import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../state/fridge_store.dart';

/// S7. 레시피 상세 + B1. 차감 확인 바텀시트 (docs/screens.md)
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.store, required this.match});

  final FridgeStore store;
  final RecipeMatch match;

  Future<void> _openYoutube() async {
    final query = Uri.encodeComponent('자취생 ${match.recipe.name}');
    await launchUrl(
      Uri.parse('https://www.youtube.com/results?search_query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _onCooked(BuildContext context) async {
    final deductions = await showModalBottomSheet<List<Deduction>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeductionSheet(match: match),
    );
    if (deductions == null || !context.mounted) return;

    final naengpa = store.applyDeductions(deductions);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: naengpa ? Colors.red.shade600 : null,
        content: Text(
          naengpa ? '냉파 성공! 🔥 임박한 재료를 구했어요 (이번 달 ${store.naengpaCount}회)' : '냉장고에서 차감했어요',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = match.recipe;
    return Scaffold(
      appBar: AppBar(title: Text('${recipe.emoji} ${recipe.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (match.urgentUsed.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '이 요리로 임박한 재료 ${match.urgentUsed.length}개가 살아납니다: '
                '${match.urgentUsed.map((i) => i.name).join(', ')}',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          const Text('재료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          for (final entry in match.owned.entries)
            _IngredientRow(
              ingredient: entry.key,
              inFridge: true,
              subtitle: '냉장고에 있음 · 남은 양 ${(entry.value.amount * 100).round()}%'
                  '${entry.value.isCountable ? ' · ${entry.value.count}개' : ''}',
            ),
          for (final ing in match.missing)
            _IngredientRow(ingredient: ing, inFridge: false, subtitle: '없음 — 사거나 빼고 조리'),
          const SizedBox(height: 16),
          const Text('만드는 법', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          // 요리하며 폰을 보므로 단계는 큰 글씨로
          for (var i = 0; i < recipe.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('${i + 1}. ${recipe.steps[i]}', style: const TextStyle(fontSize: 17)),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openYoutube,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('유튜브에서 영상 보기'),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () => _onCooked(context),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('🍳 해먹었어요', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, required this.inFridge, required this.subtitle});

  final RecipeIngredient ingredient;
  final bool inFridge;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        inFridge ? Icons.check_circle : Icons.remove_circle_outline,
        color: inFridge ? Colors.green : Colors.grey,
      ),
      title: Text('${ingredient.name} ${ingredient.amountLabel}'),
      subtitle: Text(subtitle, style: TextStyle(color: inFridge ? null : Colors.grey)),
    );
  }
}

/// B1. 차감 확인 바텀시트 — 무엇이 얼마나 차감되는지 투명하게 보여주고 확정.
/// (몰래 차감하면 냉장고가 어긋났을 때 유저가 원인을 모른다 — docs/screens.md)
class _DeductionSheet extends StatefulWidget {
  const _DeductionSheet({required this.match});

  final RecipeMatch match;

  @override
  State<_DeductionSheet> createState() => _DeductionSheetState();
}

enum _Use { none, half, all }

class _DeductionSheetState extends State<_DeductionSheet> {
  late final Map<RecipeIngredient, _Use> _choices = {
    // 레시피가 보통 쓰는 양을 기본값으로 제안
    for (final ing in widget.match.owned.keys)
      ing: ing.fraction <= 0.5 ? _Use.half : _Use.all,
  };

  double _fraction(_Use use) => switch (use) {
        _Use.none => 0.0,
        _Use.half => 0.5,
        _Use.all => 1.0,
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('얼마나 썼는지 확인해 주세요',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 4),
            Text('여기서 확정한 만큼만 냉장고에서 빠져요',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            for (final entry in widget.match.owned.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${entry.value.emoji} ${entry.key.name}',
                          style: const TextStyle(fontSize: 15)),
                    ),
                    SegmentedButton<_Use>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: _Use.none, label: Text('안 씀')),
                        ButtonSegment(value: _Use.half, label: Text('반')),
                        ButtonSegment(value: _Use.all, label: Text('다 씀')),
                      ],
                      selected: {_choices[entry.key]!},
                      onSelectionChanged: (s) => setState(() => _choices[entry.key] = s.first),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => Navigator.of(context).pop([
                for (final entry in widget.match.owned.entries)
                  Deduction(entry.value, _fraction(_choices[entry.key]!)),
              ]),
              child: const Text('확정하고 차감하기', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
