import 'package:flutter_test/flutter_test.dart';
import 'package:solo_food/main.dart';
import 'package:solo_food/models/fridge_item.dart';

void main() {
  testWidgets('냉장고 홈에 더미 재료와 신호등 버튼이 보인다', (tester) async {
    await tester.pumpWidget(const SoloFoodApp());

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
}
