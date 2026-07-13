import '../models/fridge_item.dart';

/// 파싱 결과 한 줄 (S5에서 유저가 수정 후 확정하는 단위)
class ParsedItem {
  ParsedItem({
    required this.name,
    required this.emoji,
    required this.section,
    this.count = 1,
    required this.daysLeft,
  });

  String name;
  String emoji;
  FridgeSection section;
  int count;
  int daysLeft;

  FridgeItem toFridgeItem() => FridgeItem(
        name: name,
        emoji: emoji,
        section: section,
        count: count,
        daysLeft: daysLeft,
      );
}

class ParseResult {
  const ParseResult({required this.items, required this.excluded});

  final List<ParsedItem> items;

  /// 식재료가 아니라고 판단해 제외한 품목 (오탐 구제용으로 S5에서 보여준다)
  final List<String> excluded;
}

/// 영수증/주문내역 → 품목 파서.
/// 실제 구현은 Supabase Edge Function에서 비전 LLM을 호출한다 (idea.md 9번).
abstract class ReceiptParser {
  Future<ParseResult> parseText(String text);

  Future<ParseResult> parsePhoto();
}

/// 개발용 모의 파서: 붙여넣은 텍스트에서 알려진 식재료 이름을 찾아낸다.
/// LLM 연동 전까지 입력 루프(S4→S5→냉장고)를 만들고 검증하기 위한 것.
class MockReceiptParser implements ReceiptParser {
  /// (이름, 이모지, 구역, 추정 보관일)
  static const _knownFoods = [
    ('두부', '⬜', FridgeSection.shelf1, 3),
    ('계란', '🥚', FridgeSection.shelf1, 14),
    ('우유', '🥛', FridgeSection.door, 5),
    ('대파', '🥬', FridgeSection.shelf3, 7),
    ('양파', '🧅', FridgeSection.shelf3, 21),
    ('애호박', '🥒', FridgeSection.shelf3, 7),
    ('감자', '🥔', FridgeSection.shelf3, 21),
    ('당근', '🥕', FridgeSection.shelf3, 14),
    ('김치', '🌶️', FridgeSection.shelf2, 30),
    ('삼겹살', '🥓', FridgeSection.freezer, 60),
    ('닭가슴살', '🍗', FridgeSection.freezer, 60),
    ('만두', '🥟', FridgeSection.freezer, 90),
  ];

  static const _simulatedDelay = Duration(milliseconds: 800);

  @override
  Future<ParseResult> parseText(String text) async {
    await Future<void>.delayed(_simulatedDelay); // LLM 호출 지연 시뮬레이션

    final items = <ParsedItem>[];
    final excluded = <String>[];

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final match = _knownFoods.where((f) => line.contains(f.$1)).firstOrNull;
      if (match != null) {
        final (name, emoji, section, days) = match;
        items.add(ParsedItem(
          name: name,
          emoji: emoji,
          section: section,
          count: _guessCount(line),
          daysLeft: days,
        ));
      } else {
        excluded.add(line);
      }
    }
    return ParseResult(items: items, excluded: excluded);
  }

  @override
  Future<ParseResult> parsePhoto() async {
    await Future<void>.delayed(_simulatedDelay);
    // 실기기 카메라 + 비전 LLM 연동 전까지는 그럴듯한 영수증 결과를 돌려준다.
    return ParseResult(
      items: [
        ParsedItem(name: '두부', emoji: '⬜', section: FridgeSection.shelf1, daysLeft: 3),
        ParsedItem(name: '대파', emoji: '🥬', section: FridgeSection.shelf3, daysLeft: 7),
        ParsedItem(name: '계란', emoji: '🥚', section: FridgeSection.shelf1, count: 10, daysLeft: 14),
      ],
      excluded: ['P)물티슈캡형70매', '종량제봉투20L'],
    );
  }

  /// "계란 10구", "양파 3입" 같은 줄에서 개수 추정 (실패하면 1)
  int _guessCount(String line) {
    final m = RegExp(r'(\d+)\s*(구|입|개|알|入)').firstMatch(line);
    return m == null ? 1 : int.parse(m.group(1)!);
  }
}
