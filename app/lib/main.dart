import 'package:flutter/material.dart';

import 'screens/fridge_screen.dart';
import 'screens/onboarding_screens.dart';
import 'services/hard_constraint_guard.dart';
import 'services/local_storage.dart';
import 'services/receipt_parser.dart';
import 'services/recipe_service.dart';
import 'state/fridge_store.dart';
import 'state/profile_store.dart';

void main() {
  runApp(const BootstrapApp());
}

/// 로컬 저장소를 연 뒤 본 앱을 띄운다.
/// (main을 async로 만들면 웹에서 첫 프레임이 붙지 않는 문제가 있어 위젯 안에서 로드)
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late final Future<LocalStorage?> _storageFuture = _open();

  Future<LocalStorage?> _open() async {
    try {
      return await LocalStorage.open();
    } catch (e) {
      // 저장소를 못 열어도 앱은 떠야 한다 (메모리 모드로 동작)
      debugPrint('LocalStorage.open 실패: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _storageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final storage = snapshot.data;
        final profileStore = ProfileStore(storage: storage);
        return SoloFoodApp(
          store: FridgeStore(storage: storage),
          profileStore: profileStore,
          // 두 서비스 모두 Supabase Edge Function(LLM) 연동 시 교체.
          // HardConstraintGuard는 어떤 구현으로 바뀌어도 유지된다 (3겹 필터의 최종 검사).
          parser: MockReceiptParser(),
          recipeService: HardConstraintGuard(
            inner: MockRecipeService(),
            profileStore: profileStore,
          ),
        );
      },
    );
  }
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
