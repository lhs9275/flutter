import 'package:flutter/material.dart';

class SiteWorkDetailFlutter extends StatelessWidget {
  const SiteWorkDetailFlutter({super.key, required this.site});

  final Map<String, String> site;

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
        children: [
          Text(site['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('상태: ${site['status'] ?? '-'}'),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(onPressed: () {}, child: const Text('승인')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('반려')),
            ],
          )
        ],
      ),
    );
  }
}
