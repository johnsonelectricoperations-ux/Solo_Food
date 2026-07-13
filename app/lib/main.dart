import 'package:flutter/material.dart';

import 'screens/fridge_screen.dart';

void main() {
  runApp(const SoloFoodApp());
}

class SoloFoodApp extends StatelessWidget {
  const SoloFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zero-Waste Kitchen',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        fontFamily: 'NotoSansKR',
      ),
      home: const FridgeScreen(),
    );
  }
}
