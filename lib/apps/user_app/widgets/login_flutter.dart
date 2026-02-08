import 'package:flutter/material.dart';
import 'icons/loading_spinner_flutter.dart';

class LoginFlutter extends StatelessWidget {
  const LoginFlutter({
    super.key,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onContinue,
    this.isLoading = false,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onContinue;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('로그인 / 회원가입', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('비밀번호 없이 휴대폰 번호로 간편하게 시작하세요.', style: TextStyle(color: Color(0xFF475569))),
        const SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: '휴대폰 번호',
            hintText: "'-' 없이 입력",
            filled: true,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: rememberMe,
          onChanged: onRememberChanged,
          title: const Text('로그인 상태 유지'),
          subtitle: const Text('브라우저에 로그인 정보가 저장됩니다.', style: TextStyle(color: Color(0xFF64748B))),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onContinue,
            child: isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingSpinnerFlutter(size: 18),
                      SizedBox(width: 8),
                      Text('로그인 중...'),
                    ],
                  )
                : const Text('로그인 / 가입하기'),
          ),
        ),
      ],
    );
  }
}
