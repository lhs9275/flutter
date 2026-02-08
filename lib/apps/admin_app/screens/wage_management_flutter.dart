import 'package:flutter/material.dart';

class WageManagementFlutter extends StatelessWidget {
  const WageManagementFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          tileColor: Color(0xFFFFFFFF),
          title: Text('김테스트'),
          subtitle: Text('이번주 정산 450,000원'),
        ),
        SizedBox(height: 12),
        ListTile(
          tileColor: Color(0xFFFFFFFF),
          title: Text('이철수'),
          subtitle: Text('이번주 정산 320,000원'),
        ),
      ],
    );
  }
}
