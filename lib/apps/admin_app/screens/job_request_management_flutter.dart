import 'package:flutter/material.dart';
import '../../../data/mock_backend.dart';

class JobRequestManagementFlutter extends StatelessWidget {
  const JobRequestManagementFlutter({
    super.key,
    required this.requests,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onAssignPriority,
    required this.onAssignSequence,
    required this.onResetAssignments,
    required this.onConfirmApplicantPriority,
    required this.onConfirmApplicantSequence,
  });

  final List<Map<String, dynamic>> requests;
  final ValueChanged<String> onApprove;
  final void Function(String id, String reason) onReject;
  final void Function(String id, Map<String, dynamic> updates) onEdit;
  final ValueChanged<String> onAssignPriority;
  final ValueChanged<String> onAssignSequence;
  final ValueChanged<String> onResetAssignments;
  final void Function(String jobId, String phone) onConfirmApplicantPriority;
  final void Function(String jobId, String phone) onConfirmApplicantSequence;

  Color _statusColor(JobRequestStatus status) {
    switch (status) {
      case JobRequestStatus.approved:
        return const Color(0xFF16A34A);
      case JobRequestStatus.rejected:
        return const Color(0xFFDC2626);
      case JobRequestStatus.pending:
        return const Color(0xFF2563EB);
    }
  }

  Future<void> _openRejectDialog(BuildContext context, Map<String, dynamic> request) async {
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
    onReject(request['id'] as String, reason);
  }

  Future<void> _openEditDialog(BuildContext context, Map<String, dynamic> request) async {
    final dateController = TextEditingController(text: request['date']?.toString() ?? '');
    final timeController = TextEditingController(text: request['time']?.toString() ?? '');
    final countController = TextEditingController(text: request['count']?.toString() ?? '');
    final rateController = TextEditingController(text: request['rate']?.toString() ?? '');
    final meetingController = TextEditingController(text: request['meetingPoint']?.toString() ?? '');
    final notesController = TextEditingController(text: request['notes']?.toString() ?? '');
    final memoController = TextEditingController(text: request['memo']?.toString() ?? '');
    final adminNoteController = TextEditingController(text: request['adminNote']?.toString() ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공고 요청 편집'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: '근무일', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: '근무 시간', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '인원', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '단가', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: meetingController,
                decoration: const InputDecoration(labelText: '집결지', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: '특이사항', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: memoController,
                decoration: const InputDecoration(labelText: '구인자 메모', filled: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: adminNoteController,
                decoration: const InputDecoration(labelText: '관리자 메모', filled: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('저장')),
        ],
      ),
    );
    if (confirmed != true) return;
    final count = int.tryParse(countController.text.trim()) ?? request['count'];
    onEdit(request['id'] as String, {
      'date': dateController.text.trim(),
      'time': timeController.text.trim(),
      'count': count,
      'rate': rateController.text.trim(),
      'meetingPoint': meetingController.text.trim(),
      'notes': notesController.text.trim(),
      'memo': memoController.text.trim(),
      'adminNote': adminNoteController.text.trim().isEmpty ? null : adminNoteController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(
        child: Text('공고 요청이 없습니다.', style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = requests[index];
        final status = request['status'] as JobRequestStatus? ?? JobRequestStatus.pending;
        final statusText = MockBackend.jobStatusLabel(status);
        final statusColor = _statusColor(status);
        final rejectReason = request['rejectReason']?.toString();
        final adminNote = request['adminNote']?.toString();
        final assignedPriority = List<String>.from(request['assignedPriority'] as List? ?? []);
        final assignedSequence = List<String>.from(request['assignedSequence'] as List? ?? []);
        final assignedCount = MockBackend.assignedCountForJob(request);
        final remainingCount = MockBackend.remainingCountForJob(request);
        final applicants = MockBackend.applicantsForJob(request['id'] as String);
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
                      request['siteName']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${request['date']} · ${request['time']} · ${request['jobType']} ${request['count']}명',
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 4),
              Text('단가 ${request['rate']}원', style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              Text('집결지: ${request['meetingPoint']}', style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text('특이사항: ${request['notes']}', style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text('구인자 메모: ${request['memo']}', style: const TextStyle(color: Color(0xFF94A3B8))),
              if (adminNote != null && adminNote.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('관리자 메모: $adminNote', style: const TextStyle(color: Color(0xFF64748B))),
              ],
              if (rejectReason != null && rejectReason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('반려 사유: $rejectReason', style: const TextStyle(color: Color(0xFFB91C1C))),
              ],
              const SizedBox(height: 10),
              Text('지원자 ${applicants.length}명', style: const TextStyle(color: Color(0xFF64748B))),
              if (applicants.isEmpty)
                const Text('지원자가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))
              else
                Column(
                  children: applicants.map((applicant) {
                    final name = applicant['name']?.toString() ?? '-';
                    final phone = applicant['phone']?.toString() ?? '-';
                    final applicantStatus =
                        applicant['status'] as ApplicantStatus? ?? ApplicantStatus.applied;
                    final isConfirmed = applicantStatus == ApplicantStatus.confirmed;
                    final statusChipColor =
                        isConfirmed ? const Color(0xFF16A34A) : const Color(0xFF2563EB);
                    final alreadyAssigned = assignedPriority.contains(name) || assignedSequence.contains(name);
                    final canConfirm = !isConfirmed &&
                        status == JobRequestStatus.approved &&
                        (remainingCount > 0 || alreadyAssigned);
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('$name · $phone')),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusChipColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: statusChipColor.withOpacity(0.4)),
                                ),
                                child: Text(
                                  isConfirmed ? '확정' : '지원',
                                  style: TextStyle(
                                    color: statusChipColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isConfirmed) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: canConfirm
                                      ? () => onConfirmApplicantPriority(request['id'] as String, phone)
                                      : null,
                                  child: const Text('우선 확정'),
                                ),
                                OutlinedButton(
                                  onPressed: canConfirm
                                      ? () => onConfirmApplicantSequence(request['id'] as String, phone)
                                      : null,
                                  child: const Text('순차 확정'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (status == JobRequestStatus.approved) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('채용 운영', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('우선 배정 ${assignedPriority.length}명 · 순차 배정 ${assignedSequence.length}명'),
                      Text('잔여 인원 $remainingCount명', style: const TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: remainingCount <= 0 ? null : () => onAssignPriority(request['id'] as String),
                            child: const Text('우선 배정 +1'),
                          ),
                          OutlinedButton(
                            onPressed: remainingCount <= 0 ? null : () => onAssignSequence(request['id'] as String),
                            child: const Text('순차 배정 +1'),
                          ),
                          TextButton(
                            onPressed: assignedCount == 0 ? null : () => onResetAssignments(request['id'] as String),
                            child: const Text('배정 초기화'),
                          ),
                        ],
                      ),
                      if (assignedPriority.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('우선 배정 인력', style: TextStyle(color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: assignedPriority
                              .map((name) => Chip(
                                    label: Text(name),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                  ))
                              .toList(),
                        ),
                      ],
                      if (assignedSequence.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('순차 배정 인력', style: TextStyle(color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: assignedSequence
                              .map((name) => Chip(
                                    label: Text(name),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _openEditDialog(context, request),
                    child: const Text('편집'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: status == JobRequestStatus.approved
                        ? null
                        : () => _openRejectDialog(context, request),
                    child: const Text('반려'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: status == JobRequestStatus.approved ? null : () => onApprove(request['id'] as String),
                    child: const Text('승인'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
