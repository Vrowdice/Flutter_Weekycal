import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

//week container size setting
int minTime = 0;
int maxTime = 24;

double weekTimeSizeX = 100.0;
double weekTimeSizeY = 560.0;
double weekContainerSizeX = 450.0;
double weekContainerSizeY = 570.0;
double weekInfoSizeY = 40.0;

var nowWeekInfo = [Week, Week, Week, Week, Week, Week, Week];

class Week{
  //schedule list
  List<Schedule> schedule = [];
}

class Schedule{
  String name = '';

  int listIndex = 0;
  
  int startTime = 0;

  int endTime = 0;

  String explanation = '';
}

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            onTap: (int index) {
              switch (index) {
                case 0:
                  break;
                case 1:
                  break;
                default:
              }
            },
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.schedule), label: 'Schedule'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.settings), label: 'Setting')
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: weekTimeSizeX - 50,
                    height: weekContainerSizeY + 20,
                    child: Column(
                      children: [
                        SizedBox(
                          width: weekTimeSizeX,
                          height: weekInfoSizeY - 10,
                        ),
                        for (int i = minTime; i < maxTime + 1; i++)
                          TimeText(index: i)
                      ],
                    ),
                  ),
                  Container(
                    width: weekContainerSizeX + 2,
                    height: weekContainerSizeY,
                    decoration: BoxDecoration(border: Border.all(width: 1.0)),
                    child: Column(
                      children: [
                        Center(
                          child: Row(
                            children: [
                              for (int i = 0; i < 7; i++)
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
                                for (int i = 0; i < 7; i++)
                                  const WeekBtnColumn()
                              ],
                            ),
                            Row(
                              children: [
                                for (int i = 0; i < 7; i++)
                                  const StatedWeekBtnColumn()
                              ],
                            ),
                            SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(0))),
                                  onPressed: () {},
                                  child: Container()),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                width: weekContainerSizeX + 50,
                height: weekContainerSizeY / 3,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 247, 242, 249),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}

class TimeText extends StatelessWidget {
  final index;
  const TimeText({super.key, required, required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (weekContainerSizeY - 41) / maxTime,
      child: Text(
        '${index.toString()} : 00',
      ),
    );
  }
}

//show week state block
//no any function without show week
class WeekStateBlock extends StatelessWidget {
  final index;
  const WeekStateBlock({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text(convertWeekIntToStr(index)),
      ),
      width: weekContainerSizeX / 7,
      height: weekInfoSizeY,
      decoration:
          BoxDecoration(color: Colors.white, border: Border.all(width: 1.0)),
    );
  }
}

class StatedWeekBtnColumn extends StatefulWidget {
  const StatedWeekBtnColumn({super.key});

  @override
  State<StatedWeekBtnColumn> createState() => _StatedWeekBtnColumnState();
}

class _StatedWeekBtnColumnState extends State<StatedWeekBtnColumn> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class StatedWeekBtn extends StatefulWidget {
  const StatedWeekBtn({super.key});

  @override
  State<StatedWeekBtn> createState() => _StatedWeekBtnState();
}

class _StatedWeekBtnState extends State<StatedWeekBtn> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class WeekBtnColumn extends StatelessWidget {
  const WeekBtnColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: weekContainerSizeX / 7,
      height: weekContainerSizeY - 42,
      child: Column(
        children: [for (int i = 0; i < 24; i++) const WeekBtn()],
      ),
    );
  }
}

class WeekBtn extends StatefulWidget {
  const WeekBtn({super.key});

  @override
  State<WeekBtn> createState() => WeekBtnState();
}

class WeekBtnState extends State<WeekBtn> {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: weekContainerSizeX / 7,
        height: (weekContainerSizeY - weekInfoSizeY - 2) / maxTime,
        decoration:
            BoxDecoration(color: Colors.white, border: Border.all(width: 0.5)),
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0))),
            onPressed: () {},
            child: Container()));
  }
}

String convertWeekIntToStr(int argIndex) {
  switch (argIndex) {
    case 0:
      return 'Sun';
    case 1:
      return 'Mon';
    case 2:
      return 'Tue';
    case 3:
      return 'Wed';
    case 4:
      return 'Thu';
    case 5:
      return 'Fri';
    case 6:
      return 'Sat';
    default:
      return '';
  }
}
