import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_rise/screens/splash_screen.dart';
import 'package:smart_rise/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';


int? initScreen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  initScreen = await prefs.getInt("initScreen");
  await prefs.setInt("initScreen", 1);

  await Alarm.init(showDebugLogs: true);

  runApp(
    MaterialApp(
      title: 'SmartRise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, splashColor: Colors.transparent,),
      initialRoute: initScreen == 0 || initScreen ==null ? OnboardingPage.id : AlarmHomeScreen.id,
      routes: {
        OnboardingPage.id: (context) => OnboardingPage(),
        AlarmHomeScreen.id: (context) => AlarmHomeScreen(),
      },
      //home: const AlarmHomeScreen(),
      ),
  );
}
