export 'settings.dart';
import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm/service/alarm_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_rise/ressources/app_colors.dart';

import '../utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late BluetoothAdapterState _adapterState;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAdapterState();
  }

  Future<void> _initializeAdapterState() async {
    _adapterState = BluetoothAdapterState.unknown;
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
      });
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    Widget screen = _adapterState == BluetoothAdapterState.on
        ? const BluetoothScanScreen()
        : BluetoothOffScreen(adapterState: _adapterState);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              color: AppColors.mainTextColor,
              fontSize: screenSize.width * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.mainTextColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.mainTextColor2),
            onPressed: () {
              Navigator.pushNamed(context, '/credits');
            },
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: screen,
    );
  }
}

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  BluetoothScanScreenState createState() => BluetoothScanScreenState();
}

class BluetoothScanScreenState extends State<BluetoothScanScreen> with SingleTickerProviderStateMixin{
  Stream<List<ScanResult>>? scanResults;
  Stream<bool> isScanningListener = FlutterBluePlus.isScanning;
  bool isScanning = false;
  bool isConnected = false;
  String message = 'Pas de message';
  Set<Guid> subscribedCharacteristics = <Guid>{}; // Track subscribed characteristics
  BluetoothDevice? selectedDevice;

  late AnimationController _lottieController;
  late Guid timeCharacteristicUUID ;// Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  late Guid sleepStateCharacteristicUUID ;//= Guid("37293006-4858-4c50-8cd5-d0cb0392ceb3");


  @override
  @override
  void initState() {
    super.initState();
    scanResults = FlutterBluePlus.scanResults;

    isScanningListener.listen((bool scanning) {
      setState(() {
        isScanning = scanning;
      });
    });

    _lottieController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (isScanning) {
      stopScan();
    }
    await device.connect(autoConnect: false);
    setState(() {
      isConnected = device.isConnected;
      connectedDevice = device;
    });
    connect(device);
  }

