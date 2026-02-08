import 'package:flutter/material.dart';

class GameCenterFlutter extends StatelessWidget {
  const GameCenterFlutter({super.key});

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
        children: const [
          Text('게임센터', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('출근 도장 찍기, 미션 달성 보상 등', style: TextStyle(color: Color(0xFF475569))),
          SizedBox(height: 12),
          LinearProgressIndicator(value: 0.6),
        ],
      ),
    );
  }
}
