import 'cwmp_api_client.dart';
import 'cwmp_api_models.dart';
import 'cwmp_session_store.dart';

class CwmpApiRepository {
  CwmpApiRepository({CwmpApiClient? client})
    : _client = client ?? CwmpApiClient();

  static final CwmpApiRepository instance = CwmpApiRepository();

  final CwmpApiClient _client;

  Future<CwmpPhoneAuthPendingResponse> requestPhoneAuth({
    required String phoneNumber,
    required CwmpUserRole role,
  }) async {
    final json = await _client.postJson(
      '/api/auth/phone/request',
      auth: false,
      body: {'phoneNumber': phoneNumber, 'role': role.apiValue},
    );
    return CwmpPhoneAuthPendingResponse.fromJson(json);
  }

  Future<CwmpPhoneAuthLoginResponse> verifyPhoneAuth({
    required String phoneNumber,
    required String code,
    required CwmpUserRole role,
    String? name,
  }) async {
    final body = <String, dynamic>{
      'phoneNumber': phoneNumber,
      'code': code,
      'role': role.apiValue,
    };
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isNotEmpty) {
      body['name'] = trimmedName;
    }

    final json = await _client.postJson(
      '/api/auth/phone/verify',
      auth: false,
      body: body,
    );
    final response = CwmpPhoneAuthLoginResponse.fromJson(json);
    await CwmpSessionStore.saveLogin(response);
    return response;
  }

  Future<List<CwmpJobPostResponse>> getJobPosts({
    bool includeOtherRegions = true,
  }) async {
    final list = await _client.getJsonList(
      '/api/job-posts',
      auth: true,
      query: {'include_other_regions': includeOtherRegions},
    );
    return list
        .whereType<Map>()
        .map((e) => CwmpJobPostResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CwmpJobPostResponse> getJobPostDetail(int id) async {
    final json = await _client.getJson('/api/job-posts/$id', auth: true);
    return CwmpJobPostResponse.fromJson(json);
  }

  Future<CwmpMatchSelectionResponse> applyJobPost(int id) async {
    final json = await _client.postJson('/api/job-posts/$id/apply', auth: true);
    return CwmpMatchSelectionResponse.fromJson(json);
  }

  Future<CwmpMatchSelectionResponse> cancelJobPost(int id) async {
    final json = await _client.postJson(
      '/api/job-posts/$id/cancel',
      auth: true,
    );
    return CwmpMatchSelectionResponse.fromJson(json);
  }

  Future<List<CwmpMatchSelectionResponse>> getMyMatches() async {
    final list = await _client.getJsonList('/api/matches/my', auth: true);
    return list
        .whereType<Map>()
        .map(
          (e) =>
              CwmpMatchSelectionResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<List<CwmpMatchSelectionResponse>> getMatchesForJobPost(
    int jobPostId,
  ) async {
    final list = await _client.getJsonList(
      '/api/matches/job-post/$jobPostId',
      auth: true,
    );
    return list
        .whereType<Map>()
        .map(
          (e) =>
              CwmpMatchSelectionResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<List<CwmpConstructionSiteResponse>> getMyConstructionSites() async {
    final list = await _client.getJsonList('/api/sites/my', auth: true);
    return list
        .whereType<Map>()
        .map(
          (e) => CwmpConstructionSiteResponse.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<CwmpConstructionSiteResponse> createConstructionSiteRequest({
    required String siteName,
    String? projectName,
    required String address,
    double? latitude,
    double? longitude,
    required String contactName,
    required String contactPhone,
    String? businessInfo,
  }) async {
    final body = <String, dynamic>{
      'siteName': siteName,
      'address': address,
      'contactName': contactName,
      'contactPhone': contactPhone,
    };
    if ((projectName ?? '').trim().isNotEmpty) {
      body['projectName'] = projectName!.trim();
    }
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if ((businessInfo ?? '').trim().isNotEmpty) {
      body['businessInfo'] = businessInfo!.trim();
    }
    final json = await _client.postJson(
      '/api/sites/requests',
      auth: true,
      body: body,
    );
    return CwmpConstructionSiteResponse.fromJson(json);
  }

  Future<List<CwmpJobRequestResponse>> getMyJobRequests() async {
    final list = await _client.getJsonList('/api/job-requests/my', auth: true);
    return list
        .whereType<Map>()
        .map(
          (e) => CwmpJobRequestResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<CwmpJobRequestResponse> createJobRequest({
    required int siteId,
    required String workDate,
    String? startTime,
    required String trade,
    required int headcount,
    int? dailyRate,
    String? gatheringAddress,
    String? requirements,
    String? employerMemo,
  }) async {
    final body = <String, dynamic>{
      'siteId': siteId,
      'workDate': workDate,
      'trade': trade,
      'headcount': headcount,
    };
    if ((startTime ?? '').trim().isNotEmpty) {
      body['startTime'] = startTime!.trim();
    }
    if (dailyRate != null) body['dailyRate'] = dailyRate;
    if ((gatheringAddress ?? '').trim().isNotEmpty) {
      body['gatheringAddress'] = gatheringAddress!.trim();
    }
    if ((requirements ?? '').trim().isNotEmpty) {
      body['requirements'] = requirements!.trim();
    }
    if ((employerMemo ?? '').trim().isNotEmpty) {
      body['employerMemo'] = employerMemo!.trim();
    }
    final json = await _client.postJson(
      '/api/job-requests',
      auth: true,
      body: body,
    );
    return CwmpJobRequestResponse.fromJson(json);
  }

  Future<List<CwmpConstructionSiteResponse>>
  getAdminPendingSiteRequests() async {
    final list = await _client.getJsonList(
      '/api/sites/admin/requests',
      auth: true,
    );
    return list
        .whereType<Map>()
        .map(
          (e) => CwmpConstructionSiteResponse.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<CwmpConstructionSiteResponse> approveAdminSiteRequest(
    int siteId,
  ) async {
    final json = await _client.postJson(
      '/api/sites/admin/requests/$siteId/approve',
      auth: true,
    );
    return CwmpConstructionSiteResponse.fromJson(json);
  }

  Future<CwmpConstructionSiteResponse> rejectAdminSiteRequest(
    int siteId, {
    String? reason,
  }) async {
    final trimmedReason = reason?.trim() ?? '';
    final json = await _client.postJson(
      '/api/sites/admin/requests/$siteId/reject',
      auth: true,
      body: trimmedReason.isEmpty ? null : {'reason': trimmedReason},
    );
    return CwmpConstructionSiteResponse.fromJson(json);
  }

  Future<List<CwmpJobRequestResponse>> getAdminPendingJobRequests() async {
    final list = await _client.getJsonList(
      '/api/job-requests/admin/pending',
      auth: true,
    );
    return list
        .whereType<Map>()
        .map(
          (e) => CwmpJobRequestResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<CwmpJobPostResponse> approveAdminJobRequest(
    int requestId, {
    required String title,
    String? description,
    required String workDate,
    String? startTime,
    required int headcount,
    int? dailyRate,
    String? requirements,
    String? regionCode,
  }) async {
    final body = <String, dynamic>{
      'title': title.trim(),
      'workDate': workDate.trim(),
      'headcount': headcount,
    };
    if ((description ?? '').trim().isNotEmpty) {
      body['description'] = description!.trim();
    }
    if ((startTime ?? '').trim().isNotEmpty) {
      body['startTime'] = startTime!.trim();
    }
    if (dailyRate != null) body['dailyRate'] = dailyRate;
    if ((requirements ?? '').trim().isNotEmpty) {
      body['requirements'] = requirements!.trim();
    }
    if ((regionCode ?? '').trim().isNotEmpty) {
      body['regionCode'] = regionCode!.trim();
    }
    final json = await _client.postJson(
      '/api/job-requests/admin/$requestId/approve',
      auth: true,
      body: body,
    );
    return CwmpJobPostResponse.fromJson(json);
  }

  Future<CwmpJobRequestResponse> rejectAdminJobRequest(int requestId) async {
    final json = await _client.postJson(
      '/api/job-requests/admin/$requestId/reject',
      auth: true,
    );
    return CwmpJobRequestResponse.fromJson(json);
  }

  Future<List<CwmpPreferenceRegionItem>> getPreferenceRegions() async {
    final list = await _client.getJsonList(
      '/api/preferences/regions',
      auth: true,
    );
    return list
        .whereType<Map>()
        .map(
          (e) =>
              CwmpPreferenceRegionItem.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<CwmpSiteNavigationLinksResponse> getSiteNavigationLinks(
    int siteId,
  ) async {
    final json = await _client.getJson(
      '/api/sites/$siteId/navigation-links',
      auth: true,
    );
    return CwmpSiteNavigationLinksResponse.fromJson(json);
  }

  Future<List<CwmpPreferenceRegionItem>> savePreferenceRegions(
    List<CwmpPreferenceRegionItem> regions,
  ) async {
    final list = await _client.putJsonList(
      '/api/preferences/regions',
      auth: true,
      body: {'regions': regions.map((e) => e.toJson()).toList()},
    );
    return list
        .whereType<Map>()
        .map(
          (e) =>
              CwmpPreferenceRegionItem.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<CwmpWorkRecordSummaryResponse> getMyWorkRecords({
    String? from,
    String? to,
  }) async {
    final query = <String, dynamic>{};
    if ((from ?? '').trim().isNotEmpty) {
      query['from'] = from!.trim();
    }
    if ((to ?? '').trim().isNotEmpty) {
      query['to'] = to!.trim();
    }
    final json = await _client.getJson(
      '/api/work-records/my',
      auth: true,
      query: query.isEmpty ? null : query,
    );
    return CwmpWorkRecordSummaryResponse.fromJson(json);
  }

  Future<List<CwmpWorkRecordResponse>> getWorkRecordsForJobPost(
    int jobPostId,
  ) async {
    final list = await _client.getJsonList(
      '/api/work-records/job-posts/$jobPostId',
      auth: true,
    );
    return list
        .whereType<Map>()
        .map(
          (e) => CwmpWorkRecordResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<CwmpAttendanceCheckResponse> scanAttendance({
    int? siteId,
    String? siteName,
    required int issuedAt,
    required int expiresAt,
    required String token,
  }) async {
    final body = <String, dynamic>{
      'issuedAt': issuedAt,
      'expiresAt': expiresAt,
      'token': token.trim(),
    };
    if (siteId != null) body['siteId'] = siteId;
    if ((siteName ?? '').trim().isNotEmpty) {
      body['siteName'] = siteName!.trim();
    }
    final json = await _client.postJson(
      '/api/attendance/scan',
      auth: true,
      body: body,
    );
    return CwmpAttendanceCheckResponse.fromJson(json);
  }

  Future<List<CwmpAttendanceCheckResponse>> getMyAttendance({
    String? from,
    String? to,
  }) async {
    final query = <String, dynamic>{};
    if ((from ?? '').trim().isNotEmpty) query['from'] = from!.trim();
    if ((to ?? '').trim().isNotEmpty) query['to'] = to!.trim();
    final list = await _client.getJsonList(
      '/api/attendance/my',
      auth: true,
      query: query.isEmpty ? null : query,
    );
    return list
        .whereType<Map>()
        .map(
          (e) => CwmpAttendanceCheckResponse.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<CwmpUserProfileResponse> getMyProfile() async {
    final json = await _client.getJson('/api/users/me', auth: true);
    return CwmpUserProfileResponse.fromJson(json);
  }

  Future<CwmpUserProfileResponse> updateMyProfile({
    String? name,
    String? gender,
    String? nationality,
    String? address,
    String? idNumber,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
  }) async {
    final json = await _client.putJson(
      '/api/users/me',
      auth: true,
      body: {
        'name': (name ?? '').trim().isEmpty ? null : name!.trim(),
        'gender': (gender ?? '').trim().isEmpty ? null : gender!.trim(),
        'nationality': (nationality ?? '').trim().isEmpty
            ? null
            : nationality!.trim(),
        'address': (address ?? '').trim().isEmpty ? null : address!.trim(),
        'idNumber': (idNumber ?? '').trim().isEmpty ? null : idNumber!.trim(),
        'bankName': (bankName ?? '').trim().isEmpty ? null : bankName!.trim(),
        'accountNumber': (accountNumber ?? '').trim().isEmpty
            ? null
            : accountNumber!.trim(),
        'accountHolder': (accountHolder ?? '').trim().isEmpty
            ? null
            : accountHolder!.trim(),
      },
    );
    return CwmpUserProfileResponse.fromJson(json);
  }

  Future<CwmpWorkRecordResponse> getWorkRecordForMatch(int matchId) async {
    final json = await _client.getJson(
      '/api/work-records/matches/$matchId',
      auth: true,
    );
    return CwmpWorkRecordResponse.fromJson(json);
  }

  Future<CwmpWorkRecordResponse> upsertWorkRecordForMatch({
    required int matchId,
    String? workDate,
    required num workUnits,
    int? rating,
    String? evaluationNote,
  }) async {
    final body = <String, dynamic>{'workUnits': workUnits};
    if ((workDate ?? '').trim().isNotEmpty) {
      body['workDate'] = workDate!.trim();
    }
    if (rating != null) body['rating'] = rating;
    if ((evaluationNote ?? '').trim().isNotEmpty) {
      body['evaluationNote'] = evaluationNote!.trim();
    }
    final json = await _client.postJson(
      '/api/work-records/matches/$matchId',
      auth: true,
      body: body,
    );
    return CwmpWorkRecordResponse.fromJson(json);
  }

  Future<List<CwmpNotificationResponse>> getNotifications() async {
    final list = await _client.getJsonList('/api/notifications', auth: true);
    return list
        .whereType<Map>()
        .map(
          (e) =>
              CwmpNotificationResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<CwmpNotificationResponse> getNotification(int id) async {
    final json = await _client.getJson('/api/notifications/$id', auth: true);
    return CwmpNotificationResponse.fromJson(json);
  }

  Future<List<CwmpNotificationResponse>> getNotificationsForUser(
    int userId,
  ) async {
    final list = await _client.getJsonList(
      '/api/notifications/user/$userId',
      auth: true,
    );
    return list
        .whereType<Map>()
        .map(
          (e) =>
              CwmpNotificationResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<void> createNotification({
    required String title,
    required String content,
    bool emergency = false,
  }) async {
    await _client.postJson(
      '/api/notifications',
      auth: true,
      body: {
        'title': title.trim(),
        'content': content.trim(),
        'emergency': emergency,
      },
    );
  }

  Future<void> deleteNotification(int id) async {
    await _client.delete('/api/notifications/$id', auth: true);
  }

  Future<void> updateNotification({
    required int id,
    required String title,
    required String content,
    required bool emergency,
  }) async {
    await _client.putJson(
      '/api/notifications/$id',
      auth: true,
      body: {
        'title': title.trim(),
        'content': content.trim(),
        'emergency': emergency,
      },
    );
  }

  Future<List<CwmpMatchSelectionResponse>> getAdminMatchesForJobPost(
    int jobPostId,
  ) async {
    final list = await _client.getJsonList(
      '/api/admin/matches/job-post/$jobPostId',
      auth: true,
    );
    return list
        .whereType<Map>()
        .map(
          (e) =>
              CwmpMatchSelectionResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<CwmpMatchSelectionResponse> prioritizeAdminMatch({
    required int matchId,
    bool preferred = true,
    int? selectionOrder,
    String? note,
  }) async {
    final body = <String, dynamic>{'preferred': preferred};
    if (selectionOrder != null) body['selectionOrder'] = selectionOrder;
    if ((note ?? '').trim().isNotEmpty) {
      body['note'] = note!.trim();
    }
    final json = await _client.postJson(
      '/api/admin/matches/$matchId/prioritize',
      auth: true,
      body: body,
    );
    return CwmpMatchSelectionResponse.fromJson(json);
  }

  Future<CwmpMatchSelectionResponse> confirmAdminMatch(int matchId) async {
    final json = await _client.postJson(
      '/api/admin/matches/$matchId/confirm',
      auth: true,
    );
    return CwmpMatchSelectionResponse.fromJson(json);
  }

  Future<CwmpNoShowSummaryResponse> recordNoShow({
    required int matchId,
    String? reason,
  }) async {
    final trimmedReason = reason?.trim() ?? '';
    final json = await _client.postJson(
      '/api/noshow/admin/matches/$matchId',
      auth: true,
      body: trimmedReason.isEmpty ? null : {'reason': trimmedReason},
    );
    return CwmpNoShowSummaryResponse.fromJson(json);
  }

  Future<CwmpNoShowSummaryResponse> getNoShowSummaryForUser(int userId) async {
    final json = await _client.getJson('/api/noshow/users/$userId', auth: true);
    return CwmpNoShowSummaryResponse.fromJson(json);
  }

  Future<List<CwmpAdminUserSummaryResponse>> getAdminUsers() async {
    final list = await _client.getJsonList('/api/admin/users', auth: true);
    return list
        .whereType<Map>()
        .map(
          (e) => CwmpAdminUserSummaryResponse.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<CwmpAdminUserDetailResponse> getAdminUserDetail(int userId) async {
    final json = await _client.getJson('/api/admin/users/$userId', auth: true);
    return CwmpAdminUserDetailResponse.fromJson(json);
  }

  Future<CwmpAdminUserDetailResponse> updateAdminUser({
    required int userId,
    String? name,
    String? role,
    int? perm,
    bool? phoneVerified,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if ((role ?? '').trim().isNotEmpty) body['role'] = role!.trim();
    if (perm != null) body['perm'] = perm;
    if (phoneVerified != null) body['phoneVerified'] = phoneVerified;
    final json = await _client.putJson(
      '/api/admin/users/$userId',
      auth: true,
      body: body,
    );
    return CwmpAdminUserDetailResponse.fromJson(json);
  }

  Future<List<CwmpAdminPermissionTemplateResponse>>
  getAdminPermissionTemplates() async {
    final list = await _client.getJsonList(
      '/api/admin/permissions',
      auth: true,
    );
    return list
        .whereType<Map>()
        .map(
          (e) => CwmpAdminPermissionTemplateResponse.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<CwmpAdminPermissionUserResponse> getAdminPermissionUser(
    int userId,
  ) async {
    final json = await _client.getJson(
      '/api/admin/permissions/users/$userId',
      auth: true,
    );
    return CwmpAdminPermissionUserResponse.fromJson(json);
  }

  Future<CwmpAdminPermissionUserResponse> updateAdminPermissionUser({
    required int userId,
    String? role,
    int? perm,
  }) async {
    final body = <String, dynamic>{};
    if ((role ?? '').trim().isNotEmpty) body['role'] = role!.trim();
    if (perm != null) body['perm'] = perm;
    final json = await _client.putJson(
      '/api/admin/permissions/users/$userId',
      auth: true,
      body: body,
    );
    return CwmpAdminPermissionUserResponse.fromJson(json);
  }

  Future<CwmpWorkRecordResponse> settleWorkRecord(int recordId) async {
    final json = await _client.postJson(
      '/api/work-records/$recordId/settle',
      auth: true,
    );
    return CwmpWorkRecordResponse.fromJson(json);
  }

  Future<CwmpWorkRecordResponse> reopenWorkRecord(int recordId) async {
    final json = await _client.postJson(
      '/api/work-records/$recordId/reopen',
      auth: true,
    );
    return CwmpWorkRecordResponse.fromJson(json);
  }
}
