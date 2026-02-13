import 'package:flutter/material.dart';
import '../models/application_record.dart';
import '../../../widgets/map_launcher_card_flutter.dart';

class SiteDetailFlutter extends StatelessWidget {
  const SiteDetailFlutter({
    super.key,
    required this.site,
    required this.application,
    required this.onApply,
    required this.onCancel,
  });

  final Map<String, dynamic> site;
  final ApplicationRecord? application;
  final VoidCallback onApply;
  final VoidCallback onCancel;

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
    final status = application?.status;
    final statusLabel = status == ApplicationStatus.confirmed
        ? '확정 완료'
        : status == ApplicationStatus.applied
            ? '지원 완료'
            : '모집중';
    final statusColor = status == ApplicationStatus.confirmed
        ? const Color(0xFF16A34A)
        : status == ApplicationStatus.applied
            ? const Color(0xFF2563EB)
            : const Color(0xFF64748B);
    final statusBg = status == ApplicationStatus.confirmed
        ? const Color(0xFFDCFCE7)
        : status == ApplicationStatus.applied
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF1F5F9);
    final pay = site['pay'] ?? '-';
    final date = site['date'] ?? '-';
    final time = site['time'] ?? '-';
    final count = site['count']?.toString() ?? '-';
    final meetingPoint = site['meetingPoint'] ?? '-';
    final notes = site['notes'] ?? '-';
    final contact = site['contact'] ?? '-';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(site['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusBg),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(site['address'] ?? '', style: const TextStyle(color: Color(0xFF475569))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(site['type'] ?? '')),
            _InfoChip(label: '일급', value: '$pay원'),
            _InfoChip(label: '근무일', value: date.toString()),
            _InfoChip(label: '시간', value: time.toString()),
            _InfoChip(label: '인원', value: '${count}명'),
          ],
        ),
        const SizedBox(height: 16),
        _DetailCard(
          title: '근무 정보',
          children: [
            _InfoRow(label: '근무일', value: date.toString()),
            _InfoRow(label: '근무 시간', value: time.toString()),
            _InfoRow(label: '인원', value: '${count}명'),
            _InfoRow(label: '일급', value: '$pay원'),
          ],
        ),
        _DetailCard(
          title: '집결지',
          children: [
            Text(meetingPoint.toString(), style: const TextStyle(color: Color(0xFF475569))),
          ],
        ),
        _DetailCard(
          title: '특이사항',
          children: [
            Text(notes.toString(), style: const TextStyle(color: Color(0xFF475569))),
          ],
        ),
        MapLauncherCardFlutter(
          name: site['name'] ?? '',
          address: site['address'] ?? '',
          latitude: lat,
          longitude: lng,
        ),
        const SizedBox(height: 16),
        if (status == ApplicationStatus.confirmed)
          _DetailCard(
            title: '확정 알림',
            children: [
              Text('관리자가 확정했습니다. 출근 정보를 확인해주세요.', style: const TextStyle(color: Color(0xFF475569))),
            ],
          ),
        if (status == ApplicationStatus.confirmed)
          _DetailCard(
            title: '출근 정보',
            children: [
              _InfoRow(label: '집결지', value: meetingPoint.toString()),
              _InfoRow(label: '시간', value: time.toString()),
              _InfoRow(label: '연락처', value: contact.toString()),
            ],
          ),
        if (status == null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApply,
              child: const Text('지원하기'),
            ),
          )
        else if (status == ApplicationStatus.applied)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('지원 취소'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '관리자 승인 후 확정됩니다.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              child: const Text('확정 완료'),
            ),
          ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label · $value',
        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
      ),
    );
  }
}
