import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fridge_item.dart';
import '../models/user_profile.dart';
import 'app_storage.dart';

/// Supabase 클라우드 저장 (로그인 유저 전용).
/// RLS가 걸려 있어 각 유저는 자기 행만 읽고 쓸 수 있다 (supabase/schema.sql).
class SupabaseStorage implements AppStorage {
  SupabaseStorage(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<FridgeData?> loadFridge() async {
    final profile =
        await _client.from('profiles').select().eq('user_id', _uid).maybeSingle();
    final rows = await _client.from('fridge_items').select().eq('user_id', _uid);

    if (profile == null && rows.isEmpty) return null;
    return (
      items: [
        for (final r in rows)
          FridgeItem(
            name: r['name'] as String,
            emoji: r['emoji'] as String,
            section: FridgeSection.values.byName(r['section'] as String),
            amount: (r['amount'] as num).toDouble(),
            count: r['count'] as int,
            expiresOn: DateTime.parse(r['expires_on'] as String),
          ),
      ],
      naengpaCount: (profile?['naengpa_count'] as int?) ?? 0,
      discardCount: (profile?['discard_count'] as int?) ?? 0,
    );
  }

  @override
  Future<void> saveFridge(List<FridgeItem> items,
      {required int naengpaCount, required int discardCount}) async {
    // MVP 규모(품목 수십 개)에서는 전체 교체가 가장 단순하고 안전하다
    await _client.from('fridge_items').delete().eq('user_id', _uid);
    if (items.isNotEmpty) {
      await _client.from('fridge_items').insert([
        for (final i in items)
          {
            'user_id': _uid,
            'name': i.name,
            'emoji': i.emoji,
            'section': i.section.name,
            'amount': i.amount,
            'count': i.count,
            'expires_on': i.expiresOn.toIso8601String().substring(0, 10),
          },
      ]);
    }
    await _client.from('profiles').upsert({
      'user_id': _uid,
      'naengpa_count': naengpaCount,
      'discard_count': discardCount,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  @override
  Future<UserProfile?> loadProfile() async {
    final row =
        await _client.from('profiles').select().eq('user_id', _uid).maybeSingle();
    if (row == null || row['diet_type'] == null) return null;
    // 온보딩을 완료한 적 없는 카운터-전용 행이면 allergens가 비어 있어도 프로필로 취급
    if (row['onboarding_done'] != true) return null;
    return UserProfile(
      allergens: {...(row['allergens'] as List).cast<String>()},
      dietType: DietType.values.byName(row['diet_type'] as String),
    );
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _client.from('profiles').upsert({
      'user_id': _uid,
      'allergens': profile.allergens.toList(),
      'diet_type': profile.dietType.name,
      'onboarding_done': true,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
