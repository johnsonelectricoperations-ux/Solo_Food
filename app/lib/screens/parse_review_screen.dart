import 'package:flutter/material.dart';

import '../services/receipt_parser.dart';
import '../state/fridge_store.dart';

/// S5. 파싱 결과 확인·수정 — 신뢰의 관문 (docs/screens.md)
/// 틀린 인식이 냉장고에 들어가면 신뢰 루프가 깨지므로, 유저가 확정해야만 등록된다.
class ParseReviewScreen extends StatefulWidget {
  const ParseReviewScreen({super.key, required this.store, required this.result});

  final FridgeStore store;
  final ParseResult result;

  @override
  State<ParseReviewScreen> createState() => _ParseReviewScreenState();
}

class _ParseReviewScreenState extends State<ParseReviewScreen> {
  late final List<ParsedItem> _items = List.of(widget.result.items);

  void _confirm() {
    widget.store.addAll([for (final i in _items) i.toFridgeItem()]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('재료 ${_items.length}개를 냉장고에 담았어요! 🧊')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('인식 결과 확인 (${_items.length}개)')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('잘못 읽은 게 있으면 여기서 고쳐주세요. 확인을 눌러야 냉장고에 들어가요.'),
          ),
          for (var i = 0; i < _items.length; i++)
            _ItemRow(
              key: ObjectKey(_items[i]),
              item: _items[i],
              onChanged: () => setState(() {}),
              onDelete: () => setState(() => _items.removeAt(i)),
            ),
          if (widget.result.excluded.isNotEmpty)
            ExpansionTile(
              title: Text('식재료가 아니라서 제외한 항목 (${widget.result.excluded.length})',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              children: [
                for (final line in widget.result.excluded)
                  ListTile(dense: true, title: Text(line)),
              ],
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _items.isEmpty ? null : _confirm,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('냉장고에 담기', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({super.key, required this.item, required this.onChanged, required this.onDelete});

  final ParsedItem item;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('보관 추정 D-${item.daysLeft}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            _Stepper(
              value: item.count,
              onChanged: (v) {
                item.count = v;
                onChanged();
              },
            ),
            IconButton(
              tooltip: '이 항목 빼기',
              icon: const Icon(Icons.close),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text('$value', style: const TextStyle(fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}
