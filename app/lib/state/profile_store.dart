import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/local_storage.dart';

/// 취향 프로필 상태.
/// 변경 시마다 기기 로컬(LocalStorage)에 저장한다. Supabase 연동 시 저장부만 교체.
class ProfileStore extends ChangeNotifier {
  ProfileStore({LocalStorage? storage}) : _storage = storage {
    _profile = storage?.loadProfile();
  }

  final LocalStorage? _storage;
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  bool get onboardingDone => _profile != null;

  void save(UserProfile profile) {
    _profile = profile;
    _storage?.saveProfile(profile);
    notifyListeners();
  }
}
