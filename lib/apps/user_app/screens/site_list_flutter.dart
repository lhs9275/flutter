import 'package:flutter/material.dart';

class SiteListFlutter extends StatelessWidget {
  const SiteListFlutter({
    super.key,
    required this.sites,
    required this.onViewDetail,
    required this.onApply,
  });

  final List<Map<String, String>> sites;
  final ValueChanged<Map<String, String>> onViewDetail;
  final ValueChanged<Map<String, String>> onApply;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: sites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final site = sites[index];
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
              Text(site['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(site['address'] ?? '', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(site['type'] ?? '')),
                  Text('일급 ${site['pay'] ?? '-'}원', style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('근무일: ${site['date'] ?? '-'}', style: const TextStyle(color: Colors.white54)),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => onViewDetail(site),
                        child: const Text('상세보기'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => onApply(site),
                        child: const Text('지원하기'),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
