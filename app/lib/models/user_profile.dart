/// 식단 유형 (S2 온보딩 — 원탭 선택)
enum DietType {
  normal('일반', '가리는 것 없이 다 먹어요'),
  vegan('비건', '고기·계란·유제품을 빼요'),
  lowSugar('저당', '당을 줄인 식단을 원해요'),
  lowSalt('저염', '염분을 줄인 식단을 원해요');

  const DietType(this.label, this.description);

  final String label;
  final String description;
}

/// 취향 프로필 (idea.md 유저 여정 0단계)
/// - 알레르기·비건 금기 = 하드 제약: 레시피에 절대 등장하면 안 된다
/// - 저당·저염 = 소프트 선호: 랭킹 가중치로만 사용 (아직 미구현, 2차)
class UserProfile {
  const UserProfile({required this.allergens, required this.dietType});

  /// 유저가 직접 고른 알레르기·기피 재료
  final Set<String> allergens;

  final DietType dietType;

  /// 비건 선택 시 금지되는 동물성 재료 (모의 레시피 재료 기준.
  /// 실서비스에서는 공공 DB 재료 정규화 테이블에서 분류를 가져온다)
  static const veganBanned = {'계란', '우유', '삼겹살', '닭가슴살', '치즈', '버터', '만두'};

  /// 하드 제약 재료 전체 (알레르기 + 식단 금기)
  Set<String> get bannedIngredients => {
        ...allergens,
        if (dietType == DietType.vegan) ...veganBanned,
      };
}
