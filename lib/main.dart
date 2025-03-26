import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'dataClass.dart';
import 'converter.dart';
import 'saveData.dart';
import 'saveLoad.dart';
import 'option.dart';

import 'package:weekycal/popup.dart';
import 'mainWidget/weekBtn.dart';
import 'mainWidget/ScheduleBtn.dart';
import 'mainWidget/ScheduleInfoContainer.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

//schedule first setting
int week = 7;
double minTimeMin = 0.0;
double maxTimeMin = 0.0;

//week container size setting
//schedule block size
double weekTimeSizeX = 70.0;
double weekTimeSizeY = 450.0;
double weekContainerSizeX = 290.0;
double weekContainerSizeY = 400.0;
double weekInfoSizeY = 30.0;
double weekBtnHight = 0.0;
double weekBtnHightForMin = 0.0;
double realContainerSizeX = weekContainerSizeX;

//textfield size
double textFieldSizeX = 110;
double textFieldSizeY = 35;

//textfield info
String textfieldName = "";
String textfieldExplanation = "";
String textfieldStartTime = "";
String textfieldEndTime = "";

//this var used in home widget provide id
String dataID = "schedule_data";

//scheduleInfoContanier time select button size
double timeSelectBtnSizeX = 160.0;
double timeSelectBtnSizeY = 70.0;

//now setting schedule
int nowWeekIndex = -1;
int nowScheduleIndex = -1;

// sort schedules as start time
void sortSchedulesByStartTime(List<ScheduleData> schedules) {
  schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
}

//text field controllers
//using info container schadule set textfield
List<TextEditingController> scheduleSetTextFieldControllers = [
  TextEditingController(),
  TextEditingController(),
  // Add controllers for other text fields if necessary
];

//using info container time set textfield
TextEditingController alarmTimeTextFieldControllers =
    TextEditingController(text: '0');
//info container alarm boolen
final ValueNotifier<bool> alarmToggleFlag = ValueNotifier<bool>(false);

//if this flag turn true than sync schadule and turn again to false
final ValueNotifier<bool> isSyncWithSchaduleData = ValueNotifier(false);
//if is new schadule = true
final ValueNotifier<bool> isNewSchedule = ValueNotifier(false);
//time input field controllers
final ValueNotifier<TimeOfDay> startTimeNotifier =
    ValueNotifier(const TimeOfDay(hour: 9, minute: 0));
final ValueNotifier<TimeOfDay> endTimeNotifier =
    ValueNotifier(const TimeOfDay(hour: 10, minute: 0));
// Global variable to manage button color
final ValueNotifier<Color> colorButtonColor =
    ValueNotifier<Color>(Colors.white);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  tz.initializeTimeZones();

  WidgetsFlutterBinding.ensureInitialized();
  await loadData();
  //home widget activate
  await HomeWidget.getWidgetData<String>(dataID, defaultValue: "None")
      .then((String? value) {});

  initialization();

  runApp(const MainApp());
}

Future<void> syncData() async {
  if (isSyncWithSchaduleData.value) {
    return;
  }

  isSyncWithSchaduleData.value = true;

  try {
    // Running the synchronization process
    await Future.delayed(const Duration(milliseconds: 500));
    print("Data sync complete.");
  } catch (e) {
    print("Sync error: $e");
  } finally {
    isSyncWithSchaduleData.value = false;
  }

  await saveData();
}

ScheduleData getNowScheduleData() {
  if (nowWeekIndex < 0 ||
      nowWeekIndex >= scheduleDataList.length ||
      nowScheduleIndex < 0 ||
      nowScheduleIndex >= scheduleDataList[nowWeekIndex].scheduleInfo.length) {
    print("Invalid index");
    return ScheduleData();
  }
  return scheduleDataList[nowWeekIndex].scheduleInfo[nowScheduleIndex];
}

void firstRequestExactAlarmPermission() async {
  final status = await Permission.scheduleExactAlarm.request();
  if (status.isGranted) {
    print('Exact alarm permission has been granted.');
  } else if (status.isDenied) {
    print('Exact alarm permission has been denied.');
  } else if (status.isPermanentlyDenied) {
    print(
        'Exact alarm permission has been permanently denied. You need to change it in the settings.');
  }
}

void requestExactAlarmPermission(
    BuildContext context, ScheduleData argScheduelData) async {
  print("Requesting exact alarm permission...");
  final status = await Permission.notification
      .request(); // Requesting notification permission

  if (status.isGranted) {
    print("Exact alarm permission granted.");
    setAlarmForSchedule(
        argScheduelData, context); // Set alarm if permission is granted
  } else if (status.isDenied) {
    print("Exact alarm permission denied.");
    // Show dialog to inform the user that the permission is required
    showPermissionDeniedDialog(context);
  } else if (status.isPermanentlyDenied) {
    print("Exact alarm permission permanently denied.");
    // Guide user to change permission settings manually if permanently denied
    showPermissionPermanentlyDeniedDialog(context);
  } else {
    print("Exact alarm permission status: $status");
  }
}

