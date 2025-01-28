import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'dataClass.dart';

// if true, weekends are removed
bool isRemoveWeekend = true;

// min time and max time
int minTime = 6;
int maxTime = 24;

// week data array
var scheduleData = List.generate(7, (_) => Week());

// Save function
Future<void> saveData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> encodedData =
      scheduleData.map((week) => jsonEncode(week.toJson())).toList();
  await prefs.setStringList('scheduleData', encodedData);
  await prefs.setInt('minTime', minTime); // Save minTime
  await prefs.setInt('maxTime', maxTime); // Save maxTime
  await prefs.setBool('isRemoveWeekend', isRemoveWeekend); // Save isRemoveWeekend
}

// Load function
Future<void> loadData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? encodedData = prefs.getStringList('scheduleData');

  if (encodedData != null && encodedData.isNotEmpty) {
    scheduleData = encodedData.map((jsonString) {
      return Week.fromJson(jsonDecode(jsonString));
    }).toList();
  } else {
    scheduleData = List.generate(7, (_) => Week());
  }

  minTime = prefs.getInt('minTime') ?? 6; // Load minTime with default 6
  maxTime = prefs.getInt('maxTime') ?? 24; // Load maxTime with default 24
  isRemoveWeekend = prefs.getBool('isRemoveWeekend') ?? true; // Load isRemoveWeekend with default true
}
