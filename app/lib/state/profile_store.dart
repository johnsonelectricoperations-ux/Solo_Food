import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/app_storage.dart';

/// 취향 프로필 상태.
/// 초기 로드는 BootstrapApp이 수행해 [initial]로 넘긴다.
class ProfileStore extends ChangeNotifier {
  ProfileStore({UserProfile? initial, AppStorage? storage})
      // ignore: prefer_initializing_formals
      : _storage = storage,
        _profile = initial;

  final AppStorage? _storage;
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  bool get onboardingDone => _profile != null;

  void save(UserProfile profile) {
    _profile = profile;
    _storage?.saveProfile(profile);
    notifyListeners();
  }
}
