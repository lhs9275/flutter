import 'cwmp_api_models.dart';
import 'mock_backend.dart';

class CwmpEmployerAppAdapter {
  static Map<String, dynamic> toSiteMap(CwmpConstructionSiteResponse site) {
    final businessInfo = (site.businessInfo ?? '').trim();
    final parsedJobType = _extractLabeledValue(businessInfo, '직종');
    final parsedBizNumber = _extractLabeledValue(businessInfo, '사업자번호');
    final parsedMemo = _extractLabeledValue(businessInfo, '메모');
    return {
      'source': 'cwmp',
      'id': site.id.toString(),
      'name': site.siteName,
      'address': site.address,
      'region': _regionFromAddress(site.address),
      'jobType': (parsedJobType?.isNotEmpty ?? false) ? parsedJobType : '-',
      'status': _siteStatus(site.approvalStatus),
      'createdAt': _formatDateTime(site.approvedAt) ?? '-',
      'lat': site.latitude,
      'lng': site.longitude,
      'phoneVerified': site.approvalStatus.toUpperCase() == 'APPROVED',
      'bizName': (parsedMemo?.isNotEmpty ?? false)
          ? parsedMemo
          : (businessInfo.isEmpty ? '-' : businessInfo),
      'bizNumber': (parsedBizNumber?.isNotEmpty ?? false)
          ? parsedBizNumber
          : '-',
      'representative': site.contactName,
      'bizPhone': site.contactPhone,
      'agentName': site.contactName,
      'agentPhone': site.contactPhone,
      'rejectReason': site.rejectionReason,
    };
  }

  static Map<String, dynamic> toJobRequestMap(CwmpJobRequestResponse request) {
    return {
      'source': 'cwmp',
      'id': request.id.toString(),
      'siteId': request.siteId.toString(),
      'jobPostId': request.jobPostId,
      'siteName': request.siteName,
      'date': request.workDate,
      'time': _formatTime(request.startTime),
      'jobType': request.trade.isEmpty ? '-' : request.trade,
      'count': request.headcount,
      'rate': request.dailyRate == null
          ? '-'
          : _formatMoney(request.dailyRate!),
      'meetingPoint': (request.gatheringAddress?.trim().isNotEmpty ?? false)
          ? request.gatheringAddress!.trim()
          : '-',
      'notes': (request.requirements?.trim().isNotEmpty ?? false)
          ? request.requirements!.trim()
          : '-',
      'memo': (request.employerMemo?.trim().isNotEmpty ?? false)
          ? request.employerMemo!.trim()
          : '-',
      'status': _jobRequestStatus(request.status),
      'createdAt': '-',
      'adminNote': null,
      'rejectReason': null,
      'assignedPriority': <String>[],
      'assignedSequence': <String>[],
      'applicants': <Map<String, dynamic>>[],
    };
  }

  static int? siteIdFromMap(Map<String, dynamic> site) {
    final raw = site['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static SiteStatus _siteStatus(String value) {
    switch (value.trim().toUpperCase()) {
      case 'APPROVED':
        return SiteStatus.approved;
      case 'REJECTED':
        return SiteStatus.rejected;
      case 'REQUESTED':
      default:
        return SiteStatus.pending;
    }
  }

  static JobRequestStatus _jobRequestStatus(String value) {
    switch (value.trim().toUpperCase()) {
      case 'APPROVED':
        return JobRequestStatus.approved;
      case 'REJECTED':
        return JobRequestStatus.rejected;
      case 'REQUESTED':
      default:
        return JobRequestStatus.pending;
    }
  }

  static String _regionFromAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '기타';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static String _formatTime(String? hhmmss) {
    final raw = hhmmss?.trim() ?? '';
    if (raw.isEmpty) return '-';
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return raw;
  }

  static String _formatMoney(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i += 1) {
      final indexFromEnd = text.length - i;
      buffer.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  static String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  static String? _extractLabeledValue(String text, String label) {
    if (text.trim().isEmpty) return null;
    final pattern = RegExp('^${RegExp.escape(label)}\\s*:\\s*(.+)\$');
    for (final line in text.split('\n')) {
      final match = pattern.firstMatch(line.trim());
      if (match == null) continue;
      final value = (match.group(1) ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }
}
