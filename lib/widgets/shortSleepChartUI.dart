import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Linear interpolation: https://en.wikipedia.org/wiki/Linear_interpolation
double lerp(num a, num b, double t) {
  return a.toDouble() * (1.0 - t) + b.toDouble() * t;
}

// Inverse lerp: https://www.gamedev.net/articles/programming/general-and-gameplay-programming/inverse-lerp-a-super-useful-yet-often-overlooked-function-r5230/
double invlerp(num a, num b, num x) {
  return (x - a.toDouble()) / (b.toDouble() - a.toDouble());
}

// For interpolating between colors
Color lerpColor(Color a, Color b, double t) {
  int lerpInt(int a, int b, double t) => lerp(a, b, t).round();
  return Color.fromARGB(
    lerpInt(a.alpha, b.alpha, t),
    lerpInt(a.red, b.red, t),
    lerpInt(a.green, b.green, t),
    lerpInt(a.blue, b.blue, t),
  );
}

// Data class for gradient data
class GradientData {
  final List<double> stops;
  final List<Color> colors;

  GradientData(this.stops, this.colors)
      : assert(stops.length == colors.length);

  // Get the color value at any point in a gradient
  Color getColor(double t) {
    assert(stops.length == colors.length);
    if (t <= 0) return colors.first;
    if (t >= 1) return colors.last;

    for (int i = 0; i < stops.length - 1; i++) {
      final stop = stops[i];
      final nextStop = stops[i + 1];
      final color = colors[i];
      final nextColor = colors[i + 1];
      if (t >= stop && t < nextStop) {
        final lerpT = invlerp(stop, nextStop, t);
        return lerpColor(color, nextColor, lerpT);
      }
    }

    return colors.last;
  }

  // Calculate a new gradient for a subset of this gradient
  GradientData getConstrainedGradient(
      double dataYMin, // Min y-value of the data set
      double dataYMax, // Max y-value of the data set
      double graphYMin, // Min value of the y-axis
      double graphYMax, // Max value of the y-axis
      ) {
    // The "new" beginning and end stop positions for the gradient
    final tMin = invlerp(graphYMin, graphYMax, dataYMin);
    final tMax = invlerp(graphYMin, graphYMax, dataYMax);

    final newStops = <double>[];
    final newColors = <Color>[];

    newStops.add(0);
    newColors.add(getColor(tMin));

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final color = colors[i];
      if (stop <= tMin || stop >= tMax) continue;
      final stopT = invlerp(tMin, tMax, stop);
      newStops.add(stopT);
      newColors.add(color);
    }

    newStops.add(1);
    newColors.add(getColor(tMax));

    return GradientData(newStops, newColors);
  }
}

class SleepGraph extends StatefulWidget {
  const SleepGraph({Key? key, required this.sleepRecord, required this.selectedDate}) : super(key: key);

  final List<int> sleepRecord;
  final DateTime selectedDate;

  @override
  _SleepGraphState createState() => _SleepGraphState();
}

class _SleepGraphState extends State<SleepGraph> {
  late List<FlSpot> spots;
  late GradientData gradientData = GradientData([0.0, 0.25, 0.5, 0.75, 1.0], [Colors.orange.shade600, Colors.lightBlueAccent, Colors.blueAccent, Colors.indigoAccent]);



  @override
  void initState() {
    super.initState();
    spots = List.generate(widget.sleepRecord.length, (index) => FlSpot(index.toDouble(), widget.sleepRecord[index].toDouble()));
    gradientData = GradientData([0.0, 0.33, 0.66, 1.0], [Colors.orange.shade600, Colors.lightBlueAccent, Colors.blueAccent, Colors.indigoAccent]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(DateFormat('EEE MMM d').format(widget.selectedDate), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.20,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: widget.sleepRecord.length.toDouble() - 1,
                minY: 0,
                maxY: 3,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    lineChartStepData: const LineChartStepData(
                      stepDirection: LineChartStepData.stepDirectionMiddle,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradientData.colors,
                      stops: gradientData.stops,
                    ),
                    barWidth: 1,
                    isStepLineChart: true,
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, _) {
                        switch (value.toInt()) {
                          case 3:
                            return SideTitleWidget(
                              child: Text('Awake', style: TextStyle(color: Colors.orange.shade600, fontSize: 10)),
                              axisSide: AxisSide.left,
                              space: 10,
                            );
                          case 2:
                            return SideTitleWidget(
                              child: Text('REM', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 10)),
                              axisSide: AxisSide.left,
                              space: 10,
                            );
                          case 1:
                            return SideTitleWidget(
                              child: Text('Light', style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
                              axisSide: AxisSide.left,
                              space: 10,
                            );
                          case 0:
                            return SideTitleWidget(
                              child: Text('Deep', style: TextStyle(color: Colors.indigoAccent, fontSize: 10)),
                              axisSide: AxisSide.left,
                              space: 10,
                            );
                          default:
                            return SizedBox(); // Retourne une boîte vide par défaut
                        }
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(
                  enabled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
