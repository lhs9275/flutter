import 'package:flutter/material.dart';

import '../../../data/cwmp_api_models.dart';
import '../../../widgets/remote_status_banner_flutter.dart';

class PermissionManagementRemoteFlutter extends StatelessWidget {
  const PermissionManagementRemoteFlutter({
    super.key,
    required this.templates,
    required this.users,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onLoadUserPermission,
    required this.onUpdateUserPermission,
  });

  final List<CwmpAdminPermissionTemplateResponse> templates;
  final List<CwmpAdminUserSummaryResponse> users;
  final bool isLoading;
  final String? error;
  final Future<void> Function()? onRefresh;
  final Future<CwmpAdminPermissionUserResponse> Function(int userId)
  onLoadUserPermission;
  final Future<CwmpAdminPermissionUserResponse> Function({
    required int userId,
    String? role,
    int? perm,
  })
  onUpdateUserPermission;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RemoteStatusBannerFlutter(
          isLoading: isLoading,
          error: error,
          infoMessage: '실서버 권한 관리 기준',
          showInfoOnlyWhenNoError: true,
          onRefresh: onRefresh,
        ),
        Expanded(
          child: ListView(
            children: [
              _SectionCard(
                title: '권한 템플릿',
                child: templates.isEmpty
                    ? const Text(
                        '권한 템플릿이 없습니다.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      )
                    : Column(
                        children: templates
                            .map(
                              (template) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(template.name),
                                subtitle: Text(template.description),
                                trailing: Text('perm ${template.permLevel}'),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: '사용자 권한',
                child: users.isEmpty
                    ? const Text(
                        '사용자가 없습니다.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      )
                    : Column(
                        children: users
                            .map(
                              (user) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  user.name?.trim().isNotEmpty == true
                                      ? user.name!.trim()
                                      : '사용자 #${user.id}',
                                ),
                                subtitle: Text(
                                  '${user.phoneNumber} · ${user.role} · perm ${user.perm}',
                                ),
                                trailing: TextButton(
                                  onPressed: () =>
                                      _openPermissionEditor(context, user),
                                  child: const Text('수정'),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openPermissionEditor(
    BuildContext context,
    CwmpAdminUserSummaryResponse user,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    CwmpAdminPermissionUserResponse detail;
    try {
      detail = await onLoadUserPermission(user.id);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('권한 정보 조회 실패: $e')));
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();

    final permController = TextEditingController(text: detail.perm.toString());
    String selectedRole = (detail.role ?? user.role).trim();
    final roleOptions = const ['WORKER', 'EMPLOYER', 'ADMIN'];

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setLocalState) {
              return AlertDialog(
                title: Text(
                  '권한 수정 · ${user.name?.trim().isNotEmpty == true ? user.name!.trim() : '사용자 #${user.id}'}',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.phoneNumber),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: roleOptions.contains(selectedRole)
                            ? selectedRole
                            : roleOptions.first,
                        decoration: const InputDecoration(
                          labelText: '역할',
                          filled: true,
                        ),
                        items: roleOptions
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setLocalState(
                          () => selectedRole = (value ?? roleOptions.first),
                        ),
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
                      const Text(
                        '현재 권한(Authority)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: detail.authorities
                            .map((a) => Chip(label: Text(a)))
                            .toList(),
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
                          const SnackBar(content: Text('perm 값을 입력해주세요.')),
                        );
                        return;
                      }
                      try {
                        await onUpdateUserPermission(
                          userId: user.id,
                          role: selectedRole,
                          perm: perm,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(true);
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text('권한 수정 실패: $e')));
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
        ).showSnackBar(const SnackBar(content: Text('권한이 업데이트되었습니다.')));
      }
    } finally {
      permController.dispose();
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
