import 'package:flutter/material.dart';
import '../../../data/cwmp_api_models.dart';
import '../../../data/cwmp_api_repository.dart';
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
  State<HistoryDetailViewFlutter> createState() =>
      _HistoryDetailViewFlutterState();
}

class _HistoryDetailViewFlutterState extends State<HistoryDetailViewFlutter> {
  DateTime? _lastAttendanceAt;
  String? _lastAttendanceSite;
  bool _confirmedThisSession = false;
  String? _attendanceErrorMessage;
  bool _isAttendanceLoading = false;
  String? _attendanceLoadError;
  List<CwmpAttendanceCheckResponse> _attendanceRecords = const [];
  late final List<_HistoryItem> _items;
  bool _isRemoteLoading = false;
  String? _remoteError;
  bool _hasRemoteRecords = false;
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
    _loadRemoteWorkRecords();
    _loadRemoteAttendance();
  }

  Future<void> _loadRemoteWorkRecords() async {
    setState(() {
      _isRemoteLoading = true;
      _remoteError = null;
    });
    try {
      final summary = await CwmpApiRepository.instance.getMyWorkRecords();
      final remoteItems = summary.records
          .map(_HistoryItem.fromWorkRecord)
          .toList();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(remoteItems);
        _hasRemoteRecords = true;
      });
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      setState(() => _remoteError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _remoteError = '근무 이력을 불러오지 못했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isRemoteLoading = false);
      }
    }
  }

  Future<void> _loadRemoteAttendance({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isAttendanceLoading = true;
        _attendanceLoadError = null;
      });
    } else {
      _isAttendanceLoading = true;
      _attendanceLoadError = null;
    }
    try {
      final records = await CwmpApiRepository.instance.getMyAttendance();
      if (!mounted) return;
      records.sort((a, b) {
        final aAt = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
      CwmpAttendanceCheckResponse? latest;
      for (final record in records) {
        if (record.occurredAt == null) continue;
        if (latest == null) {
          latest = record;
          continue;
        }
        final currentAt = latest.occurredAt;
        if (currentAt == null || record.occurredAt!.isAfter(currentAt)) {
          latest = record;
        }
      }
      if (latest != null) {
        final latestRecord = latest;
        setState(() {
          _attendanceRecords = records;
          _lastAttendanceAt = latestRecord.occurredAt;
          _lastAttendanceSite = (latestRecord.siteName ?? '').trim().isEmpty
              ? _lastAttendanceSite
              : latestRecord.siteName;
        });
      } else if (!silent) {
        setState(() {
          _attendanceRecords = records;
          _lastAttendanceAt = null;
          _lastAttendanceSite = null;
        });
      }
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode != 401 && e.statusCode != 404) {
        setState(() => _attendanceLoadError = e.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _attendanceLoadError = '출근 기록을 불러오지 못했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isAttendanceLoading = false);
      } else {
        _isAttendanceLoading = false;
      }
    }
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
    final statusColor = item.status == '정산 완료'
        ? const Color(0xFF34D399)
        : const Color(0xFFF59E0B);
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
                          const TextSpan(
                            text: ' · ',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
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
    final completedCount = filteredItems
        .where((item) => item.status == '정산 완료')
        .length;
    final pendingCount = filteredItems
        .where((item) => item.status != '정산 완료')
        .length;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAttendanceCard(context),
              const SizedBox(height: 12),
              _buildAttendanceHistorySection(),
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
                    child: Text(
                      '선택한 기간에 정산 내역이 없습니다.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
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
          ),
        ),
      ),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  '정산 요약',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (_isRemoteLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if ((_remoteError ?? '').isNotEmpty) ...[
            Text(
              _remoteError!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
            ),
            const SizedBox(height: 8),
          ] else if (_hasRemoteRecords) ...[
            const Text(
              '실서버 근무이력 기준',
              style: TextStyle(color: Color(0xFF2563EB), fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
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
          const Text(
            '출근 확인',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            '현장 담당자가 제공한 QR을 스캔하면 출근 확인이 완료됩니다.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          if (_attendanceLoadError != null) ...[
            const SizedBox(height: 8),
            Text(
              _attendanceLoadError!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  lastChecked,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: '출근 기록 새로고침',
                onPressed: _isAttendanceLoading
                    ? null
                    : () => _loadRemoteAttendance(),
                icon: _isAttendanceLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
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

  Widget _buildAttendanceHistorySection() {
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
          const Text(
            '최근 출근 기록',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_attendanceRecords.isEmpty)
            const Text(
              '저장된 출근 기록이 없습니다.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            )
          else ...[
            const Text(
              '실서버 출근확인 기준',
              style: TextStyle(color: Color(0xFF2563EB), fontSize: 12),
            ),
            const SizedBox(height: 10),
            ..._attendanceRecords
                .take(5)
                .map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (record.siteName ?? '').trim().isEmpty
                                    ? '현장 #${record.siteId ?? '-'}'
                                    : record.siteName!.trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                record.occurredAt == null
                                    ? '근무일 ${record.workDate}'
                                    : '출근 ${_formatDate(record.occurredAt!)} ${formatTime(record.occurredAt!)}',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 12,
                                ),
                              ),
                              if (record.jobPostId != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '공고 #${record.jobPostId}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (record.alreadyCheckedIn)
                          const Text(
                            '확인됨',
                            style: TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
          ],
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
          onConfirmed: (payload) async {
            final parsedSiteId = int.tryParse((payload.siteId ?? '').trim());
            try {
              final scanned = await CwmpApiRepository.instance.scanAttendance(
                siteId: parsedSiteId,
                siteName: payload.siteName,
                issuedAt: payload.issuedAt,
                expiresAt: payload.expiresAt,
                token: payload.token,
              );
              _confirmedThisSession = true;
              if (!mounted) return;
              setState(() {
                _lastAttendanceAt = scanned.occurredAt ?? DateTime.now();
                _lastAttendanceSite = (scanned.siteName ?? '').trim().isEmpty
                    ? payload.siteName
                    : scanned.siteName;
              });
              _loadRemoteAttendance(silent: true);
              return;
            } on CwmpApiException catch (e) {
              if (e.statusCode != 401) {
                _attendanceErrorMessage = e.message;
                return;
              }
              // Standalone/mock preview fallback when no CWMP session exists.
            } catch (e) {
              _attendanceErrorMessage = '출근 확인 중 오류가 발생했습니다: $e';
              return;
            }

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
            if (!mounted) return;
            setState(() {
              _lastAttendanceAt = DateTime.now();
              _lastAttendanceSite =
                  saved['siteName']?.toString() ?? payload.siteName;
            });
          },
        ),
      ),
    );
    if (!mounted) return;
    if (_attendanceErrorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_attendanceErrorMessage!)));
      return;
    }
    if (!_confirmedThisSession) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('출근 확인이 완료되었습니다.')));
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
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
          ),
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

  factory _HistoryItem.fromWorkRecord(CwmpWorkRecordResponse record) {
    final date = DateTime.tryParse(record.workDate) ?? DateTime.now();
    final totalPay = record.totalPay;
    final status = record.status.toUpperCase() == 'SETTLED' ? '정산 완료' : '지급 대기';
    final roleLabel = record.workUnits == 1
        ? '근무 1공수'
        : '근무 ${record.workUnits.toString()}공수';
    return _HistoryItem(
      date: date,
      site: record.jobPostId > 0 ? '공고 #${record.jobPostId}' : '근무 기록',
      role: roleLabel,
      pay: totalPay.round(),
      status: status,
    );
  }
}