  void _showDeviceSelectionBottomSheet(BuildContext context) {
    scanResults = FlutterBluePlus.scanResults;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: StreamBuilder<List<ScanResult>>(
            stream: scanResults,
            initialData: const [],
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                List<ScanResult> results = snapshot.data!;
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ListTile(
                        leading: const Icon(Icons.watch_rounded),
                        title: Text(
                          results[index].device.platformName.isNotEmpty
                              ? results[index].device.platformName
                              : 'Inconnu',
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                              color: AppColors.mainTextColor,
                              fontSize: MediaQuery.of(context).size.width * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        trailing: results[index].device.isConnected
                            ? TextButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              AppColors.confirmTextColor,
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          child: Text(
                            "Connecté ✅",
                            style: GoogleFonts.sriracha(
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainTextColor,
                              ),
                            ),
                          ),
                        )
                            : TextButton(
                          onPressed: () async{
                            BuildContext dialogContext = context; // Stocker le BuildContext ici
                            setState(() {
                              selectedDevice = results[index].device;
                            });
                            await connect(results[index].device).then((_) {
                              Navigator.pop(dialogContext);
                            });
                          },
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: AppColors.blueTextColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            "Connecter",
                            style: GoogleFonts.sriracha(
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blueTextColor,
                              ),
                            ),
                          ),
                        ),
                        shape: const ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(80),
                          ),
                        ),
                        tileColor: AppColors.secondary,
                      ),
                    );
                  },
                );
              }
            },
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(screenSize.width * 0.05),
            child: SizedBox(
              height: screenSize.height * 0.10,
              child: connectedDevice != null
                  ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary, // Couleur de fond
                  borderRadius: BorderRadius.circular(12), // Bordures arrondies
                ),
                child: Row(
                  children: [
                    const Icon(Icons.watch_rounded, color: AppColors.confirmTextColor, size: 40,), // Icône Bluetooth connecté
                    const SizedBox(width: 16), // Espacement
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          connectedDevice!.platformName.isNotEmpty
                              ? connectedDevice!.platformName
                              : 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenSize.width * 0.06,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  : Container(), // Affiche un widget vide s'il n'y a aucun appareil connecté
            ),
          ),

          GestureDetector(
            onTap: () {
              if (!isScanning) {
                startScan();
              } else {
                stopScan();
              }
              setState(() {
                isScanning = !isScanning;
              });
            },
            child: Lottie.asset(
                'assets/lottie/bluetooth.json',
                height: screenSize.height * 0.2,
              controller: _lottieController,
            ),
          ),
          Text(
            isScanning ? 'Scanning...' : 'Appuyer pour scanner',
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                color: AppColors.mainTextColor2,
                fontSize: screenSize.width * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
          /*ElevatedButton(onPressed: triggerAlarm, child: Icon(Icons.alarm)),*/
          /*Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: scanResults,
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<ScanResult> results = snapshot.data!;
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(results[index].device.platformName.isNotEmpty
                            ? results[index].device.platformName!
                            : 'Unknown',
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                              color: AppColors.mainTextColor,
                              fontSize: MediaQuery.of(context).size.width * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                        ),
                        subtitle: Text(results[index].device.remoteId.toString(),
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                              color: AppColors.mainTextColor2,
                              fontSize: MediaQuery.of(context).size.width * 0.03,
                            ),
                          ),
                        ),
                        trailing: results[index].device.isConnected
                            ? const Icon(Icons.bluetooth_connected, color: AppColors.confirmTextColor)
                            : const Icon(Icons.bluetooth, color: AppColors.cancelTextColor),
                        onTap: () {
                          _showDeviceSelectionBottomSheet(context);
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),*/
        ],
      ),
    );
  }

  void startScan() {
    _lottieController.reset();
    _lottieController.forward();

    FlutterBluePlus.startScan(
      //withNames: ['SmartRise'],
      timeout: const Duration(seconds: 5),
    );

    _showDeviceSelectionBottomSheet(context);
  }


  void stopScan() {
    _lottieController.stop();
    FlutterBluePlus.stopScan();
    _lottieController.reset();
  }

  void subscribeToNotifications(BluetoothDevice device, Guid characteristicId) async {
    print('Subscribing to notifications for characteristic with UUID: $characteristicId');
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid == characteristicId) {
          print('Found characteristic with UUID: $characteristicId');
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            print('Notification received for characteristic with UUID: $characteristicId, value: $value');
            triggerAlarm();
          });
          print('Notifications enabled for characteristic with UUID: $characteristicId');
          return;
        }
      }
    }
  }



  Future<void> connect(BluetoothDevice device) async {
    if (isScanning) {
      stopScan();
    }
    print('Connecting to device: ${device.platformName}');
    try {
      await device.connect(autoConnect: true, mtu: null);
      await device.connectionState.where((val) => val == BluetoothConnectionState.connected).first;
      device.connectionState.listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.connected) {
          setState(() {
            isConnected = true;
            connectedDevice = device;
          });
          print('Connected');
          // Une fois la connexion établie, découvrez les services
          List<BluetoothService> services = await device.discoverServices();
          for (BluetoothService service in services) {
            for (BluetoothCharacteristic characteristic in service
                .characteristics) {
              // Vérifiez si la caractéristique a les propriétés nécessaires pour le temps et l'état de sommeil
              if (characteristic.properties.read &&
                  characteristic.properties.write) {
                // Souscrire aux notifications de cette caractéristique
                setState(() {
                  timeCharacteristicUUID = characteristic.uuid;
                });
                subscribeToNotifications(device, timeCharacteristicUUID);
                print(
                    'Subscribed to notifications for time characteristic with UUID: $timeCharacteristicUUID');
              } else if (characteristic.properties.notify) {
                // Si la caractéristique n'a pas les propriétés read mais a les propriétés notify
                // Souscrire aux notifications de cette caractéristique
                setState(() {
                  sleepStateCharacteristicUUID = characteristic.uuid;
                });
                subscribeToNotifications(device, sleepStateCharacteristicUUID);
                print(
                    'Subscribed to notifications for sleep state characteristic with UUID: $sleepStateCharacteristicUUID');
              }
            }
          }
        }
      });
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }
}


void triggerAlarm() async {
  print('Alarme déclenchée');
  final now = DateTime.now();

  final List<AlarmSettings> alarmSettingsList = AlarmStorage.getSavedAlarms();

  // Créer une nouvelle liste de AlarmSettings avec les modifications
  final smartAlarmSettings = alarmSettingsList.map((alarm) {
    // Modifier les paramètres de l'alarme selon vos besoins
    return AlarmSettings(
      id: alarm.id,
      dateTime: DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        0,
        0,
      ).add(const Duration(seconds: 1)),
      loopAudio: false,
      vibrate: false,
      volume: alarm.volume,
      fadeDuration: 3,
      assetAudioPath: alarm.assetAudioPath,
      notificationTitle: 'SmartRise',
      notificationBody: 'Bonjour, il est temps de se réveiller !',
    );
  });

  // Définir les alarmes modifiées
  for (final alarm in smartAlarmSettings) {
    await Alarm.set(alarmSettings: alarm);
  }
}


class BluetoothOffScreen extends StatelessWidget {
  final BluetoothAdapterState adapterState;

  const BluetoothOffScreen({super.key, required this.adapterState});

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double fontSize = screenSize.width * 0.04;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: screenSize.height * 0.35,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.menuBackground.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bluetooth_disabled,
                size: MediaQuery.of(context).size.width * 0.15,
                color: AppColors.cancelTextColor,
              ),
              Text(
                'Le Bluetooth est désactivé',
                style: GoogleFonts.roboto(
                  fontSize: fontSize * 1.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainTextColor,
                ),
              ),
              Text(
                'Veuillez activer le Bluetooth pour continuer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  color: AppColors.mainTextColor2,
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (await FlutterBluePlus.isSupported) {
                    await FlutterBluePlus.turnOn();
                  }
                },
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
                  "Activer Bluetooth",
                  style: GoogleFonts.sriracha(
                    textStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
