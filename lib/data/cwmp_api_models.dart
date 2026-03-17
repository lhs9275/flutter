class CwmpApiException implements Exception {
  const CwmpApiException({
    required this.message,
    this.statusCode,
    this.rawBody,
  });

  final String message;
  final int? statusCode;
  final String? rawBody;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' [$statusCode]';
    return 'CwmpApiException$code: $message';
  }
}

enum CwmpUserRole { worker, employer, admin }

extension CwmpUserRoleX on CwmpUserRole {
  String get apiValue {
    switch (this) {
      case CwmpUserRole.worker:
        return 'WORKER';
      case CwmpUserRole.employer:
        return 'EMPLOYER';
      case CwmpUserRole.admin:
        return 'ADMIN';
    }
  }

  static CwmpUserRole fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'EMPLOYER':
        return CwmpUserRole.employer;
      case 'ADMIN':
        return CwmpUserRole.admin;
      case 'WORKER':
      default:
        return CwmpUserRole.worker;
    }
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, dynamic entryValue) => MapEntry(key.toString(), entryValue),
    );
  }
  return null;
}

String _firstNonEmptyString(
  Iterable<dynamic> values, {
  String fallback = '',
}) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

String? _firstNullableString(Iterable<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int? _firstInt(Iterable<dynamic> values) {
  for (final value in values) {
    final parsed = _asInt(value);
    if (parsed != null) return parsed;
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double? _firstDouble(Iterable<dynamic> values) {
  for (final value in values) {
    final parsed = _asDouble(value);
    if (parsed != null) return parsed;
  }
  return null;
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == 'y' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == 'n' || normalized == '0') {
    return false;
  }
  return fallback;
}

class CwmpPhoneAuthPendingResponse {
  const CwmpPhoneAuthPendingResponse({
    required this.phoneNumber,
    required this.expiresAt,
    required this.sessionToken,
    required this.deliveryMethod,
    required this.deliveryStatus,
    this.failureReason,
    this.debugCode,
  });

  final String phoneNumber;
  final DateTime? expiresAt;
  final String sessionToken;
  final String deliveryMethod;
  final String deliveryStatus;
  final String? failureReason;
  final String? debugCode;

  factory CwmpPhoneAuthPendingResponse.fromJson(Map<String, dynamic> json) {
    return CwmpPhoneAuthPendingResponse(
      phoneNumber: _asString(json['phoneNumber']),
      expiresAt: DateTime.tryParse(_asString(json['expiresAt'])),
      sessionToken: _asString(json['sessionToken']),
      deliveryMethod: _asString(json['deliveryMethod']),
      deliveryStatus: _asString(json['deliveryStatus']),
      failureReason: json['failureReason']?.toString(),
      debugCode: json['debugCode']?.toString(),
    );
  }
}

class CwmpAuthUser {
  const CwmpAuthUser({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.role,
    required this.phoneVerified,
  });

  final int id;
  final String phoneNumber;
  final String? name;
  final CwmpUserRole role;
  final bool phoneVerified;

  factory CwmpAuthUser.fromJson(Map<String, dynamic> json) {
    return CwmpAuthUser(
      id: _asInt(json['id']) ?? 0,
      phoneNumber: _asString(json['phoneNumber']),
      name: json['name']?.toString(),
      role: CwmpUserRoleX.fromApi(_asString(json['role'], fallback: 'WORKER')),
      phoneVerified: _asBool(json['phoneVerified']),
    );
  }
}

class CwmpAuthTokens {
  const CwmpAuthTokens({
    required this.tokenType,
    required this.accessToken,
    required this.accessTokenExpiresIn,
    required this.refreshToken,
    required this.refreshTokenExpiresIn,
  });

  final String tokenType;
  final String accessToken;
  final int accessTokenExpiresIn;
  final String refreshToken;
  final int refreshTokenExpiresIn;

  factory CwmpAuthTokens.fromJson(Map<String, dynamic> json) {
    return CwmpAuthTokens(
      tokenType: _asString(json['token_type'], fallback: 'Bearer'),
      accessToken: _asString(json['access_token']),
      accessTokenExpiresIn: _asInt(json['access_token_expires_in']) ?? 0,
      refreshToken: _asString(json['refresh_token']),
      refreshTokenExpiresIn: _asInt(json['refresh_token_expires_in']) ?? 0,
    );
  }
}

class CwmpPhoneAuthLoginResponse {
  const CwmpPhoneAuthLoginResponse({
    required this.user,
    required this.tokens,
    required this.firstLogin,
    required this.sessionToken,
  });

  final CwmpAuthUser user;
  final CwmpAuthTokens tokens;
  final bool firstLogin;
  final String sessionToken;

  factory CwmpPhoneAuthLoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = Map<String, dynamic>.from(
      json['user'] as Map? ?? const {},
    );
    final tokensJson = Map<String, dynamic>.from(
      json['tokens'] as Map? ?? const {},
    );
    return CwmpPhoneAuthLoginResponse(
      user: CwmpAuthUser.fromJson(userJson),
      tokens: CwmpAuthTokens.fromJson(tokensJson),
      firstLogin: _asBool(json['firstLogin']),
      sessionToken: _asString(json['sessionToken']),
    );
  }
}

class CwmpJobPostResponse {
  const CwmpJobPostResponse({
    required this.id,
    required this.siteId,
    required this.title,
    required this.description,
    required this.workDate,
    required this.startTime,
    required this.headcount,
    required this.dailyRate,
    required this.requirements,
    required this.regionCode,
    required this.status,
    required this.siteName,
    required this.siteAddress,
    required this.siteLatitude,
    required this.siteLongitude,
  });

  final int id;
  final int? siteId;
  final String title;
  final String? description;
  final String workDate;
  final String? startTime;
  final int headcount;
  final int? dailyRate;
  final String? requirements;
  final String? regionCode;
  final String status;
  final String siteName;
  final String siteAddress;
  final double? siteLatitude;
  final double? siteLongitude;

  factory CwmpJobPostResponse.fromJson(Map<String, dynamic> json) {
    final nestedSiteJson =
        _asJsonMap(json['site']) ??
        _asJsonMap(json['constructionSite']) ??
        _asJsonMap(json['construction_site']);
    return CwmpJobPostResponse(
      id: _asInt(json['id']) ?? 0,
      siteId: _firstInt([
        json['siteId'],
        json['site_id'],
        json['constructionSiteId'],
        json['construction_site_id'],
        nestedSiteJson?['id'],
      ]),
      title: _firstNonEmptyString([
        json['title'],
        json['jobTitle'],
        json['job_title'],
      ]),
      description: _firstNullableString([
        json['description'],
        json['content'],
      ]),
      workDate: _firstNonEmptyString([
        json['workDate'],
        json['work_date'],
        json['date'],
      ]),
      startTime: _firstNullableString([
        json['startTime'],
        json['start_time'],
      ]),
      headcount:
          _firstInt([
            json['headcount'],
            json['head_count'],
            json['count'],
          ]) ??
          0,
      dailyRate: _firstInt([
        json['dailyRate'],
        json['daily_rate'],
        json['pay'],
      ]),
      requirements: _firstNullableString([
        json['requirements'],
        json['requirement'],
      ]),
      regionCode: _firstNullableString([
        json['regionCode'],
        json['region_code'],
        nestedSiteJson?['regionCode'],
        nestedSiteJson?['region_code'],
      ]),
      status: _firstNonEmptyString([
        json['status'],
        json['approvalStatus'],
        json['approval_status'],
      ]),
      siteName: _firstNonEmptyString([
        json['siteName'],
        json['site_name'],
        json['constructionSiteName'],
        json['construction_site_name'],
        nestedSiteJson?['siteName'],
        nestedSiteJson?['site_name'],
        nestedSiteJson?['name'],
      ]),
      siteAddress: _firstNonEmptyString([
        json['siteAddress'],
        json['site_address'],
        json['address'],
        nestedSiteJson?['siteAddress'],
        nestedSiteJson?['site_address'],
        nestedSiteJson?['address'],
      ]),
      siteLatitude: _firstDouble([
        json['siteLatitude'],
        json['site_latitude'],
        nestedSiteJson?['latitude'],
        nestedSiteJson?['lat'],
      ]),
      siteLongitude: _firstDouble([
        json['siteLongitude'],
        json['site_longitude'],
        nestedSiteJson?['longitude'],
        nestedSiteJson?['lng'],
      ]),
    );
  }
}

class CwmpMatchSelectionResponse {
  const CwmpMatchSelectionResponse({
    required this.id,
    required this.jobPostId,
    required this.workerId,
    required this.status,
    required this.preferredHire,
    required this.selectionOrder,
    required this.note,
  });

  final int id;
  final int jobPostId;
  final int workerId;
  final String status;
  final bool preferredHire;
  final int? selectionOrder;
  final String? note;

  factory CwmpMatchSelectionResponse.fromJson(Map<String, dynamic> json) {
    return CwmpMatchSelectionResponse(
      id: _asInt(json['id']) ?? 0,
      jobPostId: _asInt(json['jobPostId']) ?? 0,
      workerId: _asInt(json['workerId']) ?? 0,
      status: _asString(json['status']),
      preferredHire: _asBool(json['preferredHire']),
      selectionOrder: _asInt(json['selectionOrder']),
      note: json['note']?.toString(),
    );
  }
}

class CwmpConstructionSiteResponse {
  const CwmpConstructionSiteResponse({
    required this.id,
    required this.siteName,
    required this.projectName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
    required this.businessInfo,
    required this.regionCode,
    required this.approvalStatus,
    required this.approvedAt,
    required this.rejectionReason,
  });

  final int id;
  final String siteName;
  final String? projectName;
  final String address;
  final double? latitude;
  final double? longitude;
  final String contactName;
  final String contactPhone;
  final String? businessInfo;
  final String? regionCode;
  final String approvalStatus;
  final DateTime? approvedAt;
  final String? rejectionReason;

  factory CwmpConstructionSiteResponse.fromJson(Map<String, dynamic> json) {
    return CwmpConstructionSiteResponse(
      id: _asInt(json['id']) ?? 0,
      siteName: _asString(json['siteName']),
      projectName: json['projectName']?.toString(),
      address: _asString(json['address']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      contactName: _asString(json['contactName']),
      contactPhone: _asString(json['contactPhone']),
      businessInfo: json['businessInfo']?.toString(),
      regionCode: json['regionCode']?.toString(),
      approvalStatus: _asString(json['approvalStatus']),
      approvedAt: DateTime.tryParse(_asString(json['approvedAt'])),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

class CwmpJobRequestResponse {
  const CwmpJobRequestResponse({
    required this.id,
    required this.siteId,
    required this.jobPostId,
    required this.siteName,
    required this.workDate,
    required this.startTime,
    required this.trade,
    required this.headcount,
    required this.dailyRate,
    required this.gatheringAddress,
    required this.requirements,
    required this.employerMemo,
    required this.status,
  });

  final int id;
  final int siteId;
  final int? jobPostId;
  final String siteName;
  final String workDate;
  final String? startTime;
  final String trade;
  final int headcount;
  final int? dailyRate;
  final String? gatheringAddress;
  final String? requirements;
  final String? employerMemo;
  final String status;

  factory CwmpJobRequestResponse.fromJson(Map<String, dynamic> json) {
    return CwmpJobRequestResponse(
      id: _asInt(json['id']) ?? 0,
      siteId: _asInt(json['siteId']) ?? 0,
      jobPostId: _asInt(json['jobPostId']) ?? _asInt(json['job_post_id']),
      siteName: _asString(json['siteName']),
      workDate: _asString(json['workDate']),
      startTime: json['startTime']?.toString(),
      trade: _asString(json['trade']),
      headcount: _asInt(json['headcount']) ?? 0,
      dailyRate: _asInt(json['dailyRate']),
      gatheringAddress: json['gatheringAddress']?.toString(),
      requirements: json['requirements']?.toString(),
      employerMemo: json['employerMemo']?.toString(),
      status: _asString(json['status']),
    );
  }
}

class CwmpPreferenceRegionItem {
  const CwmpPreferenceRegionItem({
    required this.regionCode,
    this.regionName,
    this.priority,
    this.latitude,
    this.longitude,
  });

  final String regionCode;
  final String? regionName;
  final int? priority;
  final double? latitude;
  final double? longitude;

  factory CwmpPreferenceRegionItem.fromJson(Map<String, dynamic> json) {
    return CwmpPreferenceRegionItem(
      regionCode: _asString(json['regionCode']),
      regionName: json['regionName']?.toString(),
      priority: _asInt(json['priority']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'regionCode': regionCode,
      if (regionName != null) 'regionName': regionName,
      if (priority != null) 'priority': priority,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

class CwmpWorkRecordResponse {
  const CwmpWorkRecordResponse({
    required this.id,
    required this.matchId,
    required this.jobPostId,
    required this.workerId,
    required this.workerName,
    required this.workDate,
    required this.workUnits,
    required this.dailyRate,
    required this.totalPay,
    required this.rating,
    required this.evaluationNote,
    required this.status,
  });

  final int id;
  final int matchId;
  final int jobPostId;
  final int workerId;
  final String workerName;
  final String workDate;
  final num workUnits;
  final int? dailyRate;
  final num totalPay;
  final int? rating;
  final String? evaluationNote;
  final String status;

  factory CwmpWorkRecordResponse.fromJson(Map<String, dynamic> json) {
    return CwmpWorkRecordResponse(
      id: _asInt(json['id']) ?? 0,
      matchId: _asInt(json['matchId']) ?? 0,
      jobPostId: _asInt(json['jobPostId']) ?? 0,
      workerId: _asInt(json['workerId']) ?? 0,
      workerName: _asString(json['workerName']),
      workDate: _asString(json['workDate']),
      workUnits: _asNum(json['workUnits']) ?? 0,
      dailyRate: _asInt(json['dailyRate']),
      totalPay: _asNum(json['totalPay']) ?? 0,
      rating: _asInt(json['rating']),
      evaluationNote: json['evaluationNote']?.toString(),
      status: _asString(json['status']),
    );
  }
}

class CwmpWorkRecordSummaryResponse {
  const CwmpWorkRecordSummaryResponse({
    required this.totalUnits,
    required this.totalPay,
    required this.records,
  });

  final num totalUnits;
  final num totalPay;
  final List<CwmpWorkRecordResponse> records;

  factory CwmpWorkRecordSummaryResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['records'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => CwmpWorkRecordResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
    return CwmpWorkRecordSummaryResponse(
      totalUnits: _asNum(json['totalUnits']) ?? 0,
      totalPay: _asNum(json['totalPay']) ?? 0,
      records: list,
    );
  }
}

class CwmpNotificationResponse {
  const CwmpNotificationResponse({
    required this.id,
    required this.title,
    required this.content,
    required this.emergency,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String content;
  final String emergency;
  final int userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isEmergency => emergency.toUpperCase() == 'Y';

  factory CwmpNotificationResponse.fromJson(Map<String, dynamic> json) {
    return CwmpNotificationResponse(
      id: _asInt(json['id']) ?? 0,
      title: _asString(json['title']),
      content: _asString(json['content']),
      emergency: _asString(json['emergency'], fallback: 'N'),
      userId: _asInt(json['userId']) ?? 0,
      createdAt: DateTime.tryParse(_asString(json['createdAt'])),
      updatedAt: DateTime.tryParse(_asString(json['updatedAt'])),
    );
  }
}

class CwmpNoShowSummaryResponse {
  const CwmpNoShowSummaryResponse({
    required this.count,
    required this.latestOccurredAt,
  });

  final int count;
  final DateTime? latestOccurredAt;

  factory CwmpNoShowSummaryResponse.fromJson(Map<String, dynamic> json) {
    return CwmpNoShowSummaryResponse(
      count: _asInt(json['count']) ?? 0,
      latestOccurredAt: DateTime.tryParse(_asString(json['latestOccurredAt'])),
    );
  }
}

class CwmpSiteNavigationLinksResponse {
  const CwmpSiteNavigationLinksResponse({this.naver, this.kakao, this.tmap});

  final String? naver;
  final String? kakao;
  final String? tmap;

  bool get hasAnyLink =>
      (naver ?? '').trim().isNotEmpty ||
      (kakao ?? '').trim().isNotEmpty ||
      (tmap ?? '').trim().isNotEmpty;

  factory CwmpSiteNavigationLinksResponse.fromJson(Map<String, dynamic> json) {
    return CwmpSiteNavigationLinksResponse(
      naver: json['naver']?.toString(),
      kakao: json['kakao']?.toString(),
      tmap: json['tmap']?.toString(),
    );
  }
}

class CwmpAttendanceCheckResponse {
  const CwmpAttendanceCheckResponse({
    required this.id,
    required this.workerId,
    required this.jobPostId,
    required this.siteId,
    required this.siteName,
    required this.workDate,
    required this.occurredAt,
    required this.alreadyCheckedIn,
  });

  final int id;
  final int? workerId;
  final int? jobPostId;
  final int? siteId;
  final String? siteName;
  final String workDate;
  final DateTime? occurredAt;
  final bool alreadyCheckedIn;

  factory CwmpAttendanceCheckResponse.fromJson(Map<String, dynamic> json) {
    return CwmpAttendanceCheckResponse(
      id: _asInt(json['id']) ?? 0,
      workerId: _asInt(json['workerId']),
      jobPostId: _asInt(json['jobPostId']),
      siteId: _asInt(json['siteId']),
      siteName: json['siteName']?.toString(),
      workDate: _asString(json['workDate']),
      occurredAt: DateTime.tryParse(_asString(json['occurredAt'])),
      alreadyCheckedIn: _asBool(json['alreadyCheckedIn']),
    );
  }
}

class CwmpUserProfileResponse {
  const CwmpUserProfileResponse({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.role,
    required this.phoneVerified,
    required this.gender,
    required this.nationality,
    required this.address,
    required this.idNumber,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  final int id;
  final String phoneNumber;
  final String? name;
  final CwmpUserRole role;
  final bool phoneVerified;
  final String? gender;
  final String? nationality;
  final String? address;
  final String? idNumber;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;

  factory CwmpUserProfileResponse.fromJson(Map<String, dynamic> json) {
    return CwmpUserProfileResponse(
      id: _asInt(json['id']) ?? 0,
      phoneNumber: _asString(json['phoneNumber']),
      name: json['name']?.toString(),
      role: CwmpUserRoleX.fromApi(_asString(json['role'], fallback: 'WORKER')),
      phoneVerified: _asBool(json['phoneVerified']),
      gender: json['gender']?.toString(),
      nationality: json['nationality']?.toString(),
      address: json['address']?.toString(),
      idNumber: json['idNumber']?.toString(),
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      accountHolder: json['accountHolder']?.toString(),
    );
  }
}

class CwmpAdminUserSummaryResponse {
  const CwmpAdminUserSummaryResponse({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.perm,
    required this.phoneVerified,
    required this.status,
    required this.noShowCount,
    required this.latestNoShowAt,
  });

  final int id;
  final String? name;
  final String phoneNumber;
  final String role;
  final int perm;
  final bool phoneVerified;
  final String status;
  final int noShowCount;
  final DateTime? latestNoShowAt;

  factory CwmpAdminUserSummaryResponse.fromJson(Map<String, dynamic> json) {
    return CwmpAdminUserSummaryResponse(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      phoneNumber: _asString(json['phoneNumber']),
      role: _asString(json['role']),
      perm: _asInt(json['perm']) ?? 0,
      phoneVerified: _asBool(json['phoneVerified']),
      status: _asString(json['status']),
      noShowCount: _asInt(json['noShowCount']) ?? 0,
      latestNoShowAt: DateTime.tryParse(_asString(json['latestNoShowAt'])),
    );
  }
}

class CwmpAdminUserDetailResponse {
  const CwmpAdminUserDetailResponse({
    required this.summary,
    required this.email,
    required this.gender,
    required this.nationality,
    required this.address,
    required this.idNumber,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  final CwmpAdminUserSummaryResponse summary;
  final String? email;
  final String? gender;
  final String? nationality;
  final String? address;
  final String? idNumber;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;

  factory CwmpAdminUserDetailResponse.fromJson(Map<String, dynamic> json) {
    final summaryJson = Map<String, dynamic>.from(
      json['summary'] as Map? ?? const {},
    );
    return CwmpAdminUserDetailResponse(
      summary: CwmpAdminUserSummaryResponse.fromJson(summaryJson),
      email: json['email']?.toString(),
      gender: json['gender']?.toString(),
      nationality: json['nationality']?.toString(),
      address: json['address']?.toString(),
      idNumber: json['idNumber']?.toString(),
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      accountHolder: json['accountHolder']?.toString(),
    );
  }
}

class CwmpAdminPermissionTemplateResponse {
  const CwmpAdminPermissionTemplateResponse({
    required this.key,
    required this.name,
    required this.description,
    required this.permLevel,
  });

  final String key;
  final String name;
  final String description;
  final int permLevel;

  factory CwmpAdminPermissionTemplateResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CwmpAdminPermissionTemplateResponse(
      key: _asString(json['key']),
      name: _asString(json['name']),
      description: _asString(json['description']),
      permLevel: _asInt(json['permLevel']) ?? 0,
    );
  }
}

class CwmpAdminPermissionUserResponse {
  const CwmpAdminPermissionUserResponse({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.perm,
    required this.authorities,
  });

  final int id;
  final String? name;
  final String phoneNumber;
  final String? role;
  final int perm;
  final List<String> authorities;

  factory CwmpAdminPermissionUserResponse.fromJson(Map<String, dynamic> json) {
    return CwmpAdminPermissionUserResponse(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      phoneNumber: _asString(json['phoneNumber']),
      role: json['role']?.toString(),
      perm: _asInt(json['perm']) ?? 0,
      authorities: (json['authorities'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class CwmpSessionSnapshot {
  const CwmpSessionSnapshot({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.userId,
    required this.phoneNumber,
    required this.role,
    this.name,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int userId;
  final String phoneNumber;
  final CwmpUserRole role;
  final String? name;

  bool get hasToken => accessToken.isNotEmpty;
}
