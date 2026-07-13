import '../models/fridge_item.dart';
import '../models/recipe.dart';

/// 레시피 1건 + 내 냉장고와의 매칭 정보
class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.owned,
    required this.missing,
  });

  final Recipe recipe;

  /// 냉장고에 있는 재료 (레시피 재료 → 냉장고 품목)
  final Map<RecipeIngredient, FridgeItem> owned;

  /// 냉장고에 없는 재료
  final List<RecipeIngredient> missing;

  List<FridgeItem> get urgentUsed =>
      owned.values.where((i) => i.freshness != Freshness.green).toList();
}

/// 파먹기 레시피 추천.
/// 실제 구현은 공공 레시피 DB 검색 → LLM 변형 (idea.md 6번 계층 2).
abstract class RecipeService {
  Future<List<RecipeMatch>> recommend(List<FridgeItem> fridge);
}

/// 개발용 모의 추천: 내장 레시피 몇 개를 재료 커버리지·임박도 순으로 랭킹.
/// 랭킹 로직 자체는 실서비스와 동일한 규칙을 쓴다 (빨강 소진 기여도 우선).
class MockRecipeService implements RecipeService {
  static const _recipes = [
    Recipe(
      name: '두부 된장찌개',
      emoji: '🍲',
      ingredients: [
        RecipeIngredient('두부', '반 모', fraction: 0.5),
        RecipeIngredient('애호박', '1/3개', fraction: 0.3),
        RecipeIngredient('양파', '1/2개', fraction: 0.5),
        RecipeIngredient('대파', '1/3대', fraction: 0.3),
        RecipeIngredient('된장', '1큰술'),
      ],
      steps: [
        '냄비에 물 400ml를 붓고 된장 1큰술을 풀어 끓인다',
        '양파·애호박을 먹기 좋게 썰어 넣고 3분 끓인다',
        '두부를 깍둑 썰어 넣고 2분 더 끓인다',
        '대파를 송송 썰어 올리고 불을 끈다',
      ],
    ),
    Recipe(
      name: '계란말이',
      emoji: '🍳',
      ingredients: [
        RecipeIngredient('계란', '3알', fraction: 0.5),
        RecipeIngredient('대파', '1/4대', fraction: 0.2),
        RecipeIngredient('당근', '조금', fraction: 0.2),
      ],
      steps: [
        '계란 3알을 풀고 잘게 썬 대파·당근을 섞는다',
        '약불 팬에 기름을 두르고 계란물 1/3을 붓는다',
        '반쯤 익으면 돌돌 말고, 남은 계란물을 부어가며 반복한다',
        '한 김 식힌 뒤 썰어낸다',
      ],
    ),
    Recipe(
      name: '김치찌개',
      emoji: '🥘',
      ingredients: [
        RecipeIngredient('김치', '1/4포기', fraction: 0.3),
        RecipeIngredient('두부', '반 모', fraction: 0.5),
        RecipeIngredient('삼겹살', '한 줌', fraction: 0.3),
        RecipeIngredient('양파', '1/2개', fraction: 0.5),
      ],
      steps: [
        '냄비에 삼겹살을 볶다가 김치를 넣고 2분 더 볶는다',
        '물 400ml를 붓고 10분 끓인다',
        '두부와 양파를 넣고 5분 더 끓인다',
      ],
    ),
    Recipe(
      name: '야채 계란볶음밥',
      emoji: '🍚',
      ingredients: [
        RecipeIngredient('계란', '2알', fraction: 0.3),
        RecipeIngredient('대파', '1/2대', fraction: 0.5),
        RecipeIngredient('양파', '1/4개', fraction: 0.3),
        RecipeIngredient('애호박', '1/4개', fraction: 0.3),
        RecipeIngredient('밥', '1공기'),
      ],
      steps: [
        '팬에 기름을 두르고 대파를 볶아 파기름을 낸다',
        '잘게 썬 양파·애호박을 넣고 2분 볶는다',
        '밥과 계란을 넣고 센 불에서 고슬고슬 볶는다',
        '간장 반 큰술을 팬 가장자리에 둘러 마무리한다',
      ],
    ),
    Recipe(
      name: '두부조림',
      emoji: '🧆',
      ingredients: [
        RecipeIngredient('두부', '한 모', fraction: 1.0),
        RecipeIngredient('양파', '1/2개', fraction: 0.5),
        RecipeIngredient('대파', '1/3대', fraction: 0.3),
      ],
      steps: [
        '두부를 도톰하게 썰어 팬에 노릇하게 굽는다',
        '간장 2큰술+물 4큰술+고춧가루 1큰술 양념을 만든다',
        '두부 위에 양파·양념을 올리고 약불에 5분 조린다',
        '대파를 올려 마무리한다',
      ],
    ),
  ];

  /// 랭킹 가중치: 빨강 소진이 최우선, 그다음 노랑, 그다음 보유 재료 수
  static const _redWeight = 100;
  static const _yellowWeight = 10;

  /// 최소 보유 재료 수 (이보다 적게 겹치면 "파먹기"라 보기 어렵다)
  static const _minOwned = 2;

  @override
  Future<List<RecipeMatch>> recommend(List<FridgeItem> fridge) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final matches = <RecipeMatch>[];
    for (final recipe in _recipes) {
      final owned = <RecipeIngredient, FridgeItem>{};
      final missing = <RecipeIngredient>[];
      for (final ing in recipe.ingredients) {
        final item = fridge.where((i) => i.name == ing.name).firstOrNull;
        if (item != null) {
          owned[ing] = item;
        } else {
          missing.add(ing);
        }
      }
      if (owned.length >= _minOwned) {
        matches.add(RecipeMatch(recipe: recipe, owned: owned, missing: missing));
      }
    }

    int score(RecipeMatch m) {
      final red = m.owned.values.where((i) => i.freshness == Freshness.red).length;
      final yellow = m.owned.values.where((i) => i.freshness == Freshness.yellow).length;
      return red * _redWeight + yellow * _yellowWeight + m.owned.length;
    }

    matches.sort((a, b) => score(b).compareTo(score(a)));
    return matches;
  }
}
