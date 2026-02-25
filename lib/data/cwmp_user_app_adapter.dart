import 'cwmp_api_models.dart';

class CwmpUserAppAdapter {
  static Map<String, dynamic> toSiteMap(CwmpJobPostResponse post) {
    return {
      'source': 'cwmp',
      'id': post.id.toString(),
      'cwmpJobPostId': post.id,
      'siteId': post.id.toString(),
      if (post.siteId != null) 'cwmpSiteId': post.siteId,
      'name': post.siteName,
      'address': post.siteAddress,
      'region': _resolveRegionLabel(post),
      // Backend JobPostResponse has no explicit trade field in current spec.
      'type': post.title,
      'date': post.workDate,
      'time': _formatTime(post.startTime),
      'count': post.headcount,
      'pay': post.dailyRate == null ? '-' : _formatMoney(post.dailyRate!),
      'meetingPoint': post.siteAddress,
      'notes': (post.requirements?.trim().isNotEmpty ?? false)
          ? post.requirements!.trim()
          : (post.description?.trim().isNotEmpty ?? false)
          ? post.description!.trim()
          : '-',
      'contact': '-',
      'lat': post.siteLatitude,
      'lng': post.siteLongitude,
      'memo': post.description ?? '',
      'status': post.status,
    };
  }

  static int? jobPostIdFromSite(Map<String, dynamic> site) {
    final direct = site['cwmpJobPostId'];
    if (direct is int) return direct;
    if (direct is num) return direct.toInt();
    if (direct != null) return int.tryParse(direct.toString());

    final id = site['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    if (id == null) return null;
    return int.tryParse(id.toString());
  }

  static String _resolveRegionLabel(CwmpJobPostResponse post) {
    final code = post.regionCode?.trim() ?? '';
    if (code.isNotEmpty) return code;
    final address = post.siteAddress.trim();
    if (address.isEmpty) return '기타';
    return address.split(RegExp(r'\s+')).first;
  }

  static String _formatTime(String? hhmmss) {
    if (hhmmss == null || hhmmss.trim().isEmpty) return '-';
    final raw = hhmmss.trim();
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return raw;
  }

  static String _formatMoney(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i += 1) {
      final indexFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}
