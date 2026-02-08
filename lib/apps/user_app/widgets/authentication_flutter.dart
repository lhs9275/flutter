import 'package:flutter/material.dart';
import 'icons/loading_spinner_flutter.dart';

class AuthenticationFlutter extends StatelessWidget {
  const AuthenticationFlutter({
    super.key,
    required this.phone,
    required this.onBack,
    required this.onVerified,
    required this.onRegister,
    this.isLoading = false,
  });

  final String phone;
  final VoidCallback onBack;
  final VoidCallback onVerified;
  final VoidCallback onRegister;
  final bool isLoading;

  String _maskPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 10) return phone;
    return '${cleaned.substring(0, 3)}-****-${cleaned.substring(cleaned.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('번호 다시 입력'),
        ),
        const SizedBox(height: 8),
        const Text('인증번호 입력', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${_maskPhone(phone)}(으)로 전송된 6자리 인증번호를 입력해주세요.', style: const TextStyle(color: Color(0xFF475569))),
        const SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: '인증번호 6자리',
            filled: true,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onVerified,
            child: isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingSpinnerFlutter(size: 18),
                      SizedBox(width: 8),
                      Text('인증 중...'),
                    ],
                  )
                : const Text('인증하고 계속하기'),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onRegister,
          child: const Text('신규 가입하기'),
        ),
      ],
    );
  }
}
