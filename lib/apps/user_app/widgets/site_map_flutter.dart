import 'package:flutter/material.dart';

class SiteMapFlutter extends StatelessWidget {
  const SiteMapFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: const Center(child: Text('지도 미리보기 (네이버/카카오맵)')),
    );
  }
}
