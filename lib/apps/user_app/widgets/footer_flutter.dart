import 'package:flutter/material.dart';

class FooterFlutter extends StatelessWidget {
  const FooterFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const Text(
        '© 2024 Construction Workforce Matching Platform.',
        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
      ),
    );
  }
}
