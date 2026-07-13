import 'package:flutter/foundation.dart';

import '../models/fridge_item.dart';

/// 앱 전체가 공유하는 냉장고 상태.
/// 지금은 메모리에만 저장 — Supabase 연결 시 이 클래스 내부만 교체하면 된다.
class FridgeStore extends ChangeNotifier {
  FridgeStore({List<FridgeItem>? initial}) : _items = List.of(initial ?? dummyFridgeItems);

  final List<FridgeItem> _items;

  List<FridgeItem> get items => List.unmodifiable(_items);

  void addAll(List<FridgeItem> newItems) {
    _items.addAll(newItems);
    notifyListeners();
  }
}
