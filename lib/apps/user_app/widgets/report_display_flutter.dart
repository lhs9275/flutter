import 'package:flutter/material.dart';

class ReportDisplayFlutter extends StatelessWidget {
  const ReportDisplayFlutter({super.key});

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
          Text('요약 리포트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('이번 달 출근 12회 · 정산 예정 1,800,000원', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
