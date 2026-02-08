import 'package:flutter/material.dart';

class CalendarViewFlutter extends StatelessWidget {
  const CalendarViewFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('캘린더', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('월별 일정 캘린더 영역', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 8),
          Text('예정 근무: 2024-08-02 판교 IT센터'),
        ],
      ),
    );
  }
}
