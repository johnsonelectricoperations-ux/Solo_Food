import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solo_food/main.dart';
import 'package:solo_food/models/fridge_item.dart';
import 'package:solo_food/services/receipt_parser.dart';
import 'package:solo_food/services/recipe_service.dart';
import 'package:solo_food/state/fridge_store.dart';

Widget _app(FridgeStore store) => SoloFoodApp(
      store: store,
      parser: MockReceiptParser(),
      recipeService: MockRecipeService(),
    );

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
