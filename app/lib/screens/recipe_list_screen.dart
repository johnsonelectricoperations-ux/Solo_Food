import 'package:flutter/material.dart';

import '../models/fridge_item.dart';
import '../services/recipe_service.dart';
import '../state/fridge_store.dart';
import 'recipe_detail_screen.dart';

/// S6. 파먹기 레시피 목록 (docs/screens.md)
/// 빨강 재료 소진 기여도 순으로 정렬된 추천을 보여준다.
class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key, required this.store, required this.recipeService});

  final FridgeStore store;
  final RecipeService recipeService;

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late Future<List<RecipeMatch>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.recipeService.recommend(widget.store.items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 파먹기 레시피')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('냉장고를 살펴보고 있어요…'),
                ],
              ),
            );
          }
          final matches = snapshot.data ?? const <RecipeMatch>[];
          if (matches.isEmpty) {
            return const Center(child: Text('냉장고 재료로 만들 수 있는 요리를 찾지 못했어요.\n재료를 먼저 채워볼까요?', textAlign: TextAlign.center));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: matches.length,
            itemBuilder: (context, index) => _RecipeCard(
              match: matches[index],
              onTap: () async {
                final navigator = Navigator.of(context);
                final consumed = await navigator.push<bool>(
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(store: widget.store, match: matches[index]),
                  ),
                );
                if (consumed == true && mounted) {
                  navigator.pop(); // 차감 완료 → 냉장고(S3)로
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.match, required this.onTap});

  final RecipeMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgent = match.urgentUsed;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(match.recipe.emoji, style: const TextStyle(fontSize: 32)),
        title: Text(match.recipe.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('내 냉장고 재료 ${match.owned.length}개로 가능'),
            if (urgent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: [
                    for (final item in urgent)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: item.freshness == Freshness.red
                            ? Colors.red.shade50
                            : Colors.amber.shade50,
                        side: BorderSide(
                          color: item.freshness == Freshness.red ? Colors.red : Colors.amber,
                        ),
                        label: Text('${item.name} 구출!', style: const TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
