import 'package:flutter/material.dart';

import 'screens/fridge_screen.dart';
import 'services/receipt_parser.dart';
import 'services/recipe_service.dart';
import 'state/fridge_store.dart';

void main() {
  runApp(SoloFoodApp(
    store: FridgeStore(),
    // 두 서비스 모두 Supabase Edge Function(LLM) 연동 시 교체
    parser: MockReceiptParser(),
    recipeService: MockRecipeService(),
  ));
}

class SoloFoodApp extends StatelessWidget {
  const SoloFoodApp({
    super.key,
    required this.store,
    required this.parser,
    required this.recipeService,
  });

  final FridgeStore store;
  final ReceiptParser parser;
  final RecipeService recipeService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zero-Waste Kitchen',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        fontFamily: 'NotoSansKR',
      ),
      home: FridgeScreen(store: store, parser: parser, recipeService: recipeService),
    );
  }
}
