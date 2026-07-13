import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solo_food/main.dart';
import 'package:solo_food/models/fridge_item.dart';
import 'package:solo_food/services/receipt_parser.dart';
import 'package:solo_food/state/fridge_store.dart';

void main() {
  testWidgets('냉장고 홈에 더미 재료와 신호등 버튼이 보인다', (tester) async {
    await tester.pumpWidget(SoloFoodApp(store: FridgeStore(), parser: MockReceiptParser()));

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

  testWidgets('입력 루프: 붙여넣기 → 확인 → 냉장고 반영', (tester) async {
    final store = FridgeStore(initial: []);
    await tester.pumpWidget(SoloFoodApp(store: store, parser: MockReceiptParser()));

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
}
