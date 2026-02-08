import 'package:flutter/material.dart';

class TooltipFlutter extends StatelessWidget {
  const TooltipFlutter({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Flexible(child: Text(message, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}
