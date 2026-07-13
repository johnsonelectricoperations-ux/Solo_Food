/// 신선도 신호등 단계 (idea.md 킬러 기능 2)
enum Freshness { green, yellow, red }

/// 냉장고 내 배치 구역 (docs/screens.md S3)
enum FridgeSection { shelf1, shelf2, shelf3, door, freezer }

class FridgeItem {
  final String name;

  /// 전용 아이콘 제작 전까지는 이모지를 플레이스홀더로 사용
  final String emoji;
  final FridgeSection section;

  /// 남은 양 (0.0 ~ 1.0) — 채움 게이지로 표시
  final double amount;

  /// 셀 수 있는 품목의 개수 (계란 ×6). 1이면 뱃지 생략
  final int count;

  /// 추정 유통기한까지 남은 일수 (영수증 기반 추정치)
  final int daysLeft;

  const FridgeItem({
    required this.name,
    required this.emoji,
    required this.section,
    this.amount = 1.0,
    this.count = 1,
    required this.daysLeft,
  });

  static const int _yellowThresholdDays = 3;

  Freshness get freshness {
    if (daysLeft <= 0) return Freshness.red;
    if (daysLeft <= _yellowThresholdDays) return Freshness.yellow;
    return Freshness.green;
  }
}

/// 1단계 개발용 더미 데이터 (docs/screens.md 개발 순서 ①)
const dummyFridgeItems = [
  FridgeItem(name: '우유', emoji: '🥛', section: FridgeSection.door, amount: 0.6, daysLeft: 4),
  FridgeItem(name: '계란', emoji: '🥚', section: FridgeSection.shelf1, count: 6, daysLeft: 12),
  FridgeItem(name: '두부', emoji: '⬜', section: FridgeSection.shelf1, amount: 0.5, daysLeft: 0),
  FridgeItem(name: '대파', emoji: '🥬', section: FridgeSection.shelf3, amount: 0.7, daysLeft: 2),
  FridgeItem(name: '애호박', emoji: '🥒', section: FridgeSection.shelf3, amount: 0.5, daysLeft: 3),
  FridgeItem(name: '양파', emoji: '🧅', section: FridgeSection.shelf3, count: 3, daysLeft: 14),
  FridgeItem(name: '김치', emoji: '🌶️', section: FridgeSection.shelf2, amount: 0.8, daysLeft: 30),
  FridgeItem(name: '고추장', emoji: '🟥', section: FridgeSection.door, amount: 0.9, daysLeft: 90),
  FridgeItem(name: '삼겹살', emoji: '🥓', section: FridgeSection.freezer, amount: 1.0, daysLeft: 60),
  FridgeItem(name: '만두', emoji: '🥟', section: FridgeSection.freezer, amount: 0.4, daysLeft: 45),
];
