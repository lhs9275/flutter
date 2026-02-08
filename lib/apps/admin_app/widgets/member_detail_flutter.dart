import 'package:flutter/material.dart';

class MemberDetailFlutter extends StatelessWidget {
  const MemberDetailFlutter({
    super.key,
    required this.member,
    required this.onBack,
  });

  final Map<String, String> member;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF374151)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('휴대폰: ${member['phone'] ?? '-'}'),
              Text('상태: ${member['status'] ?? '-'}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: onBack, child: const Text('목록으로')),
        ),
      ],
    );
  }
}
