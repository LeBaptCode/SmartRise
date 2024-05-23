import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_rise/ressources/app_colors.dart';
import '../utils.dart';



class alarmWidgetUi extends StatelessWidget {
  final double height;
  final String title;
  final String ringtoneName;
  final void Function()? onDeleted;
  final void Function() onPressed;
  final void Function()? sendEsp;


  const alarmWidgetUi({
    Key? key,
    required this.height,
    required this.title,
    required this.ringtoneName,
    required this.onPressed,
    this.onDeleted,
    this.sendEsp,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    final tileHeight = height;
    return Stack(
      clipBehavior: Clip.antiAlias,
      children: [
        Positioned.fill(
          child: Builder(
              builder: (context) =>  Container(
                decoration: BoxDecoration(
                    color: AppColors.confirmTextColor,
                ),
              ),
          ),
        ),
        Slidable(
            key: UniqueKey(),
            direction: Axis.horizontal,
            endActionPane: ActionPane(
              motion: StretchMotion(),
              extentRatio: 0.6,
              children: [
                SlidableAction(
                  backgroundColor: AppColors.confirmTextColor,
                  autoClose: false,
                  onPressed: (_) {
                    sendEsp?.call();
                  },
                  icon: Icons.schedule_send_rounded,
                  label : "Sync",
                ),

                SlidableAction(
                  backgroundColor: AppColors.cancelTextColor,
                  autoClose: false,
                  onPressed: (_) => onDeleted?.call(), //TODO : reset esp reveil var to cancel alarm
                  icon: Icons.delete,
                  label : "Supprimer",
                ),
              ],
            ),
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                height: tileHeight,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.horizontal(right: Radius.elliptical(tileHeight/3, tileHeight/2)),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.30,
                        color: isEspConnected? AppColors.confirmTextColor : AppColors.cancelTextColor,
                        child: Center(
                          child: Icon(isEspConnected? Icons.watch_outlined : Icons.watch_off_outlined, size: 80),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: GoogleFonts.bungee(textStyle: TextStyle(fontSize: 35, color: AppColors.mainTextColor))),
                          Row(
                            children: [
                              Icon(Icons.music_note_rounded, size: 35, color: AppColors.mainTextColor,),
                              Text(ringtoneName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.mainTextColor)),

                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
