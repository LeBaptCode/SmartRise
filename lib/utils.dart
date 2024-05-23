import 'package:flutter_blue_plus/flutter_blue_plus.dart';

bool isEspConnected = false;

BluetoothDevice? connectedDevice;
late Guid timeCharacteristicUUID;
late Guid sleepStateCharacteristicUUID;


