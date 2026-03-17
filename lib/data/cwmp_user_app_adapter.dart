import 'cwmp_api_models.dart';
import '../apps/user_app/data/region_code_catalog.dart';

class CwmpUserAppAdapter {
  static Map<String, dynamic> toSiteMap(CwmpJobPostResponse post) {
    final siteName = post.siteName.trim().isEmpty ? post.title : post.siteName;
    final siteAddress = post.siteAddress.trim().isEmpty ? '-' : post.siteAddress;
    return {
      'source': 'cwmp',
      'id': post.id.toString(),
      'cwmpJobPostId': post.id,
      'siteId': post.id.toString(),
      if (post.siteId != null) 'cwmpSiteId': post.siteId,
      'name': siteName,
      'address': siteAddress,
      'region': _resolveRegionLabel(post),
      // Backend JobPostResponse has no explicit trade field in current spec.
      'type': post.title,
      'date': post.workDate,
      'time': _formatTime(post.startTime),
      'count': post.headcount,
      'pay': post.dailyRate == null ? '-' : _formatMoney(post.dailyRate!),
      'meetingPoint': siteAddress,
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
    final inferredCode = _inferRegionCodeFromAddress(post.siteAddress);
    if (inferredCode != null) return inferredCode;
    final address = post.siteAddress.trim();
    if (address.isEmpty) return '기타';
    return address.split(RegExp(r'\s+')).first;
  }

  static String? _inferRegionCodeFromAddress(String address) {
    final normalizedAddress = _normalizeRegionText(address);
    if (normalizedAddress.isEmpty) return null;

    PreferredRegionOption? bestMatch;
    var bestMatchLength = -1;
    for (final option in preferredRegionCatalog) {
      final normalizedOption = _normalizeRegionText(option.name);
      if (normalizedOption.isEmpty) continue;
      if (!normalizedAddress.startsWith(normalizedOption)) continue;
      if (normalizedOption.length <= bestMatchLength) continue;
      bestMatch = option;
      bestMatchLength = normalizedOption.length;
    }
    return bestMatch?.code;
  }

  static String _normalizeRegionText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
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