void setAlarmForSchedule(ScheduleData schedule, BuildContext context) async {
  if (schedule.isAlarm) {
    if (alarmTimeTextFieldControllers.text.isEmpty) {
      showWarningDialog(context, "Please enter the alarm time.");
      return;
    }
    try {
      int alarmTimeInMinutes = int.parse(alarmTimeTextFieldControllers.text);
      DateTime alarmTime =
          schedule.getAlarmTime(alarmTimeInMinutes); // Call getAlarmTime
      print("Scheduled alarm time: $alarmTime");

      String alarmId = generateScheduleId(schedule);

      NotificationDetails details = const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'schedule_channel_id',
          'Schedule Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

      // Schedule notification
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
            alarmId.hashCode,
            schedule.name,
            schedule.explanation,
            tz.TZDateTime.from(alarmTime, tz.local),
            details,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            androidScheduleMode: AndroidScheduleMode.alarmClock);
        print("Notification successfully scheduled.");
      } catch (e) {
        print("Error occurred while scheduling notification: $e");
      }
    } catch (e) {
      showWarningDialog(context, "Please enter a valid alarm time.");
      print("Error parsing alarm time: $e");
    }
  } else {
    cancelAlarm(schedule);
  }
}

void cancelAlarm(ScheduleData schedule) async {
  String alarmId = generateScheduleId(schedule);
  await flutterLocalNotificationsPlugin.cancel(alarmId.hashCode);
}

void initialization() async {
  minTimeMin = minTime * 60;
  maxTimeMin = maxTimeMin * 60;
  weekBtnHight = ((weekContainerSizeY - weekInfoSizeY) / (maxTime - minTime));
  weekBtnHightForMin = weekBtnHight * (1.0 / 60.0);
  if (isRemoveWeekend) {
    weekContainerSizeX *= 1.5;
    realContainerSizeX /= 1.4;
  }

  AndroidInitializationSettings android =
      const AndroidInitializationSettings("@mipmap/ic_launcher");
  DarwinInitializationSettings ios = const DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );
  InitializationSettings settings =
      InitializationSettings(android: android, iOS: ios);
  await flutterLocalNotificationsPlugin.initialize(settings);

  firstRequestExactAlarmPermission();
}

void updateHomeWidget() async {
  String jsonString =
      jsonEncode(scheduleDataList.map((e) => e.toJson()).toList());
  await HomeWidget.saveWidgetData<String>(dataID, jsonString);
  await HomeWidget.updateWidget(name: 'AppWidgetProvider');
}

