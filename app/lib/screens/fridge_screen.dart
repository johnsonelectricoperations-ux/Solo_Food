import 'package:flutter/material.dart';

import '../models/fridge_item.dart';
import '../services/receipt_parser.dart';
import '../services/recipe_service.dart';
import '../state/fridge_store.dart';
import '../state/profile_store.dart';
import 'receipt_input_screen.dart';
import 'recipe_list_screen.dart';
import 'settings_screen.dart';

/// S3. 홈 = 비주얼 냉장고 (docs/screens.md)
class FridgeScreen extends StatefulWidget {
  const FridgeScreen({
    super.key,
    required this.store,
    required this.parser,
    required this.recipeService,
    required this.profileStore,
  });

  final FridgeStore store;
  final ReceiptParser parser;
  final RecipeService recipeService;
  final ProfileStore profileStore;

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  bool _iconView = true;

  List<FridgeItem> get _items => widget.store.items;

  int get _redCount => _items.where((i) => i.freshness == Freshness.red).length;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  /// B2. 재료 보정 바텀시트 — 아이콘 길게 누르기 (docs/screens.md)
  Future<void> _showAdjustSheet(FridgeItem item) async {
    final store = widget.store;
    final action = await showModalBottomSheet<_AdjustAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${item.emoji} ${item.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              for (final (action, icon, label) in [
                (_AdjustAction.eaten, Icons.check_circle_outline, '다 먹음'),
                (_AdjustAction.halfLeft, Icons.contrast, '반 남음'),
                (_AdjustAction.discarded, Icons.delete_outline, '버림'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    icon: Icon(icon),
                    label: Text(label, style: const TextStyle(fontSize: 15)),
                    onPressed: () => Navigator.of(context).pop(action),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _AdjustAction.eaten:
        final naengpa = store.markEaten(item);
        _toast(naengpa ? '냉파 성공! 🔥 (이번 달 ${store.naengpaCount}회)' : '냉장고에서 비웠어요');
      case _AdjustAction.halfLeft:
        store.markHalfLeft(item);
        _toast('${item.name}을(를) 절반으로 조정했어요');
      case _AdjustAction.discarded:
        store.markDiscarded(item);
        // 죄책감 UX 금지 — 기록만 하고 혼내지 않는다
        _toast('기록했어요. 다음엔 같이 구해봐요!');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 냉장고'),
        actions: [
          _NaengpaBadge(count: widget.store.naengpaCount),
          IconButton(
            tooltip: _iconView ? '리스트로 보기' : '냉장고로 보기',
            icon: Icon(_iconView ? Icons.view_list : Icons.kitchen),
            onPressed: () => setState(() => _iconView = !_iconView),
          ),
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(profileStore: widget.profileStore),
              ),
            ),
          ),
        ],
      ),
      body: _iconView
          ? _FridgeView(items: _items, onItemLongPress: _showAdjustSheet)
          : _ListView(items: _items, onItemLongPress: _showAdjustSheet),
      floatingActionButton: FloatingActionButton(
        tooltip: '재료 채우기',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReceiptInputScreen(store: widget.store, parser: widget.parser),
          ),
        ),
        child: const Icon(Icons.photo_camera),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _redCount > 0 ? Colors.red.shade600 : null,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeListScreen(
                  store: widget.store,
                  recipeService: widget.recipeService,
                ),
              ),
            ),
            child: Text(
              _redCount > 0 ? '🚨 빨간 애들 털어먹기 ($_redCount개)' : '오늘 뭐 해먹지?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

/// 이번 달 냉파 성공 횟수 뱃지 (킬러 기능 5 최소형 — 아직 더미 값)
class _NaengpaBadge extends StatelessWidget {
  const _NaengpaBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text('🔥 $count', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

enum _AdjustAction { eaten, halfLeft, discarded }

/// 냉장고 단면 뷰: 냉장 선반 3칸 + 문짝 포켓 + 냉동 서랍
class _FridgeView extends StatelessWidget {
  const _FridgeView({required this.items, required this.onItemLongPress});

  final List<FridgeItem> items;
  final ValueChanged<FridgeItem> onItemLongPress;

  static const _sections = [
    (FridgeSection.shelf1, '냉장 1칸'),
    (FridgeSection.shelf2, '냉장 2칸'),
    (FridgeSection.shelf3, '채소칸'),
    (FridgeSection.door, '문짝'),
    (FridgeSection.freezer, '냉동'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final (section, label) in _sections)
          _ShelfRow(
            label: label,
            isFreezer: section == FridgeSection.freezer,
            items: items.where((i) => i.section == section).toList(),
            onItemLongPress: onItemLongPress,
          ),
      ],
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({
    required this.label,
    required this.items,
    required this.onItemLongPress,
    this.isFreezer = false,
  });

  final String label;
  final List<FridgeItem> items;
  final ValueChanged<FridgeItem> onItemLongPress;
  final bool isFreezer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isFreezer ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text('비어 있음', style: TextStyle(color: Colors.grey.shade400))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in items)
                  GestureDetector(
                    onLongPress: () => onItemLongPress(item),
                    child: _ItemTile(item: item),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final FridgeItem item;

  Color get _borderColor => switch (item.freshness) {
        Freshness.red => Colors.red,
        Freshness.yellow => Colors.amber,
        Freshness.green => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor, width: 2.5),
              ),
              child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
            ),
            if (item.count > 1)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '×${item.count}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 48,
          child: LinearProgressIndicator(
            value: item.amount,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
            backgroundColor: Colors.grey.shade300,
            color: _borderColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(item.name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// 리스트 뷰: 검색·정확한 관리용 (아이콘 뷰의 검색성 보완)
class _ListView extends StatelessWidget {
  const _ListView({required this.items, required this.onItemLongPress});

  final List<FridgeItem> items;
  final ValueChanged<FridgeItem> onItemLongPress;

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(items)..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = sorted[index];
        final color = switch (item.freshness) {
          Freshness.red => Colors.red,
          Freshness.yellow => Colors.amber,
          Freshness.green => Colors.green,
        };
        return ListTile(
          onLongPress: () => onItemLongPress(item),
          leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(item.name),
          subtitle: Text('남은 양 ${(item.amount * 100).round()}%'
              '${item.count > 1 ? ' · ${item.count}개' : ''}'),
          trailing: Chip(
            label: Text(
              item.daysLeft <= 0 ? '오늘까지!' : 'D-${item.daysLeft}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            side: BorderSide(color: color),
          ),
        );
      },
    );
  }
}
