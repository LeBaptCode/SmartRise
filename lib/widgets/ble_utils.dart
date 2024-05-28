

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleUtils {
  static Future<void> sendMessageToDevice(BluetoothDevice? device, Guid characteristicId, String message) async {
    if (device == null) {
      print('Erreur: Aucun appareil Bluetooth n\'a été spécifié.');
      return;
    }

    try {
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid == characteristicId) {
            await characteristic.write(message.codeUnits);
            print('Message envoyé à l\'ESP : $message');
            return;
          }
        }
      }
      print('La caractéristique spécifiée n\'a pas été trouvée sur l\'ESP.');
    } catch (e) {
      print('Erreur lors de l\'envoi du message à l\'ESP : $e');
    }
  }

  static void triggerAlarm(BluetoothDevice? device, Guid characteristicId) async {
    // Code pour déterminer le meilleur moment pour le réveil
    // Vous pouvez utiliser une logique similaire à celle que j'ai mentionnée précédemment
    bool bestTimeToWakeUp = true; // Exemple de valeur pour démonstration

    // Si c'est le meilleur moment pour réveiller l'utilisateur, déclencher l'alarme
    if (bestTimeToWakeUp) {
      try {
        await sendMessageToDevice(device, characteristicId, "ALARM_ON");
        print('Alarme déclenchée.');
      } catch (e) {
        print('Erreur lors du déclenchement de l\'alarme : $e');
      }
    }
  }
}
