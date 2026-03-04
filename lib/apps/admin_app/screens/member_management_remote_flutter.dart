import 'package:flutter/material.dart';

import '../../../data/cwmp_api_models.dart';
import '../../../widgets/remote_status_banner_flutter.dart';

class MemberManagementRemoteFlutter extends StatelessWidget {
  const MemberManagementRemoteFlutter({
    super.key,
    required this.members,
    required this.selectedMemberDetail,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onSelectMember,
    required this.onBack,
    required this.onUpdateMember,
  });

  final List<CwmpAdminUserSummaryResponse> members;
  final CwmpAdminUserDetailResponse? selectedMemberDetail;
  final bool isLoading;
  final String? error;
  final Future<void> Function()? onRefresh;
  final ValueChanged<CwmpAdminUserSummaryResponse> onSelectMember;
  final VoidCallback onBack;
  final Future<CwmpAdminUserDetailResponse> Function({
    required int userId,
    String? name,
    String? role,
    int? perm,
    bool? phoneVerified,
  })
  onUpdateMember;

  @override
  Widget build(BuildContext context) {
    if (selectedMemberDetail != null) {
      return _MemberDetailView(
        detail: selectedMemberDetail!,
        onBack: onBack,
        onUpdateMember: onUpdateMember,
      );
    }

    return Column(
      children: [
        RemoteStatusBannerFlutter(
          isLoading: isLoading,
          error: error,
          infoMessage: '실서버 회원 목록 기준',
          showInfoOnlyWhenNoError: true,
          onRefresh: onRefresh,
        ),
        Expanded(
          child: members.isEmpty
              ? const Center(
                  child: Text(
                    '회원이 없습니다.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              : ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final noShowCount = member.noShowCount;
                    return ListTile(
                      tileColor: const Color(0xFFFFFFFF),
                      title: Text(
                        member.name?.trim().isNotEmpty == true
                            ? member.name!.trim()
                            : '사용자 #${member.id}',
                      ),
                      subtitle: Text(member.phoneNumber),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (noShowCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: Text(
                                '노쇼 ${noShowCount}회',
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (noShowCount > 0) const SizedBox(width: 8),
                          Text(
                            '${member.role} · ${member.status}',
                            style: const TextStyle(color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                      onTap: () => onSelectMember(member),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MemberDetailView extends StatelessWidget {
  const _MemberDetailView({
    required this.detail,
    required this.onBack,
    required this.onUpdateMember,
  });

  final CwmpAdminUserDetailResponse detail;
  final VoidCallback onBack;
  final Future<CwmpAdminUserDetailResponse> Function({
    required int userId,
    String? name,
    String? role,
    int? perm,
    bool? phoneVerified,
  })
  onUpdateMember;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    final noShowCount = summary.noShowCount;
    return SingleChildScrollView(
      child: Column(
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
                Text(
                  summary.name?.trim().isNotEmpty == true
                      ? summary.name!.trim()
                      : '사용자 #${summary.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _row('휴대폰', summary.phoneNumber),
                _row('상태', '${summary.status} (${summary.role})'),
                _row('perm', summary.perm.toString()),
                _row('전화인증', summary.phoneVerified ? '완료' : '미완료'),
                _row('이메일', detail.email ?? '-'),
                _row('성별', detail.gender ?? '-'),
                _row('국적', detail.nationality ?? '-'),
                _row('주소', detail.address ?? '-'),
                _row('주민등록번호', detail.idNumber ?? '-'),
                _row('은행', detail.bankName ?? '-'),
                _row('계좌번호', detail.accountNumber ?? '-'),
                _row('예금주', detail.accountHolder ?? '-'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.report_problem,
                      size: 16,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '노쇼 ${noShowCount}회',
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _openEditDialog(context),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('회원 수정'),
                  ),
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
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value'),
    );
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final summary = detail.summary;
    final nameController = TextEditingController(text: summary.name ?? '');
    final permController = TextEditingController(text: summary.perm.toString());
    final roleOptions = const ['WORKER', 'EMPLOYER', 'ADMIN'];
    var selectedRole = summary.role.trim().isEmpty
        ? roleOptions.first
        : summary.role;
    if (!roleOptions.contains(selectedRole)) {
      selectedRole = roleOptions.first;
    }
    var phoneVerified = summary.phoneVerified;
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setLocalState) {
              return AlertDialog(
                title: const Text('회원 정보 수정'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(
                          labelText: '역할',
                          filled: true,
                        ),
                        items: roleOptions
                            .map(
                              (role) => DropdownMenuItem<String>(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setLocalState(() {
                          selectedRole = value ?? roleOptions.first;
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: permController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'perm',
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: phoneVerified,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('전화 인증 완료'),
                        onChanged: (value) => setLocalState(() {
                          phoneVerified = value;
                        }),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final perm = int.tryParse(permController.text.trim());
                      if (perm == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('perm 값을 확인해주세요.')),
                        );
                        return;
                      }
                      try {
                        await onUpdateMember(
                          userId: summary.id,
                          name: nameController.text.trim(),
                          role: selectedRole,
                          perm: perm,
                          phoneVerified: phoneVerified,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(true);
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text('회원 수정 실패: $e')));
                      }
                    },
                    child: const Text('저장'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('회원 정보가 업데이트되었습니다.')));
      }
    } finally {
      nameController.dispose();
      permController.dispose();
    }
  }
}
