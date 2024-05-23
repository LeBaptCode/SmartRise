export 'settings.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smart_rise/widgets/ble_utils.dart';

import '../utils.dart';


class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late BluetoothAdapterState _adapterState;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
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
    Widget screen = _adapterState == BluetoothAdapterState.on
        ? BluetoothScanScreen()
        : BluetoothOffScreen(adapterState: _adapterState);

    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres'),
      ),
      body: screen,
    );
  }
}

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({Key? key}) : super(key: key);

  @override
  _BluetoothScanScreenState createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  Stream<List<ScanResult>>? scanResults;
  Stream<bool> isScanningListener = FlutterBluePlus.isScanning;
  bool isScanning = false;
  bool isConnected = false;
  String message = 'Pas de message';
  Set<Guid> subscribedCharacteristics = Set<Guid>(); // Track subscribed characteristics
  BluetoothDevice? selectedDevice;
  /*late Guid timeCharacteristicUUID ;//= Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  late Guid sleepStateCharacteristicUUID ;//= Guid("37293006-4858-4c50-8cd5-d0cb0392ceb3");*/


  @override
  void initState() {
    super.initState();
    scanResults = FlutterBluePlus.scanResults;

    isScanningListener.listen((bool scanning) {
      setState(() {
        isScanning = scanning;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            if (!isScanning) {
              startScan();
            } else {
              stopScan();
            }
          },
          child: Text(isScanning ? 'Stop Scan' : 'Start Scan'),
        ),
        Text(message), // Afficher le message récupéré de l'ESP32
        FloatingActionButton(onPressed: () {
          disconnect(selectedDevice!);
        }
        , child: Icon(Icons.bluetooth_disabled)
        ),
        ElevatedButton(
          onPressed: () {
            if (isConnected) {
              ble_utils.sendMessageToDevice(selectedDevice, timeCharacteristicUUID, "test");
            }
          },
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Envoyer un message à l\'ESP32',
            ),
            onSubmitted: (String value) {
              if (isConnected) {
                ble_utils.sendMessageToDevice(selectedDevice, timeCharacteristicUUID, value);
              }
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ScanResult>>(
            stream: scanResults,
            initialData: [],
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
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
                          : 'Inconnu'),
                      subtitle: Text(results[index].device.remoteId.toString()),
                      trailing: results[index].device.isConnected ? ElevatedButton(
                        onPressed: () {
                        },
                        child: Text('Connecté ✅'),
                      ) : ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedDevice = results[index].device; // Mettre à jour le périphérique sélectionné
                          });
                          connect(results[index].device);
                        },
                        child: Text('Connecter'),
                      ),
                    );
                  },
                );
            }
            },
          ),
        ),
      ],
    );
  }

  void startScan() {
    FlutterBluePlus.startScan(
        withNames: ['SmartRise'],
        timeout: const Duration(seconds: 5));
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  void subscribeToNotifications(BluetoothDevice device, Guid characteristicId) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid == characteristicId) {
          print('Found characteristic with UUID: $characteristicId');

          await characteristic.setNotifyValue(true);
          print('Notifications enabled for characteristic with UUID: $characteristicId');
          isTimeToWakeUp();
          return;
        }
      }
    }
  }


  void connect(BluetoothDevice device) async {
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


  //TODO : Supprimer disconnect car Auto connect
  void disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
      setState(() {
        isConnected = device.isConnected;
      });
      print('Disconnected from device: ${device.platformName}');
      print("after disconnecting isConnected? ${device.isConnected}");
    } catch (e) {
      print('Error disconnecting from device: $e');
    }
  }
}

void isTimeToWakeUp() {
  print('Alarme declenchée');
  //TODO : Déclancher l'alarme
  //Alarm.stop(alarms[index].id)
}

class BluetoothOffScreen extends StatelessWidget {
  final BluetoothAdapterState adapterState;

  const BluetoothOffScreen({Key? key, required this.adapterState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Bluetooth is OFF'),
          ElevatedButton(
            onPressed: () async {
              if (await FlutterBluePlus.isSupported) {
                await FlutterBluePlus.turnOn();
              }
            },
            child: Text('Activer Bluetooth'),
          ),
        ],
      ),
    );
  }
}
