import 'package:flutter/material.dart';

import 'screens/fridge_screen.dart';
import 'services/receipt_parser.dart';
import 'state/fridge_store.dart';

void main() {
  runApp(SoloFoodApp(
    store: FridgeStore(),
    parser: MockReceiptParser(), // Supabase Edge Function 연동 시 교체
  ));
}

class SoloFoodApp extends StatelessWidget {
  const SoloFoodApp({super.key, required this.store, required this.parser});

  final FridgeStore store;
  final ReceiptParser parser;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zero-Waste Kitchen',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        fontFamily: 'NotoSansKR',
      ),
      home: FridgeScreen(store: store, parser: parser),
    );
  }
}
