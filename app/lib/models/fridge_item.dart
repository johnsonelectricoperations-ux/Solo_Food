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

  /// 추정 유통기한 날짜. D-day는 저장 시점이 아니라 조회 시점 기준으로 계산해야
  /// 시간이 지나면 신호등이 실제로 빨개진다.
  final DateTime expiresOn;

  const FridgeItem({
    required this.name,
    required this.emoji,
    required this.section,
    this.amount = 1.0,
    this.count = 1,
    required this.expiresOn,
  });

  /// "오늘로부터 N일 뒤 만료" 편의 생성자 (영수증 파싱·테스트용)
  FridgeItem.expiringIn(
    int days, {
    required this.name,
    required this.emoji,
    required this.section,
    this.amount = 1.0,
    this.count = 1,
  }) : expiresOn = _today().add(Duration(days: days));

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int get daysLeft => expiresOn.difference(_today()).inDays;

  static const int _yellowThresholdDays = 3;

  Freshness get freshness {
    if (daysLeft <= 0) return Freshness.red;
    if (daysLeft <= _yellowThresholdDays) return Freshness.yellow;
    return Freshness.green;
  }

  bool get isCountable => count > 1;

  FridgeItem copyWith({double? amount, int? count}) => FridgeItem(
        name: name,
        emoji: emoji,
        section: section,
        amount: amount ?? this.amount,
        count: count ?? this.count,
        expiresOn: expiresOn,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'emoji': emoji,
        'section': section.name,
        'amount': amount,
        'count': count,
        'expiresOn': expiresOn.toIso8601String(),
      };

  factory FridgeItem.fromJson(Map<String, dynamic> json) => FridgeItem(
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        section: FridgeSection.values.byName(json['section'] as String),
        amount: (json['amount'] as num).toDouble(),
        count: json['count'] as int,
        expiresOn: DateTime.parse(json['expiresOn'] as String),
      );
}

/// 1단계 개발용 더미 데이터 (docs/screens.md 개발 순서 ①)
List<FridgeItem> dummyFridgeItems() => [
      FridgeItem.expiringIn(4, name: '우유', emoji: '🥛', section: FridgeSection.door, amount: 0.6),
      FridgeItem.expiringIn(12, name: '계란', emoji: '🥚', section: FridgeSection.shelf1, count: 6),
      FridgeItem.expiringIn(0, name: '두부', emoji: '⬜', section: FridgeSection.shelf1, amount: 0.5),
      FridgeItem.expiringIn(2, name: '대파', emoji: '🥬', section: FridgeSection.shelf3, amount: 0.7),
      FridgeItem.expiringIn(3, name: '애호박', emoji: '🥒', section: FridgeSection.shelf3, amount: 0.5),
      FridgeItem.expiringIn(14, name: '양파', emoji: '🧅', section: FridgeSection.shelf3, count: 3),
      FridgeItem.expiringIn(30, name: '김치', emoji: '🌶️', section: FridgeSection.shelf2, amount: 0.8),
      FridgeItem.expiringIn(90, name: '고추장', emoji: '🟥', section: FridgeSection.door, amount: 0.9),
      FridgeItem.expiringIn(60, name: '삼겹살', emoji: '🥓', section: FridgeSection.freezer),
      FridgeItem.expiringIn(45, name: '만두', emoji: '🥟', section: FridgeSection.freezer, amount: 0.4),
    ];
