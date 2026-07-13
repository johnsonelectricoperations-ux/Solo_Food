import 'package:flutter/material.dart';

import 'screens/fridge_screen.dart';
import 'screens/onboarding_screens.dart';
import 'services/hard_constraint_guard.dart';
import 'services/receipt_parser.dart';
import 'services/recipe_service.dart';
import 'state/fridge_store.dart';
import 'state/profile_store.dart';

void main() {
  final profileStore = ProfileStore();
  runApp(SoloFoodApp(
    store: FridgeStore(),
    profileStore: profileStore,
    // 두 서비스 모두 Supabase Edge Function(LLM) 연동 시 교체.
    // HardConstraintGuard는 어떤 구현으로 바뀌어도 유지된다 (3겹 필터의 최종 검사).
    parser: MockReceiptParser(),
    recipeService: HardConstraintGuard(
      inner: MockRecipeService(),
      profileStore: profileStore,
    ),
  ));
}

class SoloFoodApp extends StatelessWidget {
  const SoloFoodApp({
    super.key,
    required this.store,
    required this.profileStore,
    required this.parser,
    required this.recipeService,
  });

  final FridgeStore store;
  final ProfileStore profileStore;
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
      home: ListenableBuilder(
        listenable: profileStore,
        builder: (context, _) => profileStore.onboardingDone
            ? FridgeScreen(
                store: store,
                parser: parser,
                recipeService: recipeService,
                profileStore: profileStore,
              )
            : OnboardingFlow(profileStore: profileStore),
      ),
    );
  }
}
