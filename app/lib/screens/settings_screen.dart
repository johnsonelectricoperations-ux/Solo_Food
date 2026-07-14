import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/profile_store.dart';
import 'onboarding_screens.dart';

/// S8. 설정 (docs/screens.md) — 프로필 수정 외에는 넣지 않는다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.profileStore});

  final ProfileStore profileStore;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.profileStore.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.profileStore.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final profile = widget.profileStore.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.no_food),
            title: const Text('알레르기·피해야 할 재료'),
            subtitle: Text(
              profile == null || profile.allergens.isEmpty ? '없음' : profile.allergens.join(', '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OnboardingFlow(
                  profileStore: widget.profileStore,
                  initial: profile,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('식단 유형'),
            subtitle: Text(profile?.dietType.label ?? '일반'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            subtitle: const Text('스토어 등록 전에 함께 준비해요'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('스토어 제출 단계에서 문서를 만들어 연결할 예정이에요')),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            subtitle: Text(
              Supabase.instance.client.auth.currentUser?.email ?? '',
            ),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              // 인증 게이트(main)가 로그인 화면으로 전환한다
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}
