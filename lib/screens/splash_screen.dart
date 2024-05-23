import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_rise/ressources/app_colors.dart';
import 'package:smart_rise/screens/home.dart';

class OnboardingPage extends StatefulWidget {
  static const String id = "/splashScreen";

  const OnboardingPage({Key? key}) : super(key: key);

  @override
  OnboardingPageState createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  late TextEditingController _userNameController;
  String _errorMessage = '';
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String userName = _userNameController.text.trim();
    //TODO : Save birthdate in shared preferences
    DateTime? birthDate = _birthDate;

    if (userName.isNotEmpty) {
      await prefs.setString('userName', userName); 
      if (mounted) {
        Navigator.pushReplacementNamed(context, AlarmHomeScreen.id);
      }
    } else {
      setState(() {
        _errorMessage = 'Veuillez saisir votre prénom.';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 120)),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: AppColors.mainTextColor2.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Vos données sont enregistrées localement et nous ne pouvons pas y accéder. '
                    'L\'âge est utilisé pour déterminer la plage de sommeil idéale d\'après la National Sleep Agency.',
                textAlign: TextAlign.justify,
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    color: AppColors.mainTextColor2,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(
                'Date de naissance',
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    color: AppColors.mainTextColor2,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today, color: AppColors.blueTextColor, size: 30),
                onPressed: () => _selectDate(context),
              ),
              subtitle: _birthDate != null
                  ? Text(
                '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                style: GoogleFonts.bungee(
                  textStyle: const TextStyle(
                    color: AppColors.mainTextColor,
                    fontSize: 20,
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(
                'Prénom',
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    color: AppColors.mainTextColor2,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              subtitle: Theme(
                data: ThemeData(
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionColor: AppColors.blueTextColor,
                    selectionHandleColor: AppColors.blueTextColor,
                  ),
                ),
                child: TextField(
                  controller: _userNameController,
                  keyboardType: TextInputType.text,
                  cursorColor : AppColors.mainTextColor,
                  cursorErrorColor: AppColors.cancelTextColor,
                  maxLines: 1,
                  style: GoogleFonts.sriracha(
                    textStyle: const TextStyle(
                      color: AppColors.mainTextColor,
                      fontSize: 20,
                    ),
                  ),                
                  decoration: InputDecoration(
                    hintText: 'Entrez votre prénom',
                    hintStyle: GoogleFonts.sriracha(
                      textStyle: const TextStyle(
                        color: AppColors.mainGridLineColor,
                        fontSize: 20,
                      ),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.blueTextColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.blueTextColor),
                    ),
                    errorBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cancelTextColor),
                    ),
                    errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                    errorStyle: GoogleFonts.sriracha(
                      textStyle: const TextStyle(
                        color: AppColors.cancelTextColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveData,
        label: Text(
          'Enregistrer',
          style: GoogleFonts.sriracha(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ),
        backgroundColor: AppColors.confirmTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        icon: const Icon(Icons.save, color: AppColors.secondary),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
