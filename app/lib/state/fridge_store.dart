import 'package:flutter/foundation.dart';

import '../models/fridge_item.dart';
import '../services/local_storage.dart';

/// 차감 1건: 어떤 품목을 얼마나(비율) 썼는가
class Deduction {
  const Deduction(this.item, this.fraction);

  final FridgeItem item;

  /// 0.0(안 씀) ~ 1.0(다 씀)
  final double fraction;
}

/// 앱 전체가 공유하는 냉장고 상태.
/// 변경 시마다 기기 로컬(LocalStorage)에 저장한다. Supabase 연동 시 저장부만 교체.
class FridgeStore extends ChangeNotifier {
  FridgeStore({List<FridgeItem>? initial, LocalStorage? storage}) : _storage = storage {
    final saved = storage?.loadFridge();
    if (initial != null) {
      _items = List.of(initial);
    } else if (saved != null) {
      _items = List.of(saved.items);
      naengpaCount = saved.naengpaCount;
      discardCount = saved.discardCount;
    } else {
      _items = dummyFridgeItems(); // 첫 실행 데모용 — 실연동 시 빈 냉장고로 교체 예정
    }
  }

  final LocalStorage? _storage;
  late List<FridgeItem> _items;

  /// 이번 달 냉파 성공 횟수 (킬러 기능 5 최소형)
  int naengpaCount = 0;

  /// 버린 재료 횟수 — 냉파 리포트의 "얼마 버렸다" 데이터 (2차에서 리포트로 노출)
  int discardCount = 0;

  List<FridgeItem> get items => List.unmodifiable(_items);

  void _commit() {
    _storage?.saveFridge(_items, naengpaCount: naengpaCount, discardCount: discardCount);
    notifyListeners();
  }

  void addAll(List<FridgeItem> newItems) {
    _items.addAll(newItems);
    _commit();
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
    _commit();
    return naengpa;
  }

  /// B2 보정: 다 먹음. 임박 재료였다면 냉파 성공으로 기록한다.
  /// 반환값: 냉파 성공 여부.
  bool markEaten(FridgeItem item) {
    if (!_items.remove(item)) return false;
    final naengpa = item.freshness != Freshness.green;
    if (naengpa) naengpaCount++;
    _commit();
    return naengpa;
  }

  /// B2 보정: 반 남음 (현재 양의 절반으로)
  void markHalfLeft(FridgeItem item) {
    final index = _items.indexOf(item);
    if (index < 0) return;
    _items[index] = item.isCountable
        ? item.copyWith(count: (item.count / 2).ceil())
        : item.copyWith(amount: item.amount / 2);
    _commit();
  }

  /// B2 보정: 버림. 죄책감 UX 금지 — 기록만 하고 혼내지 않는다.
  void markDiscarded(FridgeItem item) {
    if (!_items.remove(item)) return;
    discardCount++;
    _commit();
  }
}
