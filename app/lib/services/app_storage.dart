import '../models/fridge_item.dart';
import '../models/user_profile.dart';

typedef FridgeData = ({List<FridgeItem> items, int naengpaCount, int discardCount});

/// 영속화 계약. 구현체: LocalStorage(기기), SupabaseStorage(클라우드).
abstract class AppStorage {
  Future<FridgeData?> loadFridge();

  Future<void> saveFridge(
    List<FridgeItem> items, {
    required int naengpaCount,
    required int discardCount,
  });

  Future<UserProfile?> loadProfile();

  Future<void> saveProfile(UserProfile profile);
}
