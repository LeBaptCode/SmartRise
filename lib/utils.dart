import 'package:flutter_blue_plus/flutter_blue_plus.dart';

bool isEspConnected = connectedDevice != null;

BluetoothDevice? connectedDevice;
 Guid timeCharacteristicUUID = Guid("e88861bf-f5c9-4d6f-81f1-d9f5a66c77ba");
late Guid sleepStateCharacteristicUUID;

