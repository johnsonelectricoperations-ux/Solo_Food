import 'package:flutter/material.dart';

import '../models/fridge_item.dart';

/// S3. 홈 = 비주얼 냉장고 (docs/screens.md)
/// 1단계 골격: 더미 데이터로 냉장고 단면 + 신호등 + 아이콘/리스트 토글까지만.
class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  bool _iconView = true;
  final List<FridgeItem> _items = List.of(dummyFridgeItems);

  int get _redCount => _items.where((i) => i.freshness == Freshness.red).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 냉장고'),
        actions: [
          const _NaengpaBadge(count: 7),
          IconButton(
            tooltip: _iconView ? '리스트로 보기' : '냉장고로 보기',
            icon: Icon(_iconView ? Icons.view_list : Icons.kitchen),
            onPressed: () => setState(() => _iconView = !_iconView),
          ),
        ],
      ),
      body: _iconView ? _FridgeView(items: _items) : _ListView(items: _items),
      floatingActionButton: FloatingActionButton(
        tooltip: '영수증 찍기',
        onPressed: () => _todo(context, '영수증 촬영(S4)은 다음 단계에서 만들어요'),
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
            onPressed: () => _todo(context, '파먹기 레시피(S6)는 다음 단계에서 만들어요'),
            child: Text(
              _redCount > 0 ? '🚨 빨간 애들 털어먹기 ($_redCount개)' : '오늘 뭐 해먹지?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _todo(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

/// 냉장고 단면 뷰: 냉장 선반 3칸 + 문짝 포켓 + 냉동 서랍
class _FridgeView extends StatelessWidget {
  const _FridgeView({required this.items});

  final List<FridgeItem> items;

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
          ),
      ],
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({required this.label, required this.items, this.isFreezer = false});

  final String label;
  final List<FridgeItem> items;
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
              children: [for (final item in items) _ItemTile(item: item)],
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
  const _ListView({required this.items});

  final List<FridgeItem> items;

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
