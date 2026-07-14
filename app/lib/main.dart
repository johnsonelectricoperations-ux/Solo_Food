import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'models/user_profile.dart';
import 'screens/fridge_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screens.dart';
import 'services/app_storage.dart';
import 'services/hard_constraint_guard.dart';
import 'services/receipt_parser.dart';
import 'services/recipe_service.dart';
import 'services/supabase_receipt_parser.dart';
import 'services/supabase_storage.dart';
import 'state/fridge_store.dart';
import 'state/profile_store.dart';

void main() {
  runApp(const BootstrapApp());
}

/// Supabase 초기화 → 로그인 게이트 → 데이터 로드 → 본 앱.
/// (main을 async로 만들면 웹에서 첫 프레임이 붙지 않는 문제가 있어 위젯 안에서 초기화)
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late final Future<SupabaseClient> _initFuture = _init();

  Future<SupabaseClient> _init() async {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
    return Supabase.instance.client;
  }

  static const _theme = _AppTheme();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _theme.wrap(const Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        final client = snapshot.data!;
        // 로그인 상태가 바뀌면(로그인/로그아웃) 화면을 전환한다
        return StreamBuilder<AuthState>(
          stream: client.auth.onAuthStateChange,
          builder: (context, _) {
            final session = client.auth.currentSession;
            if (session == null) {
              return _theme.wrap(const LoginScreen());
            }
            return _LoadedApp(key: ValueKey(session.user.id), client: client);
          },
        );
      },
    );
  }
}

/// 로그인 이후: 클라우드에서 프로필·냉장고를 읽어 앱을 띄운다.
class _LoadedApp extends StatefulWidget {
  const _LoadedApp({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<_LoadedApp> createState() => _LoadedAppState();
}

class _LoadedAppState extends State<_LoadedApp> {
  late final SupabaseStorage _storage = SupabaseStorage(widget.client);
  late final Future<(UserProfile?, FridgeData?)> _loadFuture = _load();

  Future<(UserProfile?, FridgeData?)> _load() async {
    final profile = await _storage.loadProfile();
    final fridge = await _storage.loadFridge();
    return (profile, fridge);
  }

  static const _theme = _AppTheme();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _theme.wrap(const Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        final (profile, fridge) = snapshot.data!;
        final profileStore = ProfileStore(initial: profile, storage: _storage);
        final store = FridgeStore(
          initial: fridge?.items ?? const [], // 신규 유저는 빈 냉장고에서 시작
          naengpaCount: fridge?.naengpaCount ?? 0,
          discardCount: fridge?.discardCount ?? 0,
          storage: _storage,
        );
        return SoloFoodApp(
          store: store,
          profileStore: profileStore,
          // 서버(비전 LLM) 인식 실패 시 임시 인식기로 폴백
          parser: FallbackReceiptParser(
            primary: SupabaseReceiptParser(widget.client),
            fallback: MockReceiptParser(),
          ),
          recipeService: HardConstraintGuard(
            inner: MockRecipeService(), // 레시피 엔진 실연동은 다음 단계
            profileStore: profileStore,
          ),
        );
      },
    );
  }
}

class _AppTheme {
  const _AppTheme();

  Widget wrap(Widget home) => MaterialApp(
        title: 'Zero-Waste Kitchen',
        theme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
          fontFamily: 'NotoSansKR',
        ),
        home: home,
      );
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
