import 'dart:convert';
import 'dart:math';

class AttendanceQrPayload {
  AttendanceQrPayload({
    required this.siteName,
    required this.issuedAt,
    required this.expiresAt,
    required this.token,
  });

  final String siteName;
  final int issuedAt;
  final int expiresAt;
  final String token;

  factory AttendanceQrPayload.create({
    required String siteName,
    Duration validFor = const Duration(minutes: 10),
  }) {
    final now = DateTime.now();
    final expires = now.add(validFor);
    return AttendanceQrPayload(
      siteName: siteName,
      issuedAt: now.millisecondsSinceEpoch,
      expiresAt: expires.millisecondsSinceEpoch,
      token: _randomToken(16),
    );
  }

  static AttendanceQrPayload? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final siteName = decoded['site']?.toString() ?? '';
      final issuedAt = int.tryParse(decoded['issuedAt']?.toString() ?? '');
      final expiresAt = int.tryParse(decoded['expiresAt']?.toString() ?? '');
      final token = decoded['token']?.toString() ?? '';
      if (siteName.isEmpty || issuedAt == null || expiresAt == null || token.isEmpty) {
        return null;
      }
      return AttendanceQrPayload(
        siteName: siteName,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  String encode() {
    return jsonEncode({
      'site': siteName,
      'issuedAt': issuedAt,
      'expiresAt': expiresAt,
      'token': token,
    });
  }

  DateTime get issuedAtDate => DateTime.fromMillisecondsSinceEpoch(issuedAt);
  DateTime get expiresAtDate => DateTime.fromMillisecondsSinceEpoch(expiresAt);

  bool isValidAt(DateTime now) {
    final issued = issuedAtDate;
    final expires = expiresAtDate;
    if (!_isSameDay(issued, now)) return false;
    if (now.isBefore(issued)) return false;
    if (now.isAfter(expires)) return false;
    return true;
  }
}

String formatDateTime(DateTime dateTime) {
  return '${dateTime.year}.${_two(dateTime.month)}.${_two(dateTime.day)} '
      '${_two(dateTime.hour)}:${_two(dateTime.minute)}';
}

String formatTime(DateTime dateTime) {
  return '${_two(dateTime.hour)}:${_two(dateTime.minute)}';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _randomToken(int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < length; i += 1) {
    buffer.write(chars[random.nextInt(chars.length)]);
  }
  return buffer.toString();
}

String _two(int value) => value.toString().padLeft(2, '0');
