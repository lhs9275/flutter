import 'package:flutter/material.dart';

import '../../../data/cwmp_api_models.dart';

class WorkRecordRemoteManagementFlutter extends StatelessWidget {
  const WorkRecordRemoteManagementFlutter({
    super.key,
    required this.publishedJobPosts,
    required this.workRecordsByJobPost,
    required this.loadingWorkRecordJobPostIds,
    required this.onRefresh,
    required this.onLoadWorkRecords,
    this.onSettleRecord,
    this.onReopenRecord,
    this.showSettlementActions = false,
    this.isRefreshing = false,
    this.error,
    this.title = '근무기록 관리',
  });

  final List<CwmpJobPostResponse> publishedJobPosts;
  final Map<int, List<CwmpWorkRecordResponse>> workRecordsByJobPost;
  final Set<int> loadingWorkRecordJobPostIds;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int jobPostId) onLoadWorkRecords;
  final Future<void> Function(int jobPostId, int recordId)? onSettleRecord;
  final Future<void> Function(int jobPostId, int recordId)? onReopenRecord;
  final bool showSettlementActions;
  final bool isRefreshing;
  final String? error;
  final String title;

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SETTLED':
        return const Color(0xFF16A34A);
      case 'REOPENED':
        return const Color(0xFFD97706);
      case 'CONFIRMED':
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'SETTLED':
        return '정산완료';
      case 'REOPENED':
        return '재오픈';
      case 'CONFIRMED':
      default:
        return '확인';
    }
  }

  String _formatMoney(num value) {
    final text = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
    final parts = text.split('.');
    final whole = parts.first;
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i += 1) {
      final indexFromEnd = whole.length - i;
      buf.write(whole[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    if (parts.length == 2 && parts[1] != '0') {
      return '${buf.toString()}.${parts[1]}';
    }
    return buf.toString();
  }

  String _jobPostSummary(CwmpJobPostResponse jobPost) {
    final startTime = (jobPost.startTime ?? '-').trim().isEmpty
        ? '-'
        : jobPost.startTime!;
    final rate = jobPost.dailyRate == null
        ? '-'
        : '${_formatMoney(jobPost.dailyRate!)}원';
    return '${jobPost.workDate} · $startTime · ${jobPost.headcount}명 · $rate';
  }

  bool _matchesFilter(
    CwmpWorkRecordResponse record, {
    required String statusFilter,
    required String dateFilter,
  }) {
    final normalizedStatus = statusFilter.trim().toUpperCase();
    if (normalizedStatus.isNotEmpty && normalizedStatus != 'ALL') {
      if (record.status.toUpperCase() != normalizedStatus) return false;
    }
    final normalizedDate = dateFilter.trim();
    if (normalizedDate.isNotEmpty &&
        !record.workDate.startsWith(normalizedDate)) {
      return false;
    }
    return true;
  }

  List<CwmpWorkRecordResponse> _filteredRecords(
    List<CwmpWorkRecordResponse> records, {
    required String statusFilter,
    required String dateFilter,
  }) {
    return records
        .where(
          (record) => _matchesFilter(
            record,
            statusFilter: statusFilter,
            dateFilter: dateFilter,
          ),
        )
        .toList();
  }

  ({int count, int settled, num pay}) _loadedSummary({
    required String statusFilter,
    required String dateFilter,
  }) {
    var count = 0;
    var settled = 0;
    num pay = 0;
    for (final records in workRecordsByJobPost.values) {
      for (final record in _filteredRecords(
        records,
        statusFilter: statusFilter,
        dateFilter: dateFilter,
      )) {
        count += 1;
        if (record.status.toUpperCase() == 'SETTLED') {
          settled += 1;
        }
        pay += record.totalPay;
      }
    }
    return (count: count, settled: settled, pay: pay);
  }

  Widget _summaryCard({
    required String statusFilter,
    required String dateFilter,
    required ValueChanged<String> onStatusFilterChanged,
    required VoidCallback onPickDateFilter,
    required VoidCallback onClearDateFilter,
  }) {
    final summary = _loadedSummary(
      statusFilter: statusFilter,
      dateFilter: dateFilter,
    );
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: const Text('새로고침'),
              ),
            ],
          ),
          if ((error ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                error!.trim(),
                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: statusFilter,
                decoration: const InputDecoration(
                  labelText: '상태 필터',
                  filled: true,
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('전체')),
                  DropdownMenuItem(value: 'CONFIRMED', child: Text('확인')),
                  DropdownMenuItem(value: 'SETTLED', child: Text('정산완료')),
                  DropdownMenuItem(value: 'REOPENED', child: Text('재오픈')),
                ],
                onChanged: (value) => onStatusFilterChanged(value ?? 'ALL'),
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: '날짜 필터',
                  filled: true,
                  isDense: true,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateFilter.trim().isEmpty ? '전체' : dateFilter,
                        style: TextStyle(
                          color: dateFilter.trim().isEmpty
                              ? const Color(0xFF64748B)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '달력에서 선택',
                      onPressed: onPickDateFilter,
                      icon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    if (dateFilter.trim().isNotEmpty)
                      IconButton(
                        tooltip: '날짜 필터 초기화',
                        onPressed: onClearDateFilter,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('로드된 근무기록 ${summary.count}건'),
              _chip('정산완료 ${summary.settled}건'),
              _chip('합계 ${_formatMoney(summary.pay)}원'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11),
      ),
    );
  }

  Widget _jobPostCard(
    BuildContext context,
    CwmpJobPostResponse jobPost, {
    required String statusFilter,
    required String dateFilter,
  }) {
    final records = workRecordsByJobPost[jobPost.id];
    final filtered = records == null
        ? null
        : _filteredRecords(
            records,
            statusFilter: statusFilter,
            dateFilter: dateFilter,
          );
    final isLoading = loadingWorkRecordJobPostIds.contains(jobPost.id);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          jobPost.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${jobPost.siteName}\n${_jobPostSummary(jobPost)}',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: isLoading ? null : () => onLoadWorkRecords(jobPost.id),
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long, size: 16),
              label: Text(records == null ? '근무기록 조회' : '근무기록 새로고침'),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (records == null)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '근무기록 조회 버튼을 눌러 데이터를 불러오세요.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else if (records.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '근무기록이 없습니다.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else if ((filtered ?? const []).isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '필터 조건에 맞는 근무기록이 없습니다.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            Column(
              children: filtered!.map((record) {
                final statusColor = _statusColor(record.status);
                final isSettled = record.status.toUpperCase() == 'SETTLED';
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              record.workerName.trim().isEmpty
                                  ? 'Worker #${record.workerId}'
                                  : '${record.workerName} (#${record.workerId})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: statusColor.withOpacity(0.35),
                              ),
                            ),
                            child: Text(
                              _statusLabel(record.status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${record.workDate} · 공수 ${record.workUnits} · 지급 ${_formatMoney(record.totalPay)}원',
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                      if (record.dailyRate != null ||
                          record.rating != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '일당 ${record.dailyRate == null ? '-' : '${_formatMoney(record.dailyRate!)}원'} · 평가 ${record.rating?.toString() ?? '-'}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if ((record.evaluationNote ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          record.evaluationNote!.trim(),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (showSettlementActions &&
                          (onSettleRecord != null ||
                              onReopenRecord != null)) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: isSettled || onSettleRecord == null
                                  ? null
                                  : () =>
                                        onSettleRecord!(jobPost.id, record.id),
                              child: const Text('정산 처리'),
                            ),
                            TextButton(
                              onPressed: !isSettled || onReopenRecord == null
                                  ? null
                                  : () =>
                                        onReopenRecord!(jobPost.id, record.id),
                              child: const Text('정산 재오픈'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var statusFilter = 'ALL';
    var dateFilter = '';

    Future<void> pickDateFilter(
      BuildContext context,
      void Function(void Function()) setInnerState,
    ) async {
      final initialDate = DateTime.tryParse(dateFilter) ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(2100, 12, 31),
        helpText: '날짜 필터 선택',
      );
      if (picked == null || !context.mounted) return;
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setInnerState(() => dateFilter = '$y-$m-$d');
    }

    return StatefulBuilder(
      builder: (context, setInnerState) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(
            statusFilter: statusFilter,
            dateFilter: dateFilter,
            onStatusFilterChanged: (value) {
              setInnerState(() => statusFilter = value);
            },
            onPickDateFilter: () => pickDateFilter(context, setInnerState),
            onClearDateFilter: () => setInnerState(() => dateFilter = ''),
          ),
          if (publishedJobPosts.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                '발행된 공고가 없습니다.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            ...publishedJobPosts.map(
              (jobPost) => _jobPostCard(
                context,
                jobPost,
                statusFilter: statusFilter,
                dateFilter: dateFilter,
              ),
            ),
        ],
      ),
    );
  }
}
