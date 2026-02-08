import 'package:flutter/material.dart';

class TooltipFlutter extends StatelessWidget {
  const TooltipFlutter({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info, size: 16, color: Color(0xFF475569)),
          const SizedBox(width: 6),
          Flexible(child: Text(message, style: const TextStyle(color: Color(0xFF475569)))),
        ],
      ),
    );
  }
}
