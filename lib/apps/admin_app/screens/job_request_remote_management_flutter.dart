import 'package:flutter/material.dart';

import '../../../data/cwmp_api_models.dart';
import '../../../data/mock_backend.dart';

typedef RemoteWorkRecordUpsertCallback =
    Future<void> Function({
      required int jobPostId,
      required int matchId,
      String? workDate,
      required num workUnits,
      int? rating,
      String? evaluationNote,
    });

typedef RemoteWorkRecordDetailCallback =
    Future<CwmpWorkRecordResponse> Function(int matchId);

class JobRequestRemoteManagementFlutter extends StatelessWidget {
  const JobRequestRemoteManagementFlutter({
    super.key,
    required this.pendingRequests,
    required this.publishedJobPosts,
    required this.matchesByJobPost,
    required this.loadingMatchJobPostIds,
    required this.workRecordsByJobPost,
    required this.workerNamesByUserId,
    required this.noShowSummaryByUserId,
    required this.onRefresh,
    required this.onApproveRequest,
    required this.onRejectRequest,
    required this.onLoadMatches,
    required this.onPrioritizeMatch,
    required this.onConfirmMatch,
    required this.onRecordNoShow,
    required this.onUpsertWorkRecord,
    required this.onFetchWorkRecordDetail,
    required this.onFetchNoShowSummary,
    required this.matchStatusFilter,
    required this.noShowFilter,
    required this.workRecordStatusFilter,
    required this.onMatchStatusFilterChanged,
    required this.onNoShowFilterChanged,
    required this.onWorkRecordStatusFilterChanged,
    this.isRefreshing = false,
    this.error,
  });

