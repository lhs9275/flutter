import 'package:flutter/material.dart';
import '../../../widgets/map_launcher_card_flutter.dart';

class SiteDetailFlutter extends StatelessWidget {
  const SiteDetailFlutter({
    super.key,
    required this.site,
    required this.onApply,
  });

  final Map<String, dynamic> site;
  final VoidCallback onApply;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final lat = _toDouble(site['lat']);
    final lng = _toDouble(site['lng']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(site['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(site['address'] ?? '', style: const TextStyle(color: Color(0xFF475569))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(site['type'] ?? '')),
            Text('일급 ${site['pay'] ?? '-'}원', style: const TextStyle(color: Color(0xFF475569))),
          ],
        ),
        const SizedBox(height: 16),
        MapLauncherCardFlutter(
          name: site['name'] ?? '',
          address: site['address'] ?? '',
          latitude: lat,
          longitude: lng,
        ),
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
