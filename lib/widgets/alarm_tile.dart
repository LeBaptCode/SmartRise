import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_rise/ressources/app_colors.dart';
import '../utils.dart';

class AlarmWidgetUi extends StatelessWidget {
  final double height;
  final String title;
  final String ringtoneName;
  final void Function()? onDeleted;
  final void Function() onPressed;
  final void Function()? sendEsp;

  const AlarmWidgetUi({
    super.key,
    required this.height,
    required this.title,
    required this.ringtoneName,
    required this.onPressed,
    this.onDeleted,
    this.sendEsp,
  });

  @override
  Widget build(BuildContext context) {
    final tileHeight = height;
    return Stack(
      clipBehavior: Clip.hardEdge, // Use Clip.hardEdge to prevent overflow rendering
      children: [
        Positioned.fill(
          child: Container(
            color: AppColors.cancelTextColor,
          ),
        ),
        Slidable(
          key: UniqueKey(),
          direction: Axis.horizontal,
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: 0.3,
            children: [
              SlidableAction(
                backgroundColor: AppColors.cancelTextColor,
                autoClose: false,
                onPressed: (_) => onDeleted?.call(),
                icon: Icons.delete,
                label: "Supprimer",
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
                    borderRadius: BorderRadius.horizontal(
                        right:
                        Radius.elliptical(tileHeight / 3, tileHeight / 2)),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.30,
                      color: connectedDevice != null
                          ? AppColors.confirmTextColor
                          : AppColors.cancelTextColor,
                      child: Center(
                        child: Icon(
                            connectedDevice != null
                                ? Icons.watch_outlined
                                : Icons.watch_off_outlined,
                            size: 80,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title,
                              style: GoogleFonts.bungee(
                                  textStyle: const TextStyle(
                                      fontSize: 35,
                                      color: AppColors.mainTextColor))),
                          Row(
                            children: [
                              const Icon(
                                Icons.music_note_rounded,
                                size: 35,
                                color: AppColors.mainTextColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(ringtoneName,
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.mainTextColor)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
