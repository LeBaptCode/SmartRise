import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progressive_time_picker/progressive_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:smart_rise/screens/home.dart';
import 'package:smart_rise/ressources/app_ressources.dart';

class TimeScheduleWidget extends StatefulWidget {
  const TimeScheduleWidget({
    super.key,
    required this.inBedTime,
    required this.outBedTime,
    required this.disabledInitTime,
    required this.disabledEndTime,
    required this.sleepGoal,
    required this.clockTimeFormat,
    required this.clockIncrementTimeFormat,
    required this.isSleepGoal,
    required this.validRange,
    required this.intervalBedTime,
    required this.isAlarmSet,
    required this.updateLabels,
  });

  final PickedTime inBedTime;
  final PickedTime outBedTime;
  final PickedTime disabledInitTime;
  final PickedTime disabledEndTime;
  final SleepGoal sleepGoal;
  final ClockTimeFormat clockTimeFormat;
  final ClockIncrementTimeFormat clockIncrementTimeFormat;
  final bool isSleepGoal;
  final bool? validRange;
  final PickedTime intervalBedTime;
  final bool isAlarmSet;
  final Function(PickedTime, PickedTime, bool?) updateLabels;

  @override
  TimeScheduleWidgetState createState() => TimeScheduleWidgetState();
}

class TimeScheduleWidgetState extends State<TimeScheduleWidget> {
  late PickedTime intervalBedTime;
  @override
  void initState() {
    super.initState();
    // Initialisez _intervalBedTime avec une valeur par défaut
    timeDifference(widget.inBedTime, widget.outBedTime);
  }

  @override
  Widget build(BuildContext context) {

    return TimePicker(
      initTime: widget.inBedTime,
      endTime: widget.outBedTime,
      height: 260.0,
      width: 260.0,
      onSelectionChange: (start, end, isDisableRange) {
        widget.updateLabels(start, end, isDisableRange);
        },// widget.updateLabels(start, end, isDisableRange),
      onSelectionEnd: (start, end, isDisableRange) {
        widget.updateLabels(start, end, isDisableRange);
      },
      primarySectors: widget.clockTimeFormat.value,
      secondarySectors: widget.clockTimeFormat.value * 2,
      isEndHandlerSelectable: widget.isAlarmSet,
      isSelectableHandlerMoveAble: widget.isAlarmSet,
      decoration: TimePickerDecoration(
        baseColor: AppColors.secondary,
        sweepDecoration: TimePickerSweepDecoration(
          pickerStrokeWidth: 30.0,
          pickerColor: AppColors.blueTextColor,
          showConnector: true,
        ),
        initHandlerDecoration: TimePickerHandlerDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
          radius: 12.0,
          icon: const Icon(
            Icons.bedtime_rounded,
            size: 20.0,
            color: AppColors.blueTextColor,
          ),
        ),

        endHandlerDecoration: TimePickerHandlerDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
          radius: 12.0,
          icon: const Icon(
            Icons.alarm_rounded,
            size: 20.0,
            color: AppColors.blueTextColor,
          ),
        ),
        primarySectorsDecoration: TimePickerSectorDecoration(
          color: AppColors.mainTextColor,
          width: 1.0,
          size: 4.0,
          radiusPadding: 25.0,
        ),
        secondarySectorsDecoration: TimePickerSectorDecoration(
          color: AppColors.blueTextColor,
          width: 1.0,
          size: 2.0,
          radiusPadding: 25.0,
        ),
        clockNumberDecoration: TimePickerClockNumberDecoration(
          defaultTextColor: AppColors.mainTextColor,
          textStyle: GoogleFonts.bungee(
            textStyle: const TextStyle(
              color: AppColors.mainTextColor,
              fontSize: 18.0,
            ),
          ),
          defaultFontSize: 12.0,
          scaleFactor: 2.0,
          showNumberIndicators: true,
          clockTimeFormat: widget.clockTimeFormat,
          clockIncrementTimeFormat: widget.clockIncrementTimeFormat,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(62.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //TODO : Text Color is not changing
            Text(
              '${intl.NumberFormat('00').format(widget.intervalBedTime.h)}:${intl.NumberFormat('00').format(widget.intervalBedTime.m)}',
              style: GoogleFonts.bungee(
                textStyle: TextStyle(
                  color: widget.isSleepGoal ?  AppColors.confirmTextColor : AppColors.cancelTextColor,
                  fontSize: 20.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void timeDifference(PickedTime start, PickedTime end) {
    int hoursDifference = end.h - start.h;
    int minutesDifference = end.m - start.m;

    if (minutesDifference < 0) {
      hoursDifference -= 1;
      minutesDifference += 60;
    }

    if (hoursDifference < 0 || (hoursDifference == 0 && minutesDifference < 0)) {
      // Si l'heure de fin est antérieure à l'heure de début, ou si les heures sont égales mais les minutes de fin sont antérieures
      hoursDifference += 24; // Ajouter 24 heures pour obtenir la différence sur une journée complète
    }

    setState(() {
      intervalBedTime = PickedTime(h: hoursDifference, m: minutesDifference);
    });
  }
}
