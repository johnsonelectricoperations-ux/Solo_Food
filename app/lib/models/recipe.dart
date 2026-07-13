/// 레시피 재료: 냉장고 품목과 이름으로 매칭된다
class RecipeIngredient {
  const RecipeIngredient(this.name, this.amountLabel, {this.fraction = 1.0});

  final String name;

  /// 화면 표시용 분량 (예: "반 모", "1/2개")
  final String amountLabel;

  /// 이 레시피가 보통 소모하는 비율 (차감 기본값, 0.0~1.0)
  final double fraction;
}

class Recipe {
  const Recipe({
    required this.name,
    required this.emoji,
    required this.ingredients,
    required this.steps,
  });

  final String name;
  final String emoji;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
}
