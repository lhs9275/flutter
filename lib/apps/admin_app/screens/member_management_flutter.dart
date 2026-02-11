import 'package:flutter/material.dart';
import '../widgets/member_detail_flutter.dart';

class MemberManagementFlutter extends StatelessWidget {
  const MemberManagementFlutter({
    super.key,
    required this.members,
    required this.selectedMember,
    required this.onSelectMember,
    required this.onBack,
    required this.onAdjustNoShow,
    required this.onResetNoShow,
  });

  final List<Map<String, dynamic>> members;
  final Map<String, dynamic>? selectedMember;
  final ValueChanged<Map<String, dynamic>> onSelectMember;
  final VoidCallback onBack;
  final void Function(String phone, int delta) onAdjustNoShow;
  final void Function(String phone) onResetNoShow;

  @override
  Widget build(BuildContext context) {
    if (selectedMember != null) {
      final phone = selectedMember!['phone'] as String? ?? '';
      return MemberDetailFlutter(
        member: selectedMember!,
        onBack: onBack,
        onAdjustNoShow: (delta) => onAdjustNoShow(phone, delta),
        onResetNoShow: () => onResetNoShow(phone),
      );
    }

    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = members[index];
        final noShowCount = member['noShowCount'] as int? ?? 0;
        return ListTile(
          tileColor: const Color(0xFFFFFFFF),
          title: Text(member['name'] ?? ''),
          subtitle: Text(member['phone'] ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (noShowCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    '노쇼 ${noShowCount}회',
                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              if (noShowCount > 0) const SizedBox(width: 8),
              Text(member['status'] ?? '', style: const TextStyle(color: Color(0xFF475569))),
            ],
          ),
          onTap: () => onSelectMember(member),
        );
      },
    );
  }
}
