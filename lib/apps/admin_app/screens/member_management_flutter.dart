import 'package:flutter/material.dart';
import '../widgets/member_detail_flutter.dart';

class MemberManagementFlutter extends StatelessWidget {
  const MemberManagementFlutter({
    super.key,
    required this.members,
    required this.selectedMember,
    required this.onSelectMember,
    required this.onBack,
  });

  final List<Map<String, String>> members;
  final Map<String, String>? selectedMember;
  final ValueChanged<Map<String, String>> onSelectMember;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (selectedMember != null) {
      return MemberDetailFlutter(member: selectedMember!, onBack: onBack);
    }

    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = members[index];
        return ListTile(
          tileColor: const Color(0xFF1F2937),
          title: Text(member['name'] ?? ''),
          subtitle: Text(member['phone'] ?? ''),
          trailing: Text(member['status'] ?? '', style: const TextStyle(color: Colors.white70)),
          onTap: () => onSelectMember(member),
        );
      },
    );
  }
}
