import 'package:flutter/material.dart';
import '../widgets/attendance_scan_sheet_flutter.dart';
import '../../../widgets/attendance_qr_helper.dart';
import '../../../data/mock_backend.dart';

enum _HistoryFilter { thisMonth, lastMonth, threeMonths, all }

class HistoryDetailViewFlutter extends StatefulWidget {
  const HistoryDetailViewFlutter({
    super.key,
    required this.currentUserName,
    required this.currentUserPhone,
  });

  final String currentUserName;
  final String currentUserPhone;

  @override
  State<HistoryDetailViewFlutter> createState() => _HistoryDetailViewFlutterState();
}

class _HistoryDetailViewFlutterState extends State<HistoryDetailViewFlutter> {
  DateTime? _lastAttendanceAt;
  String? _lastAttendanceSite;
  bool _confirmedThisSession = false;
  String? _attendanceErrorMessage;
  late final List<_HistoryItem> _items;
  _HistoryFilter _activeFilter = _HistoryFilter.thisMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _items = [
      _HistoryItem(
        date: DateTime(now.year, now.month, 2),
        site: '판교 IT센터',
        role: '조공',
        pay: 170000,
        status: '지급 대기',
      ),
      _HistoryItem(
        date: DateTime(now.year, now.month, 7),
        site: '서초 아파트 재건축',
        role: '보통인부',
        pay: 150000,
        status: '정산 완료',
      ),
      _HistoryItem(
        date: DateTime(now.year, now.month - 1, 22),
        site: '성수동 카페 공사',
        role: '기공',
        pay: 220000,
        status: '정산 완료',
      ),
      _HistoryItem(
        date: DateTime(now.year, now.month - 2, 15),
        site: '홍대 리모델링',
        role: '조공',
        pay: 170000,
        status: '정산 완료',
      ),
    ];
  }

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

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  String _formatCurrency(int value) {
    final buffer = StringBuffer();
    final text = value.toString();
    for (var i = 0; i < text.length; i += 1) {
      final indexFromEnd = text.length - i;
      buffer.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
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
                      _formatDate(item.date),
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
                            text: '${_formatCurrency(item.pay)}원',
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
    final filteredItems = _filteredItems();
    final totalPay = filteredItems.fold<int>(0, (sum, item) => sum + item.pay);
    final completedCount = filteredItems.where((item) => item.status == '정산 완료').length;
    final pendingCount = filteredItems.where((item) => item.status != '정산 완료').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAttendanceCard(context),
        const SizedBox(height: 16),
        _buildFilterBar(),
        const SizedBox(height: 12),
        _buildSummaryCard(
          totalCount: filteredItems.length,
          totalPay: totalPay,
          completedCount: completedCount,
          pendingCount: pendingCount,
        ),
        const SizedBox(height: 12),
        if (filteredItems.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('선택한 기간에 정산 내역이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          )
        else
          ...filteredItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHistoryCard(item),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Wrap(
      spacing: 8,
      children: [
        _buildFilterChip(_HistoryFilter.thisMonth, '이번달'),
        _buildFilterChip(_HistoryFilter.lastMonth, '지난달'),
        _buildFilterChip(_HistoryFilter.threeMonths, '3개월'),
        _buildFilterChip(_HistoryFilter.all, '전체'),
      ],
    );
  }

  Widget _buildFilterChip(_HistoryFilter filter, String label) {
    final selected = _activeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _activeFilter = filter),
      selectedColor: const Color(0xFFDBEAFE),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int totalCount,
    required int totalPay,
    required int completedCount,
    required int pendingCount,
  }) {
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
          const Text('정산 요약', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _InfoRow(label: '총 근무일', value: '$totalCount일'),
          _InfoRow(label: '총 금액', value: '${_formatCurrency(totalPay)}원'),
          _InfoRow(label: '정산 완료', value: '$completedCount건'),
          _InfoRow(label: '지급 대기', value: '$pendingCount건'),
        ],
      ),
    );
  }

  List<_HistoryItem> _filteredItems() {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;
    switch (_activeFilter) {
      case _HistoryFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case _HistoryFilter.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;
      case _HistoryFilter.threeMonths:
        start = DateTime(now.year, now.month - 2, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case _HistoryFilter.all:
        start = null;
        end = null;
        break;
    }
    final filtered = _items.where((item) {
      if (start != null && item.date.isBefore(start)) return false;
      if (end != null && item.date.isAfter(end)) return false;
      return true;
    }).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
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
    _attendanceErrorMessage = null;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendanceScanSheetFlutter(
          onConfirmed: (payload) {
            final saved = MockBackend.markAttendance(
              siteId: payload.siteId ?? '',
              siteName: payload.siteName,
              name: widget.currentUserName,
              phone: widget.currentUserPhone,
            );
            if (saved == null) {
              _attendanceErrorMessage = '확정된 근로자만 출근 확인이 가능합니다.';
              return;
            }
            _confirmedThisSession = true;
            setState(() {
              _lastAttendanceAt = DateTime.now();
              _lastAttendanceSite = saved['siteName']?.toString() ?? payload.siteName;
            });
          },
        ),
      ),
    );
    if (!mounted) return;
    if (_attendanceErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_attendanceErrorMessage!)),
      );
      return;
    }
    if (!_confirmedThisSession) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('출근 확인이 완료되었습니다.')),
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
            width: 90,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF0F172A)))),
        ],
      ),
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

  final DateTime date;
  final String site;
  final String role;
  final int pay;
  final String status;
}
