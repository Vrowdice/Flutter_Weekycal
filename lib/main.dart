import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'dataClass.dart';
import 'converter.dart';
import 'saveData.dart';
import 'saveLoad.dart';
import 'option.dart';

import 'package:weekycal/popup.dart';
import 'mainWidget/weekBtn.dart';
import 'mainWidget/ScheduleBtn.dart';
import 'mainWidget/ScheduleInfoContainer.dart';

//schedule first setting
int week = 7;
double minTimeMin = 0.0;
double maxTimeMin = 0.0;

//week container size setting
//schedule block size
double weekTimeSizeX = 70.0;
double weekTimeSizeY = 450.0;
double weekContainerSizeX = 295.0;
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
List<TextEditingController> textFieldControllers = [
  TextEditingController(),
  TextEditingController(),
  // Add controllers for other text fields if necessary
];

//if this flag turn true than sync schadule and turn again to false
final ValueNotifier<bool> isSyncWithSchaduleData = ValueNotifier(false);
//if is new schadule = true
final ValueNotifier<bool> isNewSchadule = ValueNotifier(false);
//time input field controllers
final ValueNotifier<TimeOfDay> startTimeNotifier =
    ValueNotifier(TimeOfDay(hour: 9, minute: 0));
final ValueNotifier<TimeOfDay> endTimeNotifier =
    ValueNotifier(TimeOfDay(hour: 10, minute: 0));
// Global variable to manage button color
final ValueNotifier<Color> colorButtonColor =
    ValueNotifier<Color>(Colors.white);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadData();
  await HomeWidget.getWidgetData<String>(dataID, defaultValue: "None")
      .then((String? value) {});
  firstSetting();
  runApp(const MainApp());
}

Future<void> syncData() async {
  if (isSyncWithSchaduleData.value) {
    return;
  }

  isSyncWithSchaduleData.value = true;

  try {
    // Running the synchronization process
    await Future.delayed(Duration(milliseconds: 500));
    print("Data sync complete.");
  } catch (e) {
    print("Sync error: $e");
  } finally {
    isSyncWithSchaduleData.value = false;
  }

  await saveData();
}

void firstSetting() {
  minTimeMin = minTime * 60;
  maxTimeMin = maxTimeMin * 60;
  weekBtnHight = ((weekContainerSizeY - weekInfoSizeY) / (maxTime - minTime));
  weekBtnHightForMin = weekBtnHight * (1.0 / 60.0);
  if (isRemoveWeekend) {
    weekContainerSizeX *= 1.5;
    realContainerSizeX /= 1.4;
  }
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
    return (scheduleStart < startTimeInMinutes &&
            scheduleEnd > startTimeInMinutes) ||
        (scheduleStart < endTimeInMinutes && scheduleEnd > endTimeInMinutes);
  }

  // Check for time overlaps in the existing schedule data
  for (var schedule in scheduleDataList[nowWeekIndex].scheduleInfo) {
    if (isTimeOverlap(schedule.startTime, schedule.endTime)) {
      showWarningDialog(context, "The schedule overlaps with an existing one.");
      return;
    }
  }

  // Create a new schedule object with the data from the input fields
  ScheduleData nowSchedule = ScheduleData()
    ..name = textFieldControllers[0].text
    ..explanation = textFieldControllers[1].text
    ..startTime = startTimeInMinutes
    ..endTime = endTimeInMinutes
    ..btnColor = colorButtonColor.value;

  // Add or update the schedule depending on whether it's a new schedule or not
  if (isNewSchadule.value) {
    scheduleDataList[nowWeekIndex].scheduleInfo.add(nowSchedule);
    isNewSchadule.value = false;
  } else {
    if (nowScheduleIndex < 0) {
      return;
    }
    scheduleDataList[nowWeekIndex].scheduleInfo[nowScheduleIndex] = nowSchedule;
  }

  scheduleDataList[nowWeekIndex].sortSchedulesByStartTime();

  syncData();

  updateHomeWidget();
}

void deleteNowSchedule() {
  if (nowWeekIndex < 0 ||
      nowScheduleIndex < 0 ||
      scheduleDataList[nowWeekIndex].scheduleInfo.length <= 0) {
    return;
  }

  scheduleDataList[nowWeekIndex].scheduleInfo.removeAt(nowScheduleIndex);
  scheduleDataList[nowWeekIndex].sortSchedulesByStartTime();
  isNewSchadule.value = true;

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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark, // 다크 모드 유지
        scaffoldBackgroundColor: const Color.fromARGB(255, 10, 10, 10), // 배경 검은색
        primaryColor: Color.fromARGB(255, 210, 210, 210), // 기본 색상 흰색으로 설정
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 210, 210, 210), // 주요 색상을 흰색으로
          secondary: Color.fromARGB(255, 210, 210, 210), // 보조 색상도 흰색으로
          surface: Color.fromARGB(255, 50, 50, 50), // 배경 검은색
          onPrimary: Colors.black, // primary 위의 글자색 (반전된 색상)
          onSecondary: Colors.black, // secondary 위의 글자색
          onSurface: Colors.white, // 기본 글자색을 흰색으로
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color.fromARGB(255, 210, 210, 210)),
          bodyMedium: TextStyle(color: Color.fromARGB(255, 210, 210, 210)),
          titleLarge:
              TextStyle(color: Color.fromARGB(255, 210, 210, 210), fontWeight: FontWeight.bold),
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
                                  index: i,
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
      alignment: Alignment.center, // 텍스트를 가운데 정렬
      width: weekContainerSizeX / 7,
      height: weekInfoSizeY,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(width: 2.0),
      ),
      child: Text(
        convertWeekIntToStr(index),
        style:
            const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
