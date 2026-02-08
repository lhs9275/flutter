import 'package:flutter/material.dart';

class PermissionManagementFlutter extends StatelessWidget {
  const PermissionManagementFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          tileColor: Color(0xFF1F2937),
          title: Text('master'),
          subtitle: Text('전체 권한'),
        ),
        SizedBox(height: 12),
        ListTile(
          tileColor: Color(0xFF1F2937),
          title: Text('site_admin'),
          subtitle: Text('현장 관리 권한'),
        ),
      ],
    );
  }
}
