import 'package:flutter/material.dart';

class DailyWorkManagementFlutter extends StatelessWidget {
  const DailyWorkManagementFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          tileColor: Color(0xFFFFFFFF),
          title: Text('2024-08-06 서초 아파트'),
          subtitle: Text('배정 5명'),
        ),
        SizedBox(height: 12),
        ListTile(
          tileColor: Color(0xFFFFFFFF),
          title: Text('2024-08-07 판교 IT센터'),
          subtitle: Text('배정 3명'),
        ),
      ],
    );
  }
}
