import 'package:flutter/material.dart';
import '../../../widgets/map_launcher_card_flutter.dart';

class SiteWorkDetailFlutter extends StatelessWidget {
  const SiteWorkDetailFlutter({super.key, required this.site});

  final Map<String, dynamic> site;

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
    final address = site['address'] as String? ?? '';
    final phoneVerified = site['phoneVerified'] == true;
    final bizName = site['bizName'] as String? ?? '-';
    final bizNumber = site['bizNumber'] as String? ?? '-';
    final representative = site['representative'] as String? ?? '-';
    final bizPhone = site['bizPhone'] as String? ?? '-';
    final agentName = site['agentName'] as String? ?? '-';
    final agentPhone = site['agentPhone'] as String? ?? '-';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(site['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (address.isNotEmpty) ...[
            Text(address, style: const TextStyle(color: Color(0xFF475569))),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(
                phoneVerified ? Icons.check_circle : Icons.phone_in_talk,
                size: 16,
                color: phoneVerified ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 6),
              Text(
                phoneVerified ? '전화 확인 완료 (최초 1회)' : '전화 확인 대기 (최초 1회)',
                style: TextStyle(
                  color: phoneVerified ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MapLauncherCardFlutter(
            name: site['name'] ?? '',
            address: address,
            latitude: lat,
            longitude: lng,
            height: 120,
          ),
          const SizedBox(height: 12),
          const Text('사업자 정보', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('사업자명: $bizName', style: const TextStyle(color: Color(0xFF475569))),
          Text('사업자등록번호: $bizNumber', style: const TextStyle(color: Color(0xFF475569))),
          Text('대표자명: $representative', style: const TextStyle(color: Color(0xFF475569))),
          Text('사업자 연락처: $bizPhone', style: const TextStyle(color: Color(0xFF475569))),
          const SizedBox(height: 12),
          const Text('현장 대리인 연락처', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('이름: $agentName', style: const TextStyle(color: Color(0xFF475569))),
          Text('연락처: $agentPhone', style: const TextStyle(color: Color(0xFF475569))),
          const SizedBox(height: 12),
          Text('상태: ${site['status'] ?? '-'}'),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: phoneVerified ? () {} : null,
                child: const Text('승인'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('반려')),
            ],
          )
        ],
      ),
    );
  }
}
