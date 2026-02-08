import 'package:flutter/material.dart';

class NoticeViewFlutter extends StatelessWidget {
  const NoticeViewFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ListTile(
          tileColor: Color(0xFF1F2937),
          title: Text('안전 수칙 안내'),
          subtitle: Text('안전화 필수 착용'),
        ),
        SizedBox(height: 12),
        ListTile(
          tileColor: Color(0xFF1F2937),
          title: Text('급여 정산 일정'),
          subtitle: Text('매주 금요일 지급'),
        ),
      ],
    );
  }
}
