import 'package:flutter/foundation.dart';

import '../models/fridge_item.dart';

/// 차감 1건: 어떤 품목을 얼마나(비율) 썼는가
class Deduction {
  const Deduction(this.item, this.fraction);

  final FridgeItem item;

  /// 0.0(안 씀) ~ 1.0(다 씀)
  final double fraction;
}

/// 앱 전체가 공유하는 냉장고 상태.
/// 지금은 메모리에만 저장 — Supabase 연결 시 이 클래스 내부만 교체하면 된다.
class FridgeStore extends ChangeNotifier {
  FridgeStore({List<FridgeItem>? initial}) : _items = List.of(initial ?? dummyFridgeItems);

  final List<FridgeItem> _items;

  /// 이번 달 냉파 성공 횟수 (킬러 기능 5 최소형 — 아직 메모리 카운트)
  int naengpaCount = 0;

  List<FridgeItem> get items => List.unmodifiable(_items);

  void addAll(List<FridgeItem> newItems) {
    _items.addAll(newItems);
    notifyListeners();
  }

  /// 차감을 적용하고, 임박(빨강/노랑) 재료를 소진했으면 냉파 성공으로 기록한다.
  /// 반환값: 냉파 성공 여부.
  bool applyDeductions(List<Deduction> deductions) {
    var naengpa = false;

    for (final d in deductions) {
      if (d.fraction <= 0) continue;

      final index = _items.indexOf(d.item);
      if (index < 0) continue; // 이미 사라진 품목이면 무시

      final item = _items[index];
      if (item.freshness != Freshness.green) naengpa = true;

      final FridgeItem updated;
      if (item.isCountable) {
        updated = item.copyWith(count: item.count - (item.count * d.fraction).ceil());
      } else {
        updated = item.copyWith(amount: item.amount - d.fraction);
      }

      final depleted = item.isCountable ? updated.count <= 0 : updated.amount <= 0;
      if (depleted) {
        _items.removeAt(index);
      } else {
        _items[index] = updated;
      }
    }

    if (naengpa) naengpaCount++;
    notifyListeners();
    return naengpa;
  }
}