  final List<Map<String, dynamic>> pendingRequests;
  final List<CwmpJobPostResponse> publishedJobPosts;
  final Map<int, List<CwmpMatchSelectionResponse>> matchesByJobPost;
  final Set<int> loadingMatchJobPostIds;
  final Map<int, List<CwmpWorkRecordResponse>> workRecordsByJobPost;
  final Map<int, String> workerNamesByUserId;
  final Map<int, CwmpNoShowSummaryResponse> noShowSummaryByUserId;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String requestId, String? regionCode)
  onApproveRequest;
  final Future<void> Function(String requestId, String reason) onRejectRequest;
  final Future<void> Function(int jobPostId) onLoadMatches;
  final Future<void> Function(
    int jobPostId,
    int matchId,
    int? selectionOrder,
    String? note,
  )
  onPrioritizeMatch;
  final Future<void> Function(int jobPostId, int matchId) onConfirmMatch;
  final Future<void> Function(int jobPostId, int matchId, String? reason)
  onRecordNoShow;
  final RemoteWorkRecordUpsertCallback onUpsertWorkRecord;
  final RemoteWorkRecordDetailCallback onFetchWorkRecordDetail;
  final Future<CwmpNoShowSummaryResponse> Function(int userId)
  onFetchNoShowSummary;
  final String matchStatusFilter;
  final String noShowFilter;
  final String workRecordStatusFilter;
  final ValueChanged<String> onMatchStatusFilterChanged;
  final ValueChanged<String> onNoShowFilterChanged;
  final ValueChanged<String> onWorkRecordStatusFilterChanged;
  final bool isRefreshing;
  final String? error;

  Color _matchStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return const Color(0xFF16A34A);
      case 'NO_SHOW':
        return const Color(0xFFDC2626);
      case 'PREFERRED':
        return const Color(0xFF7C3AED);
      case 'CANCELLED':
        return const Color(0xFF64748B);
      case 'APPLIED':
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _matchStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return '확정';
      case 'NO_SHOW':
        return '노쇼';
      case 'PREFERRED':
        return '우선선발';
      case 'CANCELLED':
        return '취소';
      case 'APPLIED':
      default:
        return '지원';
    }
  }

  String _workRecordStatusLabel(String status) {
    switch (status.trim().toUpperCase()) {
      case 'SETTLED':
        return '정산완료';
      case 'REOPENED':
        return '재오픈';
      case 'CONFIRMED':
      default:
        return '확인';
    }
  }

  ({Color bg, Color border, Color fg}) _workRecordStatusColors(String status) {
    switch (status.trim().toUpperCase()) {
      case 'SETTLED':
        return (
          bg: const Color(0xFFDCFCE7),
          border: const Color(0xFF86EFAC),
          fg: const Color(0xFF166534),
        );
      case 'REOPENED':
        return (
          bg: const Color(0xFFFFEDD5),
          border: const Color(0xFFFDBA74),
          fg: const Color(0xFF9A3412),
        );
      case 'CONFIRMED':
      default:
        return (
          bg: const Color(0xFFEFF6FF),
          border: const Color(0xFFBFDBFE),
          fg: const Color(0xFF1D4ED8),
        );
    }
  }

  String _jobRequestSummary(Map<String, dynamic> request) {
    final date = request['date']?.toString() ?? '-';
    final time = request['time']?.toString() ?? '-';
    final type = request['jobType']?.toString() ?? '-';
    final count = request['count']?.toString() ?? '0';
    return '$date · $time · $type $count명';
  }

  String _jobPostSummary(CwmpJobPostResponse jobPost) {
    final time = (jobPost.startTime ?? '-').trim().isEmpty
        ? '-'
        : jobPost.startTime!;
    final pay = jobPost.dailyRate == null
        ? '-'
        : _formatMoney(jobPost.dailyRate!);
    return '${jobPost.workDate} · $time · ${jobPost.headcount}명 · $pay원';
  }

  String _formatMoney(int value) {
    final text = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < text.length; i += 1) {
      final indexFromEnd = text.length - i;
      buf.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return buf.toString();
  }

  Future<void> _promptReject(BuildContext context, String requestId) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공고 요청 반려'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '반려 사유', filled: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('반려'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final reason = controller.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('반려 사유를 입력해주세요.')));
      return;
    }
    await onRejectRequest(requestId, reason);
  }

  Future<void> _promptApprove(
    BuildContext context,
    String requestId, {
    String? initialRegionCode,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공고 요청 승인/발행'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '앱이 현장 좌표로 지역코드를 자동 계산해 공고를 발행합니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            if ((initialRegionCode ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '기존 값: ${initialRegionCode!.trim()} (입력 없이 자동 계산값 우선 사용)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('승인/발행'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await onApproveRequest(requestId, null);
  }

  Future<void> _promptPrioritize(
    BuildContext context, {
    required int jobPostId,
    required int matchId,
  }) async {
    final orderController = TextEditingController();
    final noteController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('우선선발 표시'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: orderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '선발 순서 (선택)',
                filled: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final order = int.tryParse(orderController.text.trim());
    final note = noteController.text.trim().isEmpty
        ? null
        : noteController.text.trim();
    await onPrioritizeMatch(jobPostId, matchId, order, note);
  }

  Future<void> _promptNoShow(
    BuildContext context, {
    required int jobPostId,
    required int matchId,
  }) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노쇼 기록'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '사유 (선택)', filled: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('기록'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final reason = controller.text.trim().isEmpty
        ? null
        : controller.text.trim();
    await onRecordNoShow(jobPostId, matchId, reason);
  }

  CwmpWorkRecordResponse? _workRecordForMatch(int jobPostId, int matchId) {
    final records = workRecordsByJobPost[jobPostId] ?? const [];
    for (final record in records) {
      if (record.matchId == matchId) return record;
    }
    return null;
  }

  Future<void> _promptWorkRecordEditor(
    BuildContext context, {
    required CwmpJobPostResponse jobPost,
    required CwmpMatchSelectionResponse match,
  }) async {
    final existing = _workRecordForMatch(jobPost.id, match.id);
    final workDateController = TextEditingController(
      text: (existing?.workDate.trim().isNotEmpty ?? false)
          ? existing!.workDate
          : jobPost.workDate,
    );
    final workUnitsController = TextEditingController(
      text: (existing?.workUnits.toString() ?? '1.0').trim(),
    );
    final ratingController = TextEditingController(
      text: existing?.rating?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: (existing?.evaluationNote ?? '').trim(),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? '근무기록 입력' : '근무기록 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: workDateController,
                decoration: const InputDecoration(
                  labelText: '근무일 (YYYY-MM-DD)',
                  filled: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: workUnitsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '공수 (필수)',
                  hintText: '예: 1.0',
                  filled: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ratingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '평점 1~5 (선택)',
                  filled: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '평가 메모 (선택)',
                  filled: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final workDate = workDateController.text.trim();
    final workUnits = num.tryParse(workUnitsController.text.trim());
    final ratingText = ratingController.text.trim();
    final rating = ratingText.isEmpty ? null : int.tryParse(ratingText);
    final note = noteController.text.trim().isEmpty
        ? null
        : noteController.text.trim();

    if (workUnits == null || workUnits < 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공수는 0 이상의 숫자로 입력해주세요.')));
      return;
    }
    if (ratingText.isNotEmpty && (rating == null || rating < 1 || rating > 5)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('평점은 1~5 범위로 입력해주세요.')));
      return;
    }

    await onUpsertWorkRecord(
      jobPostId: jobPost.id,
      matchId: match.id,
      workDate: workDate.isEmpty ? null : workDate,
      workUnits: workUnits,
      rating: rating,
      evaluationNote: note,
    );
  }

  Future<void> _showNoShowSummary(BuildContext context, int userId) async {
    try {
      final summary = await onFetchNoShowSummary(userId);
      if (!context.mounted) return;
      final latest = summary.latestOccurredAt == null
          ? '-'
          : _formatDateTime(summary.latestOccurredAt!);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('노쇼 요약'),
          content: Text(
            '근로자 ID: $userId\n누적 노쇼: ${summary.count}회\n최근 발생: $latest',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('노쇼 요약 조회 실패: $e')));
    }
  }

  Future<void> _showWorkRecordDetail(
    BuildContext context, {
    required int matchId,
  }) async {
    try {
      final record = await onFetchWorkRecordDetail(matchId);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('근무기록 상세'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('근무일: ${record.workDate}'),
                Text('공수: ${record.workUnits}'),
                Text('정산상태: ${_workRecordStatusLabel(record.status)}'),
                Text('일당: ${record.dailyRate ?? '-'}'),
                Text('지급액: ${record.totalPay}'),
                Text('평점: ${record.rating ?? '-'}'),
                Text(
                  '메모: ${(record.evaluationNote ?? '').trim().isEmpty ? '-' : record.evaluationNote!.trim()}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('근무기록 상세 조회 실패: $e')));
    }
  }

  String _formatDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _workerLabel(CwmpMatchSelectionResponse match) {
    final name = workerNamesByUserId[match.workerId];
    if ((name ?? '').trim().isNotEmpty) {
      return 'Match #${match.id} · $name (#${match.workerId})';
    }
    return 'Match #${match.id} · Worker #${match.workerId}';
  }

  String _matchStatusFilterLabel(String value) {
    switch (value) {
      case 'APPLIED':
        return '지원';
      case 'PREFERRED':
        return '우선선발';
      case 'CONFIRMED':
        return '확정';
      case 'CANCELLED':
        return '취소';
      case 'NO_SHOW':
        return '노쇼';
      case 'ALL':
      default:
        return '전체';
    }
  }

  String _noShowFilterLabel(String value) {
    switch (value) {
      case 'HAS_NO_SHOW':
        return '노쇼 이력 있음';
      case 'NO_NO_SHOW':
        return '노쇼 이력 없음';
      case 'ALL':
      default:
        return '전체';
    }
  }

  String _workRecordFilterLabel(String value) {
    switch (value) {
      case 'NONE':
        return '없음';
      case 'CONFIRMED':
        return '확인';
      case 'REOPENED':
        return '재오픈';
      case 'SETTLED':
        return '정산완료';
      case 'ALL':
      default:
        return '전체';
    }
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> values,
    required String Function(String) labelOf,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 168,
      child: DropdownButtonFormField<String>(
        value: values.contains(value) ? value : values.first,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: values
            .map(
              (v) => DropdownMenuItem<String>(
                value: v,
                child: Text(labelOf(v), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  Widget _buildPendingRequestsCard(BuildContext context) {
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
              const Expanded(
                child: Text(
                  '승인 대기 공고 요청',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 8),
          if ((error ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
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
          if (pendingRequests.isEmpty)
            const Text(
              '승인 대기 공고 요청이 없습니다.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...pendingRequests.map((request) {
              final status =
                  request['status'] as JobRequestStatus? ??
                  JobRequestStatus.pending;
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
                    Text(
                      request['siteName']?.toString() ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _jobRequestSummary(request),
                      style: const TextStyle(color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '상태: ${MockBackend.jobStatusLabel(status)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: status == JobRequestStatus.approved
                              ? null
                              : () => _promptReject(
                                  context,
                                  request['id']?.toString() ?? '',
                                ),
                          child: const Text('반려'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: status == JobRequestStatus.approved
                              ? null
                              : () => _promptApprove(
                                  context,
                                  request['id']?.toString() ?? '',
                                  initialRegionCode:
                                      (request['regionCode']?.toString() ?? '')
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : request['regionCode']?.toString(),
                                ),
                          child: const Text('승인/발행'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPublishedPostsCard(BuildContext context) {
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
          const Text(
            '발행 공고 매칭 운영',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterDropdown(
                label: '매칭 상태',
                value: matchStatusFilter,
                values: const [
                  'ALL',
                  'APPLIED',
                  'PREFERRED',
                  'CONFIRMED',
                  'NO_SHOW',
                  'CANCELLED',
                ],
                labelOf: _matchStatusFilterLabel,
                onChanged: onMatchStatusFilterChanged,
              ),
              _buildFilterDropdown(
                label: '노쇼 이력',
                value: noShowFilter,
                values: const ['ALL', 'HAS_NO_SHOW', 'NO_NO_SHOW'],
                labelOf: _noShowFilterLabel,
                onChanged: onNoShowFilterChanged,
              ),
              _buildFilterDropdown(
                label: '근무기록 상태',
                value: workRecordStatusFilter,
                values: const [
                  'ALL',
                  'NONE',
                  'CONFIRMED',
                  'REOPENED',
                  'SETTLED',
                ],
                labelOf: _workRecordFilterLabel,
                onChanged: onWorkRecordStatusFilterChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (publishedJobPosts.isEmpty)
            const Text(
              '발행된 공고가 없습니다.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...publishedJobPosts.map((jobPost) {
              final matches = matchesByJobPost[jobPost.id];
              final isLoadingMatches = loadingMatchJobPostIds.contains(
                jobPost.id,
              );
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  title: Text(
                    jobPost.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${jobPost.siteName}\n${_jobPostSummary(jobPost)}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: isLoadingMatches
                            ? null
                            : () => onLoadMatches(jobPost.id),
                        icon: isLoadingMatches
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.group, size: 16),
                        label: Text(
                          matches == null ? '지원 목록 조회' : '지원 목록 새로고침',
                        ),
                      ),
                    ),
                    if (isLoadingMatches)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (matches == null)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '지원 목록 조회 버튼을 눌러 매칭 상태를 불러오세요.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    else if (matches.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '지원자가 없습니다.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    else
                      Column(
                        children: () {
                          final filteredMatches = matches.where((match) {
                            final status = match.status.toUpperCase();
                            if (matchStatusFilter != 'ALL' &&
                                status != matchStatusFilter) {
                              return false;
                            }
                            final cachedNoShow =
                                noShowSummaryByUserId[match.workerId];
                            final noShowCount = cachedNoShow?.count ?? 0;
                            if (noShowFilter == 'HAS_NO_SHOW' &&
                                noShowCount <= 0) {
                              return false;
                            }
                            if (noShowFilter == 'NO_NO_SHOW' &&
                                noShowCount > 0) {
                              return false;
                            }
                            final existingWorkRecord = _workRecordForMatch(
                              jobPost.id,
                              match.id,
                            );
                            if (workRecordStatusFilter == 'NONE') {
                              return existingWorkRecord == null;
                            }
                            if (workRecordStatusFilter != 'ALL') {
                              if (existingWorkRecord == null) return false;
                              if (existingWorkRecord.status.toUpperCase() !=
                                  workRecordStatusFilter) {
                                return false;
                              }
                            }
                            return true;
                          }).toList();
                          if (filteredMatches.isEmpty) {
                            return <Widget>[
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '필터 조건에 맞는 지원자가 없습니다.',
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ];
                          }
                          return filteredMatches.map((match) {
                            final statusColor = _matchStatusColor(match.status);
                            final status = match.status.toUpperCase();
                            final cachedNoShow =
                                noShowSummaryByUserId[match.workerId];
                            final existingWorkRecord = _workRecordForMatch(
                              jobPost.id,
                              match.id,
                            );
                            final canConfirm =
                                status != 'CONFIRMED' &&
                                status != 'NO_SHOW' &&
                                status != 'CANCELLED';
                            final canNoShow =
                                status != 'NO_SHOW' && status != 'CANCELLED';
                            final canEditWorkRecord = status == 'CONFIRMED';
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(_workerLabel(match)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: statusColor.withOpacity(
                                              0.35,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          _matchStatusLabel(match.status),
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
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (match.preferredHire) _chip('우선선발'),
                                      if (match.selectionOrder != null)
                                        _chip('순서 ${match.selectionOrder}'),
                                      if (existingWorkRecord != null)
                                        _chip('근무기록 있음'),
                                      if (existingWorkRecord != null)
                                        _chip(
                                          '${existingWorkRecord.workDate} · ${existingWorkRecord.workUnits}공수',
                                        ),
                                      if (existingWorkRecord != null)
                                        (() {
                                          final colors =
                                              _workRecordStatusColors(
                                                existingWorkRecord.status,
                                              );
                                          return _chip(
                                            '정산상태 ${_workRecordStatusLabel(existingWorkRecord.status)}',
                                            bg: colors.bg,
                                            border: colors.border,
                                            fg: colors.fg,
                                          );
                                        })(),
                                      if (cachedNoShow != null)
                                        _chip('노쇼 ${cachedNoShow.count}회'),
                                      if ((match.note ?? '').trim().isNotEmpty)
                                        _chip('메모: ${match.note!.trim()}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _promptPrioritize(
                                          context,
                                          jobPostId: jobPost.id,
                                          matchId: match.id,
                                        ),
                                        child: const Text('우선선발'),
                                      ),
                                      ElevatedButton(
                                        onPressed: canConfirm
                                            ? () => onConfirmMatch(
                                                jobPost.id,
                                                match.id,
                                              )
                                            : null,
                                        child: const Text('확정'),
                                      ),
                                      OutlinedButton(
                                        onPressed: canEditWorkRecord
                                            ? () => _promptWorkRecordEditor(
                                                context,
                                                jobPost: jobPost,
                                                match: match,
                                              )
                                            : null,
                                        child: Text(
                                          existingWorkRecord == null
                                              ? '근무기록 입력'
                                              : '근무기록 수정',
                                        ),
                                      ),
                                      OutlinedButton(
                                        onPressed: existingWorkRecord == null
                                            ? null
                                            : () => _showWorkRecordDetail(
                                                context,
                                                matchId: match.id,
                                              ),
                                        child: const Text('기록 상세'),
                                      ),
                                      OutlinedButton(
                                        onPressed: canNoShow
                                            ? () => _promptNoShow(
                                                context,
                                                jobPostId: jobPost.id,
                                                matchId: match.id,
                                              )
                                            : null,
                                        child: const Text('노쇼 기록'),
                                      ),
                                      TextButton(
                                        onPressed: () => _showNoShowSummary(
                                          context,
                                          match.workerId,
                                        ),
                                        child: const Text('노쇼 요약'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        }(),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _chip(
    String text, {
    Color bg = const Color(0xFFEFF6FF),
    Color border = const Color(0xFFBFDBFE),
    Color fg = const Color(0xFF1D4ED8),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPendingRequestsCard(context),
        const SizedBox(height: 12),
        _buildPublishedPostsCard(context),
      ],
    );
  }
}
