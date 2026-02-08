import 'package:flutter/material.dart';

class HistoryDetailViewFlutter extends StatelessWidget {
  const HistoryDetailViewFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ListTile(
          tileColor: Color(0xFF1F2937),
          title: Text('2024-07-20 강남 오피스텔'),
          subtitle: Text('보통인부 · 150,000원'),
        ),
        SizedBox(height: 12),
        ListTile(
          tileColor: Color(0xFF1F2937),
          title: Text('2024-07-22 홍대 리모델링'),
          subtitle: Text('조공 · 170,000원'),
        ),
      ],
    );
  }
}
