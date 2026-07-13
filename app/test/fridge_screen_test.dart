import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solo_food/main.dart';
import 'package:solo_food/models/fridge_item.dart';
import 'package:solo_food/models/user_profile.dart';
import 'package:solo_food/services/hard_constraint_guard.dart';
import 'package:solo_food/services/receipt_parser.dart';
import 'package:solo_food/services/recipe_service.dart';
import 'package:solo_food/state/fridge_store.dart';
import 'package:solo_food/state/profile_store.dart';

ProfileStore _doneProfile({Set<String> allergens = const {}, DietType diet = DietType.normal}) =>
    ProfileStore()..save(UserProfile(allergens: allergens, dietType: diet));

Widget _app(FridgeStore store, {ProfileStore? profileStore}) {
  final profiles = profileStore ?? _doneProfile();
  return SoloFoodApp(
    store: store,
    profileStore: profiles,
    parser: MockReceiptParser(),
    recipeService: HardConstraintGuard(inner: MockRecipeService(), profileStore: profiles),
  );
}

void main() {
  testWidgets('냉장고 홈에 더미 재료와 신호등 버튼이 보인다', (tester) async {
    await tester.pumpWidget(_app(FridgeStore()));

    expect(find.text('내 냉장고'), findsOneWidget);
    expect(find.text('두부'), findsOneWidget);
    expect(find.text('계란'), findsOneWidget);
    // 두부(D-0)가 빨강이므로 털어먹기 버튼이 떠야 한다
    expect(find.textContaining('빨간 애들 털어먹기'), findsOneWidget);
  });

  test('신선도 신호등 경계값', () {
    const red = FridgeItem(name: 't', emoji: 'x', section: FridgeSection.shelf1, daysLeft: 0);
    const yellow = FridgeItem(name: 't', emoji: 'x', section: FridgeSection.shelf1, daysLeft: 3);
    const green = FridgeItem(name: 't', emoji: 'x', section: FridgeSection.shelf1, daysLeft: 4);

    expect(red.freshness, Freshness.red);
    expect(yellow.freshness, Freshness.yellow);
    expect(green.freshness, Freshness.green);
  });

  group('MockReceiptParser', () {
    test('텍스트에서 식재료를 찾고 개수를 추정한다', () async {
      final result = await MockReceiptParser()
          .parseText('두부 300g 1개\n계란 10구\n종량제봉투 20L');

      expect(result.items.map((i) => i.name), ['두부', '계란']);
      expect(result.items[1].count, 10);
      expect(result.excluded, ['종량제봉투 20L']);
    });

    test('빈 입력이면 아무것도 인식하지 않는다', () async {
      final result = await MockReceiptParser().parseText('');
      expect(result.items, isEmpty);
    });
  });

  group('MockRecipeService', () {
    test('빨강 재료를 구하는 레시피가 최상단에 온다', () async {
      final fridge = [
        const FridgeItem(name: '두부', emoji: 'x', section: FridgeSection.shelf1, daysLeft: 0),
        const FridgeItem(name: '양파', emoji: 'x', section: FridgeSection.shelf3, daysLeft: 14),
        const FridgeItem(name: '계란', emoji: 'x', section: FridgeSection.shelf1, count: 6, daysLeft: 12),
        const FridgeItem(name: '당근', emoji: 'x', section: FridgeSection.shelf3, daysLeft: 12),
      ];
      final matches = await MockRecipeService().recommend(fridge);

      expect(matches, isNotEmpty);
      // 1위 레시피는 빨강인 두부를 사용해야 한다
      expect(matches.first.owned.values.map((i) => i.name), contains('두부'));
    });

    test('겹치는 재료가 2개 미만이면 추천하지 않는다', () async {
      final fridge = [
        const FridgeItem(name: '우유', emoji: 'x', section: FridgeSection.door, daysLeft: 5),
      ];
      final matches = await MockRecipeService().recommend(fridge);
      expect(matches, isEmpty);
    });
  });

  group('FridgeStore.applyDeductions', () {
    test('양 차감·소진 제거·냉파 카운트가 동작한다', () {
      const tofu = FridgeItem(name: '두부', emoji: 'x', section: FridgeSection.shelf1, amount: 0.5, daysLeft: 0);
      const eggs = FridgeItem(name: '계란', emoji: 'x', section: FridgeSection.shelf1, count: 10, daysLeft: 12);
      final store = FridgeStore(initial: [tofu, eggs]);

      final naengpa = store.applyDeductions([
        const Deduction(tofu, 0.5), // 남은 0.5를 다 씀 → 소진 제거
        const Deduction(eggs, 0.5), // 10개 중 5개 사용
      ]);

      expect(naengpa, isTrue); // 두부가 빨강이었으므로 냉파 성공
      expect(store.naengpaCount, 1);
      expect(store.items.map((i) => i.name), ['계란']);
      expect(store.items.first.count, 5);
    });

    test('안 씀(0)만 있으면 냉파가 아니다', () {
      const tofu = FridgeItem(name: '두부', emoji: 'x', section: FridgeSection.shelf1, daysLeft: 0);
      final store = FridgeStore(initial: [tofu]);

      final naengpa = store.applyDeductions([const Deduction(tofu, 0)]);

      expect(naengpa, isFalse);
      expect(store.naengpaCount, 0);
      expect(store.items, hasLength(1));
    });
  });

  testWidgets('입력 루프: 붙여넣기 → 확인 → 냉장고 반영', (tester) async {
    final store = FridgeStore(initial: []);
    await tester.pumpWidget(_app(store));

    // FAB → S4
    await tester.tap(find.byTooltip('재료 채우기'));
    await tester.pumpAndSettle();

    // 붙여넣기 탭으로 이동 후 텍스트 입력
    await tester.tap(find.text('주문내역 붙여넣기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '애호박 1개\n우유 900ml');
    await tester.tap(find.text('재료 인식하기'));
    await tester.pumpAndSettle();

    // S5: 인식 결과 확인 후 담기
    expect(find.text('애호박'), findsOneWidget);
    expect(find.text('우유'), findsOneWidget);
    await tester.tap(find.text('냉장고에 담기'));
    await tester.pumpAndSettle();

    // S3로 복귀했고 냉장고에 들어갔다
    expect(find.text('내 냉장고'), findsOneWidget);
    expect(store.items.map((i) => i.name), containsAll(['애호박', '우유']));
  });

  group('하드 제약 3겹 필터 (최종 검사)', () {
    final fridge = [
      const FridgeItem(name: '두부', emoji: 'x', section: FridgeSection.shelf1, daysLeft: 0),
      const FridgeItem(name: '계란', emoji: 'x', section: FridgeSection.shelf1, count: 6, daysLeft: 12),
      const FridgeItem(name: '대파', emoji: 'x', section: FridgeSection.shelf3, daysLeft: 2),
      const FridgeItem(name: '양파', emoji: 'x', section: FridgeSection.shelf3, daysLeft: 14),
      const FridgeItem(name: '김치', emoji: 'x', section: FridgeSection.shelf2, daysLeft: 30),
      const FridgeItem(name: '삼겹살', emoji: 'x', section: FridgeSection.freezer, daysLeft: 60),
    ];

    test('계란 알레르기면 계란 레시피가 절대 나오지 않는다', () async {
      final guard = HardConstraintGuard(
        inner: MockRecipeService(),
        profileStore: _doneProfile(allergens: {'계란'}),
      );
      final matches = await guard.recommend(fridge);

      expect(matches, isNotEmpty);
      for (final m in matches) {
        expect(m.recipe.ingredients.map((i) => i.name), isNot(contains('계란')));
      }
    });

    test('비건이면 고기·계란 레시피가 전부 걸러진다', () async {
      final guard = HardConstraintGuard(
        inner: MockRecipeService(),
        profileStore: _doneProfile(diet: DietType.vegan),
      );
      final matches = await guard.recommend(fridge);

      for (final m in matches) {
        for (final ing in m.recipe.ingredients) {
          expect(UserProfile.veganBanned.contains(ing.name), isFalse,
              reason: '${m.recipe.name}에 동물성 재료 ${ing.name}이 남아 있다');
        }
      }
    });
  });

  group('FridgeStore B2 보정', () {
    const urgentTofu =
        FridgeItem(name: '두부', emoji: 'x', section: FridgeSection.shelf1, daysLeft: 0);
    const eggs =
        FridgeItem(name: '계란', emoji: 'x', section: FridgeSection.shelf1, count: 6, daysLeft: 12);

    test('다 먹음: 제거 + 임박이면 냉파 성공', () {
      final store = FridgeStore(initial: [urgentTofu]);
      expect(store.markEaten(urgentTofu), isTrue);
      expect(store.naengpaCount, 1);
      expect(store.items, isEmpty);
    });

    test('반 남음: 개수는 절반 올림, 양은 절반', () {
      final store = FridgeStore(initial: [urgentTofu, eggs]);
      store.markHalfLeft(eggs);
      store.markHalfLeft(urgentTofu);
      expect(store.items[1].count, 3);
      expect(store.items[0].amount, 0.5);
    });

    test('버림: 제거 + 버림 카운트 (냉파 아님)', () {
      final store = FridgeStore(initial: [urgentTofu]);
      store.markDiscarded(urgentTofu);
      expect(store.items, isEmpty);
      expect(store.discardCount, 1);
      expect(store.naengpaCount, 0);
    });
  });

  testWidgets('첫 실행 온보딩: 알레르기 → 식단 유형 → 홈 진입', (tester) async {
    final profiles = ProfileStore();
    await tester.pumpWidget(_app(FridgeStore(), profileStore: profiles));

    // S1: 알레르기 선택
    expect(find.text('알레르기나 절대 피해야 할 재료가 있나요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, '계란'));
    await tester.pump();
    await tester.tap(find.text('1개 선택하고 다음으로'));
    await tester.pumpAndSettle();

    // S2: 식단 유형 선택 → 홈
    await tester.tap(find.text('비건'));
    await tester.pumpAndSettle();

    expect(find.text('내 냉장고'), findsOneWidget);
    expect(profiles.profile!.allergens, {'계란'});
    expect(profiles.profile!.dietType, DietType.vegan);
  });

  testWidgets('소비 루프: 레시피 → 해먹었어요 → 차감·냉파 성공', (tester) async {
    final store = FridgeStore(); // 더미: 두부(빨강) 포함
    await tester.pumpWidget(_app(store));

    await tester.tap(find.textContaining('빨간 애들 털어먹기'));
    await tester.pumpAndSettle();

    // S6: 1위 카드 진입
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();

    // S7 → 해먹었어요 → B1
    await tester.tap(find.text('🍳 해먹었어요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확정하고 차감하기'));
    await tester.pumpAndSettle();

    // 냉파 성공 후 S3 복귀
    expect(store.naengpaCount, 1);
    expect(find.text('내 냉장고'), findsOneWidget);
    expect(find.textContaining('냉파 성공'), findsOneWidget);
  });
}
