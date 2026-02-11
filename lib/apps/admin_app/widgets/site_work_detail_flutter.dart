import 'package:flutter/material.dart';
import '../../../data/mock_backend.dart';
import '../../../widgets/map_launcher_card_flutter.dart';

class SiteWorkDetailFlutter extends StatelessWidget {
  const SiteWorkDetailFlutter({
    super.key,
    required this.site,
    required this.onVerify,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> site;
  final VoidCallback onVerify;
  final VoidCallback onApprove;
  final ValueChanged<String> onReject;

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
    final status = site['status'] as SiteStatus? ?? SiteStatus.pending;
    final statusText = MockBackend.siteStatusLabel(status);
    final rejectReason = site['rejectReason'] as String?;
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
          Text('상태: $statusText'),
          if (rejectReason != null && rejectReason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('반려 사유: $rejectReason', style: const TextStyle(color: Color(0xFFB91C1C))),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!phoneVerified)
                OutlinedButton(
                  onPressed: onVerify,
                  child: const Text('전화 확인 완료'),
                ),
              if (!phoneVerified) const SizedBox(width: 8),
              OutlinedButton(
                onPressed: phoneVerified && status != SiteStatus.approved ? onApprove : null,
                child: const Text('승인'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: status == SiteStatus.rejected ? null : () => _openRejectDialog(context),
                child: const Text('반려'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _openRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반려 사유 입력'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '사유', filled: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('반려')),
        ],
      ),
    );
    if (confirmed != true) return;
    final reason = controller.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반려 사유를 입력해주세요.')),
      );
      return;
    }
    onReject(reason);
  }
}
