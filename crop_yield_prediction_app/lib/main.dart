import 'package:crop_yield_prediction_app/screen/prediction-form.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Yield Predictor',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Color(0xFF2E7D32),
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CropPredictionForm(),
      debugShowCheckedModeBanner: false,
    );
  }
}
