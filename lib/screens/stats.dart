import 'package:flutter/material.dart';

class StatsPage extends StatelessWidget {
  final DateTime selectedDate;

  const StatsPage({Key? key, required this.selectedDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stats'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Date sélectionnée : ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Retourner à la page précédente
                Navigator.pop(context);
              },
              child: Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
