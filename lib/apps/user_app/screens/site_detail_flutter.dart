import 'package:flutter/material.dart';
import '../widgets/site_map_flutter.dart';

class SiteDetailFlutter extends StatelessWidget {
  const SiteDetailFlutter({
    super.key,
    required this.site,
    required this.onApply,
  });

  final Map<String, String> site;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(site['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(site['address'] ?? '', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(site['type'] ?? '')),
            Text('일급 ${site['pay'] ?? '-'}원', style: const TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 16),
        const SiteMapFlutter(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onApply,
            child: const Text('지원하기'),
          ),
        ),
      ],
    );
  }
}
