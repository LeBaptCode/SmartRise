import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_rise/screens/credits.dart';
import 'package:smart_rise/screens/onboarding.dart';
import 'package:smart_rise/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


int? initScreen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  initScreen = prefs.getInt("initScreen");
  await prefs.setInt("initScreen", 1);
  initializeDateFormatting('fr_FR', null);

  await Alarm.init(showDebugLogs: true);

  runApp(
    MaterialApp(
      title: 'SmartRise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, splashColor: Colors.transparent,),
      initialRoute: initScreen == 0 || initScreen ==null ? OnboardingPage.id : AlarmHomeScreen.id,
      routes: {
        OnboardingPage.id: (context) => const OnboardingPage(),
        AlarmHomeScreen.id: (context) => const AlarmHomeScreen(),
        CreditsPage.id: (context) => const CreditsPage(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      //home: const AlarmHomeScreen(),
      ),
  );
}
