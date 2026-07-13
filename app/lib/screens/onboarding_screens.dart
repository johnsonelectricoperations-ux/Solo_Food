import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../state/profile_store.dart';

/// S1. 온보딩① 알레르기·금기 + S2. 온보딩② 식단 유형 (docs/screens.md)
/// 합쳐서 30초 안에 끝나야 한다 — 화면당 질문 1개.
///
/// [initial]이 있으면 설정(S8)에서 진입한 수정 모드: 저장 후 뒤로 돌아간다.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.profileStore, this.initial});

  final ProfileStore profileStore;
  final UserProfile? initial;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final Set<String> _allergens = {...?widget.initial?.allergens};

  bool get _isEdit => widget.initial != null;

  void _goDietStep() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DietTypeScreen(
          initial: widget.initial?.dietType ?? DietType.normal,
          onDone: (dietType) {
            widget.profileStore.save(
              UserProfile(allergens: _allergens, dietType: dietType),
            );
            if (_isEdit) {
              // 수정 모드: 설정 화면까지 되돌아간다
              Navigator.of(context)
                ..pop()
                ..pop();
            } else {
              // 첫 온보딩: 식단 화면을 걷어내면 main의 라우팅이
              // 프로필 저장을 감지해 홈(S3)으로 전환돼 있다
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '알레르기·기피 수정' : '시작하기 (1/2)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('알레르기나 절대 피해야 할 재료가 있나요?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('선택한 재료는 어떤 레시피에도 등장하지 않아요',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _commonAllergens)
                  FilterChip(
                    label: Text(name),
                    selected: _allergens.contains(name),
                    onSelected: (on) => setState(
                      () => on ? _allergens.add(name) : _allergens.remove(name),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('직접 추가'),
                  onPressed: _addCustom,
                ),
              ],
            ),
            const Spacer(),
            // 대부분의 유저는 여기서 3초 만에 지나간다 — "없음"을 크게
            if (_allergens.isEmpty)
              OutlinedButton(
                onPressed: _goDietStep,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text('없어요, 다음으로', style: TextStyle(fontSize: 16)),
              )
            else
              FilledButton(
                onPressed: _goDietStep,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text('${_allergens.length}개 선택하고 다음으로',
                    style: const TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustom() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('피해야 할 재료 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 오이'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('추가'),
          ),
        ],
      ),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) setState(() => _allergens.add(trimmed));
  }
}

/// 법정 알레르기 표시 대상 중심의 대표 항목
const _commonAllergens = ['계란', '우유', '땅콩', '대두', '밀', '새우', '게', '고등어', '돼지고기', '복숭아'];

class _DietTypeScreen extends StatelessWidget {
  const _DietTypeScreen({required this.initial, required this.onDone});

  final DietType initial;
  final ValueChanged<DietType> onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시작하기 (2/2)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('어떤 식단을 원하세요?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('하나만 고르면 바로 시작돼요 (나중에 설정에서 변경 가능)',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            for (final type in DietType.values)
              Card(
                child: ListTile(
                  title: Text(type.label,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(type.description),
                  trailing: type == initial ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () => onDone(type),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
