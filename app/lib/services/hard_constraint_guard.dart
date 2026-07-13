import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../state/profile_store.dart';
import 'recipe_service.dart';

/// 하드 제약 최종 검사 (idea.md 6번 — 3겹 필터의 3번째 겹).
///
/// 어떤 RecipeService든(모의든 LLM이든) 이 데코레이터를 통과해야 화면에 닿는다.
/// LLM이 변형 단계에서 금지 재료를 대체 재료로 넣는 사고를 막는 마지막 방어선이므로,
/// 안쪽 서비스가 이미 필터링했더라도(1·2겹) 여기서 무조건 다시 검사한다.
class HardConstraintGuard implements RecipeService {
  const HardConstraintGuard({required this.inner, required this.profileStore});

  final RecipeService inner;
  final ProfileStore profileStore;

  @override
  Future<List<RecipeMatch>> recommend(fridge) async {
    final matches = await inner.recommend(fridge);
    final profile = profileStore.profile;
    if (profile == null) return matches;

    return [
      for (final m in matches)
        if (!violates(m.recipe, profile)) m,
    ];
  }

  /// 레시피 재료 목록에 금지 재료가 하나라도 있으면 true.
  /// LLM 출력을 신뢰하지 않고 코드로 검사하는 지점이라 규칙 기반으로만 판단한다.
  static bool violates(Recipe recipe, UserProfile profile) {
    final banned = profile.bannedIngredients;
    return recipe.ingredients.any(
      (ing) => banned.any((b) => ing.name.contains(b)),
    );
  }
}
