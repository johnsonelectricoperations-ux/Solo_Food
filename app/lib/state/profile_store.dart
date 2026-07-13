import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

/// 취향 프로필 상태.
/// 지금은 메모리에만 저장 — Supabase 연결 시 이 클래스 내부만 교체하면 된다.
class ProfileStore extends ChangeNotifier {
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  bool get onboardingDone => _profile != null;

  void save(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }
}
