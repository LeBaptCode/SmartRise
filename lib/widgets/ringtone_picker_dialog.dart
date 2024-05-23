import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:smart_rise/screens/edit_alarm.dart';

import '../ressources/app_colors.dart';


class RingtonePickerDialog extends StatefulWidget {
  final List<Ringtone> ringtones;
  final String assetAudio;
  final ValueChanged<String> onRingtoneSelected;
  final Function onClose;

  const RingtonePickerDialog({
    super.key,
    required this.ringtones,
    required this.assetAudio,
    required this.onRingtoneSelected,
    required this.onClose,
  });

  @override
  State<RingtonePickerDialog> createState() => _RingtonePickerDialogState();
}

class _RingtonePickerDialogState extends State<RingtonePickerDialog> {
  late String actualSelectedRingtone;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    actualSelectedRingtone = widget.assetAudio;
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToSelectedRingtone();
    });
  }

  void scrollToSelectedRingtone() {
    final itemExtent = MediaQuery.of(context).size.width * 0.135; // Hauteur d'un élément de la liste
    final index = widget.ringtones.indexWhere((ringtone) => ringtone.name == actualSelectedRingtone);
    if (index != -1) { // Vérifie si l'élément sélectionné a été trouvé dans la liste
      _scrollController.animateTo(
        index * itemExtent, // L'index de l'élément sélectionné multiplié par la hauteur de chaque élément de la liste
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutExpo,
      );
    }
  }


  @override
  Widget build(BuildContext context) {

    return GlassmorphicContainer(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.49,
      borderRadius: 30,
      blur: 10,
      alignment: Alignment.topCenter,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.mainTextColor.withOpacity(0.05),
          AppColors.mainTextColor.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.mainTextColor.withOpacity(0.5),
          AppColors.mainTextColor.withOpacity(0.5),
        ],
      ),
      //TODO : review the widget; list is going out of the container
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: ListView.separated(
                controller: _scrollController,
                itemCount: widget.ringtones.length,
                separatorBuilder: (BuildContext context, int index) => Padding(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.17,
                    right: 20,
                  ),
                  child: const Divider(height: 1,
                    color: AppColors.background),
                ),
                itemBuilder: (context, index) {
                  return RadioListTile<String>(
                    value: widget.ringtones[index].name,
                    groupValue: actualSelectedRingtone,
                    fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.blueTextColor; // Couleur lorsque le bouton est sélectionné
                      }
                      return AppColors.background; // Couleur lorsque le bouton n'est pas sélectionné
                    }),
                    title: Text(widget.ringtones[index].name,
                    style: const TextStyle(fontSize: 18, color: AppColors.mainTextColor)),
                    onChanged: (String? value) {
                      setState(() {
                        actualSelectedRingtone = value!;
                        widget.onRingtoneSelected(value);
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              widget.onClose();
            },
            child: const Padding(
              padding: EdgeInsets.only(
                  right: 30.0, top: 8.0, bottom: 15.0),
              child: Text('OK', style: TextStyle(fontSize: 20, color: AppColors.blueTextColor)),
            ),
          ),
        ],
      ),
    );
  }
}