void applyNowSchedule(BuildContext context) {
  if (nowWeekIndex < 0) {
    return;
  }

  final startTimeInMinutes =
      startTimeNotifier.value.hour * 60 + startTimeNotifier.value.minute;
  final endTimeInMinutes =
      endTimeNotifier.value.hour * 60 + endTimeNotifier.value.minute;

  // Function to check if the time overlaps with existing schedules
  bool isTimeOverlap(int scheduleStart, int scheduleEnd) {
    return (scheduleStart < startTimeInMinutes && scheduleEnd > startTimeInMinutes) ||
        (scheduleStart < endTimeInMinutes && scheduleEnd > endTimeInMinutes);
  }

  // Check for time overlaps in the existing schedule data
  for (var schedule in scheduleDataList[nowWeekIndex].scheduleInfo) {
    if (schedule == scheduleDataList[nowWeekIndex].scheduleInfo[nowScheduleIndex]) {
      continue;
    }
    if (isTimeOverlap(schedule.startTime, schedule.endTime)) {
      showWarningDialog(context, "The time overlaps with an existing schedule.");
      return;
    }
  }

  // Create a new schedule object with the data from the input fields
  ScheduleData nowSchedule = ScheduleData()
    ..name = scheduleSetTextFieldControllers[0].text
    ..explanation = scheduleSetTextFieldControllers[1].text
    ..startTime = startTimeInMinutes
    ..endTime = endTimeInMinutes
    ..btnColor = colorButtonColor.value;

  // Add or update the schedule depending on whether it's a new schedule or not
  if (isNewSchedule.value) {
    scheduleDataList[nowWeekIndex].scheduleInfo.add(nowSchedule);
    isNewSchedule.value = false;
  } else {
    if (nowScheduleIndex < 0) {
      return;
    }
    scheduleDataList[nowWeekIndex].scheduleInfo[nowScheduleIndex] = nowSchedule;
  }

  scheduleDataList[nowWeekIndex].sortSchedulesByStartTime();

  // Handle alarm time and isAlarm flag
  try {
    nowSchedule.alarmTime = int.parse(alarmTimeTextFieldControllers.text);
  } catch (e) {
    showWarningDialog(context, "Invalid alarm time input.");
    return;
  }
  nowSchedule.isAlarm = alarmToggleFlag.value;

  if (nowSchedule.isAlarm) {
    requestExactAlarmPermission(context, nowSchedule);
  } else {
    cancelAlarm(getNowScheduleData());
  }

  syncData();

  updateHomeWidget();

  // Display a success message using a Snackbar
  Fluttertoast.showToast(
    msg: "Schedule has been successfully applied!",
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

void deleteNowSchedule() {
  if (nowWeekIndex < 0 ||
      nowScheduleIndex < 0 ||
      scheduleDataList[nowWeekIndex].scheduleInfo.length <= 0) {
    return;
  }

  scheduleDataList[nowWeekIndex].scheduleInfo.removeAt(nowScheduleIndex);
  scheduleDataList[nowWeekIndex].sortSchedulesByStartTime();
  isNewSchedule.value = true;

  syncData();

  updateHomeWidget();
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    HomeWidget.widgetClicked.listen((Uri? uri) => loadData());
    loadData();
    firstRequestExactAlarmPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(255, 10, 10, 10),
        primaryColor: Color.fromARGB(255, 210, 210, 210),
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 210, 210, 210),
          secondary: Color.fromARGB(255, 210, 210, 210),
          surface: Color.fromARGB(255, 50, 50, 50),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color.fromARGB(255, 210, 210, 210)),
          bodyMedium: TextStyle(color: Color.fromARGB(255, 210, 210, 210)),
          titleLarge: TextStyle(
              color: Color.fromARGB(255, 210, 210, 210),
              fontWeight: FontWeight.bold),
        ),
      ),
      home: const Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 1,
                  child: SingleChildScrollView(
                    physics: ClampingScrollPhysics(),
                    child: MainScheduleColumn(),
                  ),
                ),
                ScheduleInfoContainer(),
              ],
            ),
            Positioned(top: 15, right: 105, child: SaveBtn()),
            Positioned(top: 15, right: 60, child: LoadBtn()),
            Positioned(top: 15, right: 15, child: OptionBtn()),
          ],
        ),
      ),
    );
  }
}

class MainScheduleColumn extends StatefulWidget {
  const MainScheduleColumn({super.key});

  @override
  State<MainScheduleColumn> createState() => _MainScheduleColumnState();
}

class _MainScheduleColumnState extends State<MainScheduleColumn> {
  @override
  Widget build(BuildContext context) {
    return Column(
      // Changed to Column to allow for vertical scrolling
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: weekTimeSizeX - 35,
              height: weekContainerSizeY + 20,
              child: Column(
                children: [
                  SizedBox(
                    width: weekTimeSizeX,
                    height: weekInfoSizeY - 10,
                  ),
                  for (int i = minTime; i < maxTime + 1; i++) TimeText(index: i)
                ],
              ),
            ),
            Container(
              width: realContainerSizeX + 2,
              height: weekContainerSizeY + 2,
              decoration: BoxDecoration(border: Border.all(width: 1.0)),
              child: Column(
                children: [
                  Center(
                    child: Row(
                      children: [
                        for (int i = 0; i < week; i++)
                          WeekStateBlock(
                            index: i,
                          )
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      Row(
                        children: [
                          for (int i = 0; i < week; i++)
                            WeekBtnColumn(
                              index: i,
                            )
                        ],
                      ),
                      ValueListenableBuilder(
                        valueListenable: isSyncWithSchaduleData,
                        builder: (context, isSyncWithData, child) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < week; i++)
                                ScheduleBtnColumn(
                                  weekIndex: i,
                                )
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

//time text ui
class TimeText extends StatelessWidget {
  final int index;
  const TimeText({super.key, required, required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (weekContainerSizeY - 41) / (maxTime - minTime) + 0.6,
      child: Text(
        '${index.toString()}:00',
        style: TextStyle(fontSize: 12.0),
      ),
    );
  }
}

//show week state block
//no any function without show week
class WeekStateBlock extends StatelessWidget {
  final int index;
  const WeekStateBlock({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    if (isRemoveWeekend) {
      if (index == 0 || index >= week - 1) {
        return const SizedBox();
      }
    }
    return Container(
      alignment: Alignment.center,
      width: weekContainerSizeX / 7,
      height: weekInfoSizeY,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(width: 2.0),
      ),
      child: Text(
        convertWeekIntToStr(index),
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
