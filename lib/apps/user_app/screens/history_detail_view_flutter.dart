import 'package:flutter/material.dart';
import '../widgets/attendance_scan_sheet_flutter.dart';
import '../../../widgets/attendance_qr_helper.dart';

class HistoryDetailViewFlutter extends StatefulWidget {
  const HistoryDetailViewFlutter({super.key});

  @override
  State<HistoryDetailViewFlutter> createState() => _HistoryDetailViewFlutterState();
}

class _HistoryDetailViewFlutterState extends State<HistoryDetailViewFlutter> {
  DateTime? _lastAttendanceAt;
  String? _lastAttendanceSite;
  bool _confirmedThisSession = false;

  static const List<_HistoryItem> _items = [
    _HistoryItem(
      date: '2024-07-20',
      site: '강남 오피스텔',
      role: '보통인부',
      pay: '150,000원',
      status: '정산 완료',
    ),
    _HistoryItem(
      date: '2024-07-22',
      site: '홍대 리모델링',
      role: '조공',
      pay: '170,000원',
      status: '지급 대기',
    ),
    _HistoryItem(
      date: '2024-07-25',
      site: '성수동 카페 공사',
      role: '기공',
      pay: '220,000원',
      status: '정산 완료',
    ),
  ];

  Widget _buildStatusLabel(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(_HistoryItem item) {
    final statusColor = item.status == '정산 완료' ? const Color(0xFF34D399) : const Color(0xFFF59E0B);
    final borderColor = statusColor.withOpacity(0.35);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.site,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: item.role,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const TextSpan(text: ' · ', style: TextStyle(color: Color(0xFF64748B))),
                          TextSpan(
                            text: item.pay,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusLabel(item.status, statusColor),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAttendanceCard(context),
        const SizedBox(height: 16),
        ..._items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHistoryCard(item),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(BuildContext context) {
    final lastChecked = _lastAttendanceAt == null
        ? '아직 출근 확인 기록이 없습니다.'
        : '마지막 확인: ${formatTime(_lastAttendanceAt!)} · ${_lastAttendanceSite ?? '-'}';
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
          const Text('출근 확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            '현장 담당자가 제공한 QR을 스캔하면 출근 확인이 완료됩니다.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Text(lastChecked, style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openAttendanceScanner(context),
              child: const Text('QR 스캔하기'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttendanceScanner(BuildContext context) async {
    _confirmedThisSession = false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendanceScanSheetFlutter(
          onConfirmed: (payload) {
            _confirmedThisSession = true;
            setState(() {
              _lastAttendanceAt = DateTime.now();
              _lastAttendanceSite = payload.siteName;
            });
          },
        ),
      ),
    );
    if (!_confirmedThisSession || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('출근 확인이 완료되었습니다.')),
    );
  }
}

class _HistoryItem {
  const _HistoryItem({
    required this.date,
    required this.site,
    required this.role,
    required this.pay,
    required this.status,
  });

  final String date;
  final String site;
  final String role;
  final String pay;
  final String status;
}
