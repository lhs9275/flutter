import 'package:flutter/material.dart';

class MemberDetailFlutter extends StatelessWidget {
  const MemberDetailFlutter({
    super.key,
    required this.member,
    required this.onBack,
    required this.onAdjustNoShow,
    required this.onResetNoShow,
  });

  final Map<String, dynamic> member;
  final VoidCallback onBack;
  final ValueChanged<int> onAdjustNoShow;
  final VoidCallback onResetNoShow;

  @override
  Widget build(BuildContext context) {
    final noShowCount = member['noShowCount'] as int? ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('휴대폰: ${member['phone'] ?? '-'}'),
              Text('상태: ${member['status'] ?? '-'}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.report_problem, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Text(
                    '노쇼 ${noShowCount}회',
                    style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => onAdjustNoShow(-1),
                    child: const Text('-1'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => onAdjustNoShow(1),
                    child: const Text('+1'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onResetNoShow,
                    child: const Text('초기화'),
                  ),
                ],
              ),
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
