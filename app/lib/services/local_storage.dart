import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fridge_item.dart';
import '../models/user_profile.dart';

/// 기기 로컬 저장 (Supabase 연동 전까지의 영속화 다리).
/// 저장 대상: 냉장고 품목, 냉파/버림 카운트, 취향 프로필.
class LocalStorage {
  LocalStorage(this._prefs);

  static Future<LocalStorage> open() async =>
      LocalStorage(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _fridgeKey = 'fridge.v1';
  static const _profileKey = 'profile.v1';

  Future<void> saveFridge(List<FridgeItem> items, {required int naengpaCount, required int discardCount}) async {
    await _prefs.setString(
      _fridgeKey,
      jsonEncode({
        'items': [for (final i in items) i.toJson()],
        'naengpaCount': naengpaCount,
        'discardCount': discardCount,
      }),
    );
  }

  ({List<FridgeItem> items, int naengpaCount, int discardCount})? loadFridge() {
    final raw = _prefs.getString(_fridgeKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (
      items: [
        for (final j in json['items'] as List) FridgeItem.fromJson(j as Map<String, dynamic>),
      ],
      naengpaCount: json['naengpaCount'] as int,
      discardCount: json['discardCount'] as int,
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(
      _profileKey,
      jsonEncode({
        'allergens': profile.allergens.toList(),
        'dietType': profile.dietType.name,
      }),
    );
  }

  UserProfile? loadProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return UserProfile(
      allergens: {...(json['allergens'] as List).cast<String>()},
      dietType: DietType.values.byName(json['dietType'] as String),
    );
  }
}
