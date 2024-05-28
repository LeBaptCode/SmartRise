import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:datetime_loop/datetime_loop.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable/exports.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_rise/screens/edit_alarm.dart';
import 'package:smart_rise/screens/ring.dart';
import 'package:smart_rise/screens/settings.dart';
import 'package:smart_rise/screens/onboarding.dart';
import 'package:smart_rise/widgets/alarm_tile.dart';
import 'package:smart_rise/widgets/ble_utils.dart';
import 'package:smart_rise/widgets/empty_alarm.dart';
import 'package:smart_rise/widgets/horizontal_day_picker.dart';
import 'package:smart_rise/ressources/app_ressources.dart';
import 'package:smart_rise/widgets/time_schedule.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progressive_time_picker/progressive_time_picker.dart';
import 'package:intl/intl.dart' as intl;
import '../utils.dart';

class SleepGoal {
  final int min;
  final int max;

  SleepGoal({required this.min, required this.max});
}

class AlarmHomeScreen extends StatefulWidget {
  static const String id = "/alarmHomeScreen";
  const AlarmHomeScreen({super.key});

  @override
  State<AlarmHomeScreen> createState() => _ExampleAlarmHomeScreenState();
}

class _ExampleAlarmHomeScreenState extends State<AlarmHomeScreen> {
  late List<AlarmSettings> alarms;

  final ClockTimeFormat _clockTimeFormat = ClockTimeFormat.twentyFourHours;
  final ClockIncrementTimeFormat _clockIncrementTimeFormat =
      ClockIncrementTimeFormat.fiveMin;

  PickedTime _inBedTime = PickedTime(h: 23, m: 0);
  PickedTime _outBedTime = PickedTime(h: 7, m: 0);

  final PickedTime _disabledInitTime = PickedTime(h: 12, m: 0);
  final PickedTime _disabledEndTime = PickedTime(h: 20, m: 0);
  PickedTime intervalBedTime = PickedTime(h: 0, m: 0);

  final SleepGoal _sleepGoal = SleepGoal(min: 7, max: 9);

  bool _isSleepGoal = false;

  bool? validRange = true;

  String _userName = '';
  int _userAge = 18;

  DateTime _timeBeforeAlarm = DateTime.now();

  static StreamSubscription<AlarmSettings>? subscription;

