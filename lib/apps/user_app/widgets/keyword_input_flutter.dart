import 'package:flutter/material.dart';

class RegistrationFormFlutter extends StatelessWidget {
  const RegistrationFormFlutter({
    super.key,
    required this.onSubmit,
  });

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('회원가입', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '이름', filled: true)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '주민등록번호', filled: true)),
        const SizedBox(height: 12),
        DropdownButtonFormField(
          items: const [
            DropdownMenuItem(value: 'male', child: Text('남성')),
            DropdownMenuItem(value: 'female', child: Text('여성')),
          ],
          onChanged: (_) {},
          decoration: const InputDecoration(labelText: '성별', filled: true),
        ),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '국적', filled: true)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '선호 지역', filled: true)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '은행', filled: true)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '계좌번호', filled: true)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '예금주', filled: true)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: const Text('가입 완료'),
          ),
        ),
      ],
    );
  }
}
