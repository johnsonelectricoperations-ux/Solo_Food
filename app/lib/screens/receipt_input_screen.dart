import 'package:flutter/material.dart';

import '../services/receipt_parser.dart';
import '../state/fridge_store.dart';
import 'parse_review_screen.dart';

/// S4. 영수증 촬영 / 구매내역 붙여넣기 (docs/screens.md)
class ReceiptInputScreen extends StatefulWidget {
  const ReceiptInputScreen({super.key, required this.store, required this.parser});

  final FridgeStore store;
  final ReceiptParser parser;

  @override
  State<ReceiptInputScreen> createState() => _ReceiptInputScreenState();
}

class _ReceiptInputScreenState extends State<ReceiptInputScreen> {
  final _textController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<ParseResult> Function() parse) async {
    setState(() => _loading = true);
    try {
      final result = await parse();
      if (!mounted) return;
      if (result.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('식재료를 찾지 못했어요. 내용을 확인하고 다시 시도해 주세요.')),
        );
        return;
      }
      final added = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ParseReviewScreen(store: widget.store, result: result),
        ),
      );
      if (added == true && mounted) {
        Navigator.of(context).pop(); // 냉장고(S3)로 복귀
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('재료 채우기'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.photo_camera), text: '영수증 찍기'),
            Tab(icon: Icon(Icons.paste), text: '주문내역 붙여넣기'),
          ]),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _PhotoTab(onCapture: () => _run(widget.parser.parsePhoto)),
                _PasteTab(
                  controller: _textController,
                  onSubmit: () => _run(() => widget.parser.parseText(_textController.text)),
                ),
              ],
            ),
            if (_loading)
              Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('영수증을 읽고 있어요…',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTab extends StatelessWidget {
  const _PhotoTab({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('마트 영수증을 찍으면\n재료가 자동으로 등록돼요', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.photo_camera),
            label: const Text('영수증 찍기 (개발용 모의 데이터)'),
          ),
        ],
      ),
    );
  }
}

class _PasteTab extends StatelessWidget {
  const _PasteTab({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('쿠팡·컬리·이마트몰 주문내역을 복사해서 붙여넣어 주세요'),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: '예)\n두부 300g 1개\n계란 10구\n애호박 1개',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('재료 인식하기'),
          ),
        ],
      ),
    );
  }
}
