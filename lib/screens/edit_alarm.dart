import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path/path.dart' as path;
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
//import 'package:flutter_sound_lite/public/flutter_sound_player.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progressive_time_picker/progressive_time_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ressources/app_colors.dart';
import '../utils.dart';
import '../widgets/ble_utils.dart';
import '../widgets/ringtone_picker_dialog.dart';

class Ringtone {
  final String name;
  final String path;

  Ringtone(this.name, this.path);
}

class ExampleAlarmEditScreen extends StatefulWidget {
  final AlarmSettings? alarmSettings;
  final String username;
  final PickedTime outBedTime;
  final Function(DateTime) updateTimeBeforeAlarm;

  const ExampleAlarmEditScreen(
      {super.key,
      this.alarmSettings,
      required this.username,
      required this.outBedTime,
      required this.updateTimeBeforeAlarm});

  @override
  State<ExampleAlarmEditScreen> createState() => _ExampleAlarmEditScreenState();
}

class _ExampleAlarmEditScreenState extends State<ExampleAlarmEditScreen> {
  bool loading = false;

  late bool creating;
  late DateTime selectedDateTime;
  late bool loopAudio;
  late bool vibrate;
  late double? volume;
  late String assetAudioName;
  late String assetAudioPath;
  bool isLoading = true;

  List<Ringtone> defaultRingtones = [
    Ringtone('Marimba', 'assets/alarms/marimba.mp3'),
    Ringtone('Nokia', 'assets/alarms/nokia.mp3'),
    Ringtone('Mozart', 'assets/alarms/mozart.mp3'),
    Ringtone('Star Wars', 'assets/alarms/star_wars.mp3'),
    Ringtone('One Piece', 'assets/alarms/one_piece.mp3'),
  ];

  @override
  void initState() {
    super.initState();
    creating = widget.alarmSettings == null;

    assetAudioPath = 'assets/alarms/marimba.mp3';

    if (creating) {
      DateTime now = DateTime.now();
      if (widget.outBedTime.h < now.hour ||
          (widget.outBedTime.h == now.hour &&
              widget.outBedTime.m < now.minute)) {
        // Si l'heure spécifiée est dans le passé, utiliser la date de demain
        selectedDateTime = DateTime(now.year, now.month, now.day + 1,
            widget.outBedTime.h, widget.outBedTime.m);
      } else {
        // Sinon, utiliser la date d'aujourd'hui'
        selectedDateTime = DateTime(now.year, now.month, now.day,
            widget.outBedTime.h, widget.outBedTime.m);
      }
      selectedDateTime = selectedDateTime.copyWith(second: 0, millisecond: 0);
      loopAudio = true;
      vibrate = true;
      volume = null;
      _initializeRingtones();
    } else {
      selectedDateTime = widget.alarmSettings!.dateTime;
      loopAudio = widget.alarmSettings!.loopAudio;
      vibrate = widget.alarmSettings!.vibrate;
      volume = widget.alarmSettings!.volume;
      _initializeRingtones();
    }
  }

  Future<void> _initializeRingtones() async {
    assetAudioName = await _loadAssetAudio();
    assetAudioPath = await findSoundFile(assetAudioName);
    await loadRingtones();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  loadRingtones() async {
    const channel = MethodChannel('flutter_channel');
    List<dynamic> ringtonesList = await channel.invokeMethod('getRingtones');

    List<Ringtone> ringtoneList = [];
    for (String ringtone in ringtonesList) {
      String formattedRingtone =
          ringtone.toString().replaceAll(' ', '_').replaceAll("'", '');
      String? filePath = await findSoundFile(formattedRingtone);
      if (filePath != null) {
        ringtoneList.add(Ringtone(ringtone, filePath));
      }
    }
    setState(() {
      // Mettre à jour l'état avec les nouvelles données de ringtoneMap
      this.ringtoneList = ringtoneList;
    });
  }

  List<Ringtone> ringtoneList = [];
  FlutterSoundPlayer player = FlutterSoundPlayer();

  String getDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = selectedDateTime.difference(today).inDays;

    switch (difference) {
      case 0:
        return "Aujourd'hui";
      case 1:
        return 'Demain';
      case 2:
        return 'After tomorrow';
      default:
        return 'In $difference days';
    }
  }