  Future<void> _initData() async {
    loadAlarms(); // Charge les alarmes
    subscription ??= Alarm.ringStream.stream.listen((alarmSettings) =>
        navigateToRingScreen(alarmSettings)); // Souscrit au stream
    await _loadUserName(); // Attend le chargement du nom d'utilisateur
    await _loadUserAge(); // Attend le chargement de l'âge de l'utilisateur
    await _loadSavedIntervalBedTime(); // Attend le chargement de l'heure de coucher/réveil
    await _updateLabels(
        _inBedTime, _outBedTime, false); // Met à jour les étiquettes
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Utilisateur';
    });
  }

  Future<void> _loadUserAge() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String birthDateString = prefs.getString('birthDate')!;
    DateTime birthDate = DateTime.parse(birthDateString);
    int storedAge = prefs.getInt('age')!;
    int calculatedAge = _calculateAge(birthDate);

    if (storedAge != calculatedAge) {
      await prefs.setInt('age', calculatedAge);
    }

    setState(() {
      _userAge = calculatedAge;
    });
  }



  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void loadAlarms() {
    setState(() {
      alarms = Alarm.getAlarms();
    });
  }

  Future<void> _loadSavedIntervalBedTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int bedTimeInMin = prefs.getInt('bedTime') ?? 1380;
    int wakeUpTimeInMin = prefs.getInt('wakeUpTime') ?? 420;

    setState(() {
      _inBedTime = PickedTime(h: bedTimeInMin ~/ 60, m: bedTimeInMin % 60);
      _outBedTime =
          PickedTime(h: wakeUpTimeInMin ~/ 60, m: wakeUpTimeInMin % 60);
    });
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ExampleAlarmRingScreen(alarmSettings: alarmSettings),
        ));
    loadAlarms();
  }

  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {
    final res = await showModalBottomSheet<bool?>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        backgroundColor: AppColors.secondary,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.76,
            child: ExampleAlarmEditScreen(
              alarmSettings: settings,
              username: _userName,
              outBedTime: _outBedTime,
              updateTimeBeforeAlarm: (alarmTime) {
                setState(() {
                  _outBedTime =
                      PickedTime(h: alarmTime.hour, m: alarmTime.minute);
                  _timeBeforeAlarm = alarmTime;
                });
              },
            ),
          );
        });

    if (res != null && res == true) loadAlarms();
  }

  Future<void> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      alarmPrint('Requesting notification permission...');
      final res = await Permission.notification.request();
      alarmPrint(
        'Notification permission ${res.isGranted ? '' : 'not'} granted.',
      );
    }
  }

  Future<void> checkAndroidExternalStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isDenied) {
      alarmPrint('Requesting external storage permission...');
      final res = await Permission.storage.request();
      alarmPrint(
        'External storage permission ${res.isGranted ? '' : 'not'} granted.',
      );
    }
  }



  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  List ringtones = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Bonjour ',
              style: GoogleFonts.roboto(
                color: AppColors.mainTextColor,
                fontSize: 25,
              ),
            ),
            Text('$_userName 👋',
                style: GoogleFonts.sriracha(
                    textStyle: const TextStyle(
                        color: AppColors.mainTextColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w600))),
          ]),
          toolbarHeight: 100,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.png"),
                fit: BoxFit.fitWidth,
                opacity: 0.25,
                //scale: 1.0,
              ),
            ),
          ),
          actions: [
            //TODO : Delete this IconButton
            /*IconButton.filledTonal(
                onPressed: () => {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const OnboardingPage())) //TODO à supprimer
                    }, //TODO : Change action onPressed, icon: icon)
                icon: const Icon(
                  Icons.account_circle_rounded,
                  color: AppColors.mainTextColor2,
                )),*/
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipPath(
                clipper: const ShapeBorderClipper(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.4),
                  ),
                  child: IconButton(
                      onPressed: () => {
                        HapticFeedback.selectionClick(),
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SettingsPage())),
                          },
                      highlightColor: Colors.transparent,
                      icon: const Icon(Icons.settings_rounded,
                          size: 30, color: AppColors.mainTextColor)),
                ),
              ),
            )
          ]),
      backgroundColor: AppColors.primary,
      body: SafeArea(
        //minimum: const EdgeInsets.only(bottom: 15),
        child: ClipPath(
          clipper: const ShapeBorderClipper(
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(70),
                topLeft: Radius.circular(70),
              ),
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 5,
                bottom: 15,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const HorizontalCalendar(),
                      TimeScheduleWidget(
                          inBedTime: _inBedTime,
                          outBedTime: _outBedTime,
                          disabledInitTime: _disabledInitTime,
                          disabledEndTime: _disabledEndTime,
                          sleepGoal: _sleepGoal,
                          clockTimeFormat: _clockTimeFormat,
                          clockIncrementTimeFormat: _clockIncrementTimeFormat,
                          isSleepGoal: _isSleepGoal,
                          validRange: validRange,
                          intervalBedTime: intervalBedTime,
                          isAlarmSet: alarms.isEmpty,
                          updateLabels: _updateLabels),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.04,
                        child: alarms.isNotEmpty
                            ? Center(child: _buildTimeBeforeAlarm())
                            : Container(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _timeWidget(
                            context,
                            'Couché',
                            _inBedTime,
                            const Icon(
                              Icons.bedtime_rounded,
                              size: 30,
                              color: AppColors.blueTextColor,
                            ),
                            ArrowDirection.right,
                          ),
                          _timeWidget(
                            context,
                            'Réveil',
                            _outBedTime,
                            const Icon(
                              Icons.alarm_rounded,
                              size: 30,
                              color: AppColors.blueTextColor,
                            ),
                            ArrowDirection.left,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.23,
                    child: ClipPath(
                      clipper: const ShapeBorderClipper(
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(80),
                          ),
                        ),
                      ),
                      child: Container(
                          height: MediaQuery.of(context).size.height * 0.23,
                          width: MediaQuery.of(context).size.width * 0.94,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                          ),
                          child: alarms.isNotEmpty
                              ? ListView.separated(
                                  itemCount: alarms.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    return AlarmWidgetUi(
                                        key: Key(alarms[index].id.toString()),
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.23,
                                        title: TimeOfDay(
                                          hour: alarms[index].dateTime.hour,
                                          minute: alarms[index].dateTime.minute,
                                        ).format(context),
                                        ringtoneName: getAlarmNameFromPath(
                                            alarms[index].assetAudioPath),
                                        onPressed: () => navigateToAlarmScreen(
                                            alarms[index]),
                                        onDeleted: () {
                                          HapticFeedback.lightImpact();
                                          Alarm.stop(alarms[index].id)
                                              .then((_) => loadAlarms());
                                          BleUtils.sendMessageToDevice(
                                              connectedDevice,
                                              timeCharacteristicUUID,
                                              null.toString());
                                        },
                                        sendEsp: () {
                                          setState(() {
                                            isEspConnected = !isEspConnected;
                                          });
                                        });
                                  },
                                )
                              : AnimatedInkWell(
                                  onTap: () => navigateToAlarmScreen(null),
                                )),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding _buildTimeBeforeAlarm() {
    return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 2, // Hauteur du trait
                                    decoration: BoxDecoration(
                                      color: AppColors
                                          .blueTextColor, // Couleur du trait
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal:
                                            15), // Marge horizontale entre le trait et le texte
                                  ),
                                ),
                                DateTimeLoopBuilder(
                                    timeUnit: TimeUnit.minutes,
                                    builder: (context, dateTime, child) {
                                      return Text(
                                        _timeToAlarm(_timeBeforeAlarm),
                                        style: const TextStyle(
                                          color: AppColors.blueTextColor,
                                          fontSize: 15,
                                        ),
                                      );
                                    }),
                                Expanded(
                                  child: Container(
                                    height: 2, // Hauteur du trait
                                    decoration: BoxDecoration(
                                      color: AppColors
                                          .blueTextColor, // Couleur du trait
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal:
                                            15), // Marge horizontale entre le trait et le texte
                                  ),
                                ),
                              ],
                            ),
                          );
  }

  Widget _timeWidget(BuildContext context, String title, PickedTime time,
      Icon icon, ArrowDirection arrowDirection) {
    return GestureDetector(
      onTap: () {
        if (title != 'Réveil' || alarms.isEmpty) {
          showTimePicker(
            // TODO : Change title
            context: context,
            initialTime: TimeOfDay(
              hour: time.h,
              minute: time.m,
            ),
          ).then(
            (selectedTime) {
              setState(() {
                if (selectedTime != null) {
                  if (title == 'Couché') {
                    _inBedTime = PickedTime(
                        h: selectedTime.hour, m: selectedTime.minute);
                  } else {
                    _outBedTime = PickedTime(
                        h: selectedTime.hour, m: selectedTime.minute);
                  }
                }
              });
              _updateLabels(_inBedTime, _outBedTime, false);
            },
          );
        }
      },
      child: SizedBox(
        width: 150.0,
        height: 104.0,
        child: CustomPaint(
          painter: TimmeSettingsBoxPainter(
              color: AppColors.secondary, direction: arrowDirection),
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.transparent, //Color(0xFF1F2633)
              borderRadius: BorderRadius.circular(25.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: arrowDirection == ArrowDirection.left
                      ? [
                          Text(
                            title,
                            style: GoogleFonts.roboto(
                              color: AppColors.blueTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          icon,
                        ]
                      : [
                          icon,
                          Text(
                            title,
                            style: GoogleFonts.roboto(
                              color: AppColors.blueTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                ),
                Text(
                  '${intl.NumberFormat('00').format(time.h)}:${intl.NumberFormat('00').format(time.m)}',
                  style: GoogleFonts.bungee(
                    color: AppColors.blueTextColor,
                    fontSize: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateLabels(
      PickedTime init, PickedTime end, bool? isDisableRange) async {

    // Vérifiez les anciennes valeurs pour la comparaison
    PickedTime? oldInBedTime = _inBedTime;
    PickedTime? oldOutBedTime = _outBedTime;

    _inBedTime = init;
    _outBedTime = end;
    int hoursDifference = _outBedTime.h - _inBedTime.h;
    int minutesDifference = _outBedTime.m - _inBedTime.m;

    if (((oldInBedTime.h != init.h || oldInBedTime.m != init.m)) ||
        ((oldOutBedTime.h != end.h || oldOutBedTime.m != end.m))) {
      HapticFeedback.selectionClick();
    }

    if (minutesDifference < 0) {
      hoursDifference -= 1;
      minutesDifference += 60;
    }

    if (hoursDifference < 0 ||
        (hoursDifference == 0 && minutesDifference < 0)) {
      // Si l'heure de fin est antérieure à l'heure de début, ou si les heures sont égales mais les minutes de fin sont antérieures
      hoursDifference +=
          24; // Ajouter 24 heures pour obtenir la différence sur une journée complète
    }

    setState(() {
      intervalBedTime = PickedTime(h: hoursDifference, m: minutesDifference);
      validRange = validateSleepGoal(
        intervalBedTime: intervalBedTime,
        clockTimeFormat: _clockTimeFormat,
        clockIncrementTimeFormat: _clockIncrementTimeFormat,
        age: _userAge,
      );
      _isSleepGoal = validRange!;
      _saveIntervalBedTime(_inBedTime, _outBedTime);
    });
  }

  String _timeToAlarm(DateTime alarmTime) {
    DateTime now = DateTime.now();
    DateTime actualTime =
        now.copyWith(second: 0, millisecond: 0, microsecond: 0);

    // Si l'heure de l'alarme est passée pour aujourd'hui, ajoute une journée complète
    if (alarmTime.isBefore(actualTime)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    // Calcule la différence en heures et minutes entre maintenant et l'heure de l'alarme
    Duration difference = alarmTime.difference(actualTime);

    // Convertit la différence en heures et minutes
    int remainingHours = difference.inHours % 24;
    int remainingMinutes = difference.inMinutes % 60;

    // Détermine le texte à afficher en fonction du temps restant avant l'alarme
    String alarmText = '';

    if (remainingHours == 0 && remainingMinutes <= 1) {
      alarmText = "Alarme imminente";
    } else if (remainingHours == 0) {
      alarmText = "Alarme dans $remainingMinutes min";
    } else if (remainingMinutes == 0) {
      alarmText = "Alarme dans $remainingHours h";
    } else {
      alarmText = "Alarme dans $remainingHours h $remainingMinutes min";
    }
    return alarmText;
  }

  String getAlarmNameFromPath(String path) {
    // Utilisez la classe File pour extraire le nom du fichier à partir du chemin
    File file = File(path);
    String fileName = file.path
        .split('/')
        .last; // Séparez le chemin et récupérez le dernier élément
    String alarmName = fileName
        .split('.')
        .first
        .replaceAll('ACH_', '')
        .replaceAll(
            '_', ' '); // Séparez le nom du fichier et supprimez l'extension
    return alarmName;
  }
}

class HorizontalCalendar extends StatelessWidget {
  const HorizontalCalendar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollHaptics(
      heavyHapticsAtEdgeEnabled: true,
      // TODO : Add hapticEffectDuringScroll
      child: SingleChildScrollView(
        child: DateTimeLoopBuilder(
          timeUnit: TimeUnit.days,
          builder: (context, value, child) {
            return HorizontalDayPicker();
          },
        ),
      ),
    );
  }
}

void _saveIntervalBedTime(PickedTime bedTime, PickedTime wakeUpTime) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Convertir les heures et minutes en minutes totales depuis minuit
  int bedTimeInMin = bedTime.h * 60 + bedTime.m;
  int wakeUpTimeInMin = wakeUpTime.h * 60 + wakeUpTime.m;

  // Enregistrer les heures de coucher et de réveil dans SharedPreferences
  await prefs.setInt('bedTime', bedTimeInMin);
  await prefs.setInt('wakeUpTime', wakeUpTimeInMin);
}

bool validateSleepGoal({
  required PickedTime intervalBedTime,
  ClockTimeFormat clockTimeFormat = ClockTimeFormat.twentyFourHours,
  ClockIncrementTimeFormat clockIncrementTimeFormat =
      ClockIncrementTimeFormat.fiveMin,
  required int age,
}) {
  var sleepTime = intervalBedTime.h * 60 + intervalBedTime.m;

  // Déterminer l'intervalle de sommeil en fonction de l'âge
  if (age >= 6 && age <= 13) {
    // Intervalle de sommeil recommandé pour les jeunes enfants
    return (9 * 60 <= sleepTime && sleepTime <= 11 * 60);
  } else if (age >= 14 && age < 18) {
    // Intervalle de sommeil recommandé pour les enfants d'âge scolaire
    return (8 * 60 <= sleepTime && sleepTime <= 10 * 60);
  } else if (age >= 18 && age <= 64) {
    // Intervalle de sommeil recommandé pour les adolescents
    return (7 * 60 <= sleepTime && sleepTime <= 9 * 60);
  } else if (age > 64) {
    // Intervalle de sommeil recommandé pour les adolescents
    return (7 * 60 <= sleepTime && sleepTime <= 8 * 60);
  } else {
    return false;
  }
}

enum ArrowDirection {
  left,
  right,
}

class TimmeSettingsBox extends StatelessWidget {
  final Color color;
  final ArrowDirection direction;

  const TimmeSettingsBox({
    super.key,
    required this.color,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 100,
      child: CustomPaint(
        painter: TimmeSettingsBoxPainter(color: color, direction: direction),
      ),
    );
  }
}

class TimmeSettingsBoxPainter extends CustomPainter {
  final Color color;
  final ArrowDirection direction;

  TimmeSettingsBoxPainter({required this.color, required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(size.width * 0.19, 0)
      ..cubicTo(
          size.width * 0.41, 0, size.width * 0.76, 0, size.width * 0.92, 0)
      ..cubicTo(size.width * 0.97, 0, size.width, size.height * 0.07,
          size.width, size.height * 0.16)
      ..cubicTo(size.width, size.height * 0.16, size.width, size.height * 0.87,
          size.width, size.height * 0.87)
      ..cubicTo(size.width, size.height * 0.94, size.width * 0.98, size.height,
          size.width * 0.93, size.height)
      ..cubicTo(size.width * 0.93, size.height, size.width * 0.19, size.height,
          size.width * 0.19, size.height)
      ..cubicTo(size.width * 0.16, size.height, size.width * 0.14,
          size.height * 0.97, size.width * 0.12, size.height * 0.93)
      ..cubicTo(size.width * 0.12, size.height * 0.93, size.width * 0.02,
          size.height * 0.56, size.width * 0.02, size.height * 0.56)
      ..cubicTo(size.width * 0.01, size.height * 0.52, size.width * 0.01,
          size.height * 0.48, size.width * 0.02, size.height * 0.44)
      ..cubicTo(size.width * 0.02, size.height * 0.44, size.width * 0.12,
          size.height * 0.07, size.width * 0.12, size.height * 0.07)
      ..cubicTo(size.width * 0.14, size.height * 0.03, size.width * 0.16, 0,
          size.width * 0.19, 0)
      ..close();

    if (direction == ArrowDirection.right) {
      canvas.scale(-1, 1);
      canvas.translate(-size.width, 0);
      canvas.drawPath(path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
