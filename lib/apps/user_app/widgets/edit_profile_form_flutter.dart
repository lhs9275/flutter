import 'package:flutter/material.dart';

class EditProfileFormFlutter extends StatelessWidget {
  const EditProfileFormFlutter({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('프로필 수정', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '이름', filled: true)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '선호 지역', filled: true)),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: '은행', filled: true)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onSave,
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
