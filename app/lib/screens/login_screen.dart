import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// S0. 로그인 (docs/screens.md)
/// 이메일로 6자리 인증코드를 받아 입력하는 방식 — 비밀번호도 딥링크 설정도 필요 없다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _toast('이메일 주소를 확인해 주세요');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
      setState(() => _codeSent = true);
      _toast('인증코드를 이메일로 보냈어요. 메일함을 확인해 주세요!');
    } on AuthException catch (e) {
      _toast('코드 전송 실패: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email,
        email: _emailController.text.trim(),
        token: _codeController.text.trim(),
      );
      // 성공하면 main의 인증 게이트가 자동으로 홈/온보딩으로 전환한다
    } on AuthException catch (e) {
      _toast('인증 실패: ${e.message} — 코드를 다시 확인해 주세요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('🧊', textAlign: TextAlign.center, style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text('Zero-Waste Kitchen',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('버리는 재료 없는 자취 냉장고',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_codeSent) ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '인증코드 6자리',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _verify,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(_busy ? '확인 중…' : '시작하기'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _codeSent = false),
                  child: const Text('이메일 다시 입력'),
                ),
              ] else
                FilledButton(
                  onPressed: _busy ? null : _sendCode,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(_busy ? '보내는 중…' : '이메일로 인증코드 받기'),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