  Future<void> pickTime() async {
    TimeOfDay initialTime = TimeOfDay.fromDateTime(selectedDateTime);

    final res = await showTimePicker(
      initialTime: initialTime,
      context: context,
    );

    if (res != null) {
      setState(() {
        final DateTime now = DateTime.now();
        selectedDateTime = now.copyWith(
            hour: res.hour,
            minute: res.minute,
            second: 0,
            millisecond: 0,
            microsecond: 0);
        if (selectedDateTime.isBefore(now)) {
          selectedDateTime = selectedDateTime.add(const Duration(days: 1));
        }
      });
    }
  }

  AlarmSettings buildAlarmSettings() {
    final id = creating
        ? DateTime.now().millisecondsSinceEpoch % 10000
        : widget.alarmSettings!.id;
    print('Alarm ID: $id, assetAudio: $assetAudioPath');
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: selectedDateTime,
      loopAudio: loopAudio,
      vibrate: vibrate,
      volume: volume,
      fadeDuration: 5,
      assetAudioPath: assetAudioPath,
      notificationTitle: 'SmartRise',
      notificationBody:
          'Bonjour ${widget.username}, il est temps de se réveiller !',
    );
    return alarmSettings;
  }

  void saveAlarm() async {
    bool isGranted =
        await checkAndroidNotificationPermission(); // Vérifier la permission de notification
    if (!isGranted) {
      // Fermer le popup si la permission de notification n'est pas accordée
      if (mounted) {
        Navigator.pop(context);
        showNotificationPermissionDialog(context);
      }
      return; // Sortir de la méthode pour éviter d'exécuter le reste du code
    }

    if (loading) return;
    setState(() => loading = true);
    Alarm.set(alarmSettings: buildAlarmSettings()).then((res) {
      if (res) Navigator.pop(context, true);
      setState(() => loading = false);
    });
    widget.updateTimeBeforeAlarm(
        widget.alarmSettings?.dateTime ?? selectedDateTime);
    int timeRemainingInSeconds = selectedDateTime
        .difference(DateTime.now())
        .inSeconds; // Calculer le temps restant en secondes
    ble_utils.sendMessageToDevice(connectedDevice, timeCharacteristicUUID,
        timeRemainingInSeconds.toString());
  }

  void deleteAlarm() {
    Alarm.stop(widget.alarmSettings!.id).then((res) {
      if (res) Navigator.pop(context, true);
    });
    ble_utils.sendMessageToDevice(connectedDevice, timeCharacteristicUUID,
        ""); // Effacer l'heure de réveil
    print("Alarme supprimée ");
  }

  Future<bool> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    print('Notif status $status');
    bool isGranted =
        false; // Variable pour stocker le résultat de la vérification de la permission
    if (!status.isGranted) {
      alarmPrint('Requesting notification permission...');
      final res = await Permission.notification.request();
      alarmPrint(
        'Notification permission ${res.isGranted ? '' : 'not'} granted.',
      );
      isGranted = res
          .isGranted; // Mettre à jour la variable en fonction du résultat de la vérification de la permission
    } else {
      isGranted = true; // Si la permission est déjà accordée
    }
    return isGranted; // Retourner le résultat de la vérification de la permission
  }

  void showNotificationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: const Text('Permission requise'),
          content: const Text(
              'Vous devez autoriser les notifications pour enregistrer une alarme.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Autoriser les notifications'),
              onPressed: () {
                Navigator.pop(context); // Ferme la boîte de dialogue
                openAppSettings(); // Ouvre les paramètres de l'application
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context); // Ferme la boîte de dialogue
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: creating
                    ? ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                                color: AppColors.cancelTextColor,
                                width: 2), // Définir la couleur des contours
                          ),
                        ),
                      )
                    : const ButtonStyle(),
                child: Text(
                  "Annuler",
                  style: GoogleFonts.sriracha(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cancelTextColor,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: saveAlarm,
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(AppColors.confirmTextColor),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                child: Text(
                  "Save",
                  style: GoogleFonts.sriracha(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Text(
            getDay(),
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.15,
            width: MediaQuery.of(context).size.width * 0.60,
            child: ClipPath(
              clipper: const ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(80),
                  ),
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                ),
                child: RawMaterialButton(
                  onPressed: pickTime,
                  child: Center(
                    child: Text(
                      DateFormat('HH:mm').format(selectedDateTime),
                      style: GoogleFonts.bungee(
                        textStyle: const TextStyle(
                          fontSize: 55,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Répéter l'alarme en boucle",
                  style: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainTextColor,
                    ),
                  )),
              Switch.adaptive(
                value: loopAudio,
                activeTrackColor: AppColors.blueTextColor,
                inactiveTrackColor: AppColors.background,
                trackOutlineColor:
                    WidgetStateProperty.all(Colors.transparent),
                onChanged: (value) => setState(() => loopAudio = value),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vibration',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                ),
              ),
              Switch.adaptive(
                value: vibrate,
                activeTrackColor: AppColors.blueTextColor,
                inactiveTrackColor: AppColors.background,
                trackOutlineColor:
                    MaterialStateProperty.all(Colors.transparent),
                onChanged: (value) => setState(() => vibrate = value),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Son de l'alarme",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
                child: isLoading ?
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: AppColors.blueTextColor,
                      size: 40,
                    ),
                  ),
                ) :
                ringtoneList.isNotEmpty
                    ? TextButton(
                        style: const ButtonStyle(
                          splashFactory: NoSplash.splashFactory,
                        ),
                        onPressed: () async {
                          var selectedRingtone = await showPopupCard(
                            context: context,
                            builder: (context) {
                              return RingtonePickerDialog(
                                ringtones: ringtoneList,
                                assetAudio: assetAudioName,
                                onRingtoneSelected: (selectedRingtone) async {
                                  // Recherche de l'objet Ringtone correspondant au nom de la sonnerie sélectionnée
                                  Ringtone? selectedRingtoneObject =
                                      ringtoneList.firstWhere((ringtone) =>
                                          ringtone.name == selectedRingtone);
                                  print(
                                      "Selected ringtone object: $selectedRingtoneObject");
                                  await _saveAssetAudio(
                                      selectedRingtone); // Sauvegardez le chemin de la sonnerie sélectionnée
                                  print("Selected ringtone: $selectedRingtone");
                                  setState(() {
                                    assetAudioName =
                                        selectedRingtone; // Mettez à jour le nom de la sonnerie sélectionnée
                                    assetAudioPath = selectedRingtoneObject
                                        .path; // Mettez à jour le chemin de la sonnerie sélectionnée
                                  });
                                  player = (await player.openAudioSession())!;
                                  await player.startPlayer(
                                    fromURI: selectedRingtoneObject
                                        .path, // Utilisez le chemin de la sonnerie sélectionnée
                                    codec: Codec.opusOGG,
                                  );
                                },
                                onClose: () async {
                                  Navigator.pop(context);
                                  await player.stopPlayer();
                                  await player.closeAudioSession();
                                },
                              );
                            },
                          );
                          setState(() {
                            assetAudioName = selectedRingtone ?? assetAudioName;
                          });
                        },
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.50,
                          child: Text(
                            assetAudioName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blueTextColor,
                            ),
                          ),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton(
                          value: assetAudioPath,
                          alignment: Alignment.centerRight,
                          dropdownColor: AppColors.primary,
                          borderRadius: BorderRadius.circular(10.0),
                          icon: Icon(Icons.arrow_drop_down_rounded,
                              color: AppColors.blueTextColor),
                          iconSize: 24,
                          elevation: 16,
                          onChanged: (String? newValue) {
                            setState(() {
                              assetAudioPath = newValue!;
                              // Mettre à jour assetAudioName en fonction de la nouvelle valeur de assetAudioPath si nécessaire
                            });
                          },
                          items: defaultRingtones
                              .map<DropdownMenuItem<String>>((ringtone) {
                            return DropdownMenuItem<String>(
                                value: ringtone.path,
                                child: SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.05,
                                    child: ClipPath(
                                      clipper: const ShapeBorderClipper(
                                        shape: ContinuousRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(60),
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical:8.0), // Padding du conteneur
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              10.0), // Bordure arrondie
                                          color: AppColors.secondary, // Couleur de fond du conteneur
                                        ),
                                        child: Text(
                                          ringtone.name,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: AppColors
                                                  .blueTextColor), // Style du texte
                                        ),
                                      ),
                                    )));
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Volume de l'alarme",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainTextColor,
                ),
              ),
              Switch.adaptive(
                value: volume != null,
                activeTrackColor: AppColors.blueTextColor,
                inactiveTrackColor: AppColors.background,
                trackOutlineColor:
                    MaterialStateProperty.all(Colors.transparent),
                onChanged: (value) =>
                    setState(() => volume = value ? 0.5 : null),
              ),
            ],
          ),
          SizedBox(
            height: 30,
            child: volume != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        volume! > 0.7
                            ? Icons.volume_up_rounded
                            : volume! > 0.1
                                ? Icons.volume_down_rounded
                                : Icons.volume_mute_rounded,
                        color: AppColors.mainTextColor,
                      ),
                      Expanded(
                        child: Slider(
                          value: volume!,
                          activeColor: AppColors.blueTextColor,
                          onChanged: (value) async {
                            setState(() => volume = value);
                            await player.openAudioSession();
                            await player.setVolume(value);
                            await player.startPlayer(
                              fromURI: await findSoundFile(assetAudioName),
                              codec: Codec.opusOGG,
                            );
                            await Future.delayed(const Duration(seconds: 5));
                            await player.stopPlayer();
                            await player.closeAudioSession();
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
          if (!creating)
            TextButton(
              onPressed: deleteAlarm,
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                        color: AppColors.cancelTextColor, width: 2),
                  ),
                ),
              ),
              child: Text(
                'Delete Alarm',
                style: GoogleFonts.sriracha(
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cancelTextColor,
                  ),
                ),
              ),
            ),
          const SizedBox(),
        ],
      ),
    );
  }
}

Future<String> _loadAssetAudio() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedAssetAudio = prefs.getString('assetAudio');
  return storedAssetAudio ?? 'assets/alarms/marimba.mp3';
}

Future<void> _saveAssetAudio(String selectedRingtone) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('assetAudio', selectedRingtone);
}

findSoundFile(String soundName) async {
  List<String> subDirectories = ['Calm', 'Fun', 'Galaxy', 'Retro'];
  String basePath =
      '/system/media/audio/ringtones/SoundTheme'; // Chemin vers le répertoire principal des sons

  String formatedAssetAudio =
      soundName.replaceAll(' ', '_').replaceAll("'", '');

  for (String subDir in subDirectories) {
    Directory directory = Directory('$basePath/$subDir');
    if (await directory.exists()) {
      List<FileSystemEntity> files = directory.listSync(recursive: true);
      for (FileSystemEntity file in files) {
        if (file is File && file.path.contains(formatedAssetAudio)) {
          return file.path;
        }
      }
    }
  }
  return null; // Aucun fichier trouvé avec ce nom
}
