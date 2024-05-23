import 'dart:math';

import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_rise/widgets/shortSleepChartUI.dart';
import 'package:smart_rise/ressources/app_ressources.dart';
import '../screens/stats.dart';

class HorizontalDayPicker extends StatelessWidget {
  //TODO : Modifier cette date lors de la première utilisation de l'application
  final firstUseDate = DateTime(2024,01,01);

  final List<int> _sleepRecord = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3]
  ;

  HorizontalDayPicker({super.key});

  List<int> generateSleepPhases() {
    // Générer 24 heures de phases de sommeil aléatoires
    Random random = Random();
    List<int> phases = List.generate(24, (index) => random.nextInt(4)); // 4 représente le nombre de phases de sommeil différentes
    return phases;
  }

  @override
  Widget build(BuildContext context) {
    return EasyInfiniteDateTimeLine(
      firstDate: firstUseDate,
      //TODO: changer focus date ?
      focusDate: DateTime.now(),
      lastDate: DateTime.now(),
      onDateChange: (selectedDate) {
        // Ouvrir une nouvelle page avec une transition de zoom
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatsPage(selectedDate: selectedDate),
          ),
        );
      },
      showTimelineHeader: false,
      //Todo: Ajouter un header ?
      /*headerBuilder: (BuildContext context, DateTime date) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            DateFormat('yyyy-MM-dd').format(date).toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3CDAF7),
            ),
          ),
        );
      },*/
      dayProps: EasyDayProps(
        height: MediaQuery.of(context).size.height * 0.08,
        width: MediaQuery.of(context).size.width * 0.30,
      ),
      timeLineProps: const EasyTimeLineProps(
        vPadding: 15,
        hPadding: 5,
      ),
      itemBuilder: (BuildContext context, String dayNumber, dayName, monthName,
          fullDate, isSelected) {
        return GestureDetector(
          onLongPress: () {
            showPopupCard(
              context: context,
              builder: (context) {
                return GlassmorphicContainer(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.28,
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
                  child: SleepGraph(sleepRecord: _sleepRecord,
                    selectedDate : fullDate,
                  ),
                );
              },
              offset: ResponsiveOffset(context).getResponsiveOffset(0, 0.2),
              alignment: Alignment.topCenter,
              useSafeArea: true,
            );
          },
          child: Transform.translate(
            offset: isSelected ? const Offset(0, -15) : Offset.zero, // Décale vers le haut si l'élément est sélectionné
            child: ClipPath(
              clipper: const ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30),
                  ),
                ),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.25,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.dayColor : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      monthName,
                      style: GoogleFonts.roboto(
                        textStyle : TextStyle(
                          fontSize: isSelected ? 14 : 12,
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected ? Colors.white : const Color(0xFF3CDAF7),
                        ),
                      )
                    ),
                    Text(
                      dayNumber,
                      style: GoogleFonts.bungee(
                        textStyle : TextStyle(
                          fontSize: isSelected ? 20 : 18,
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected ? Colors.white : const Color(0xFF3CDAF7),
                        ),
                    ),
                    ),
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : const Color(0xFF3CDAF7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      },
    );
  }
}

class ResponsiveOffset {
  final BuildContext context;

  ResponsiveOffset(this.context);

  Offset getResponsiveOffset(double offsetX, double offsetY) {
    // Obtenir les dimensions de l'écran
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculer les offsets réactifs en fonction de la taille de l'écran
    double responsiveOffsetX = offsetX * screenWidth;
    double responsiveOffsetY = offsetY * screenHeight;

    // Retourner l'offset réactif
    return Offset(responsiveOffsetX, responsiveOffsetY);
  }
}
