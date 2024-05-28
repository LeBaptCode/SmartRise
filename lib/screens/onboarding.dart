import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_rise/ressources/app_colors.dart';
import 'package:smart_rise/screens/home.dart';
import 'package:smart_rise/utils.dart';

class OnboardingPage extends StatefulWidget {
  static const String id = "/onboarding";

  const OnboardingPage({super.key});

  @override
  OnboardingPageState createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  late TextEditingController _userNameController;
  String _userNameErrorMessage = '';
  String _birthDateErrorMessage = '';
  DateTime? _birthDate;
  final PageController _pageController = PageController();
  bool _isFirstUse = true;
  DateTime? initialDateTime;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _initFirstUseDate();
  }

  void _initFirstUseDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstUse = prefs.getBool('isFirstUse') ?? true;
    if (isFirstUse) {
      DateTime now = DateTime.now();
      initialDateTime = DateTime(now.year, now.month, now.day);

      await prefs.setBool('isFirstUse', false);
      await prefs.setString('initialDateTime', initialDateTime!.toIso8601String());

      setState(() {
        _isFirstUse = false;
      });
    } else {
      String? dateString = prefs.getString('initialDateTime');
      if (dateString != null) {
        initialDateTime = DateTime.parse(dateString);
      }

      setState(() {
        _isFirstUse = false;
      });
    }
  }


  Future<void> _saveData() async {
    HapticFeedback.lightImpact();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String userName = _userNameController.text.trim();
    DateTime? birthDate = _birthDate;
    int age = _calculateAge(birthDate!);
    print("calculated age to store : $age");

    setState(() {
      _userNameErrorMessage = '';
      _birthDateErrorMessage = '';

      if (userName.isEmpty) {
        _userNameErrorMessage = 'Veuillez saisir votre prénom.';
      }
    });

    if (_userNameErrorMessage.isEmpty && _birthDateErrorMessage.isEmpty) {
      await prefs.setString('userName', userName);
      await prefs.setString('birthDate', birthDate.toIso8601String());
      await prefs.setInt('age', age);
      if (mounted) {
        Navigator.pushReplacementNamed(context, AlarmHomeScreen.id);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(now.year - 18, now.month, now.day);
    final DateTime firstDate = DateTime(now.year - 120, now.month, now.day);
    final DateTime lastDate = DateTime(now.year - 6, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      cancelText: 'Annuler',
      helpText: 'Date de naissance (au moins 6ans)',
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateErrorMessage = ''; // Réinitialisation du message d'erreur
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildInfoPage(context),
          _buildFormPage(context),
        ],
      ),
    );
  }

  Widget _buildInfoPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SmartRise',
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              color: AppColors.mainTextColor,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.03),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          backgroundColor: AppColors.confirmTextColor,
          child: const Icon(Icons.arrow_forward),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Image(image: AssetImage('assets/images/illustration.png')),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                    Container(
                      padding: const EdgeInsets.all(20.0),
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 40.0), // Adjust the spacing as needed
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 12.0,
                    height: 12.0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blueTextColor,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mainTextColor2.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              color: AppColors.mainTextColor,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.03),
        child: FloatingActionButton.extended(
          onPressed: _saveData,
          label: Text(
            'Save',
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Center(
                child: Column(
                  children: [
                    ListTile(
                      title: Row( // Wrap the title and the icon in a Row
                        children: [
                          Expanded(
                            child: Text(
                              'Date de naissance',
                              style: GoogleFonts.roboto(
                                textStyle: const TextStyle(
                                  color: AppColors.mainTextColor2,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today,
                                color: AppColors.blueTextColor, size: 30),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _selectDate(context);
                              },
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top : 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_birthDate != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                                    style: GoogleFonts.bungee(
                                      textStyle: const TextStyle(
                                        color: AppColors.mainTextColor,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Âge: ',
                                          style: GoogleFonts.roboto(
                                            textStyle: const TextStyle(
                                              color: AppColors.mainTextColor2,
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        TextSpan(
                                          text: '${_calculateAge(_birthDate!)} ans',
                                          style: GoogleFonts.bungee(
                                            textStyle: const TextStyle(
                                              color: AppColors.mainTextColor,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            if (_birthDateErrorMessage.isNotEmpty)
                              Text(
                                _birthDateErrorMessage,
                                style: GoogleFonts.sriracha(
                                  textStyle: const TextStyle(
                                    color: AppColors.cancelTextColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
                          cursorColor: AppColors.mainTextColor,
                          maxLines: 1,
                          style: GoogleFonts.sriracha(
                            textStyle: const TextStyle(
                              color: AppColors.mainTextColor,
                              fontSize: 25,
                            ),
                          ),
                          onTap: () => HapticFeedback.selectionClick(),
                          onChanged: (value) {
                            setState(() {
                              _userNameErrorMessage = ''; // Réinitialisation du message d'erreur
                            });
                          },
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
                            errorText: _userNameErrorMessage.isNotEmpty ? _userNameErrorMessage : null,
                            errorStyle: GoogleFonts.sriracha(
                              textStyle: const TextStyle(
                                color: AppColors.cancelTextColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          autocorrect: false,
                          enableSuggestions: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 40.0), // Adjust the spacing as needed
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mainTextColor2.withOpacity(0.3),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 12.0,
                    height: 12.0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.blueTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
