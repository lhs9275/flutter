import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../data/cwmp_api_models.dart';
import '../../data/cwmp_api_repository.dart';
import '../../data/cwmp_employer_app_adapter.dart';
import '../../data/cwmp_session_store.dart';
import '../../data/mock_backend.dart';
import 'screens/admin_login_flutter.dart';
import 'screens/daily_work_management_flutter.dart';
import 'screens/job_request_management_flutter.dart';
import 'screens/job_request_remote_management_flutter.dart';
import 'screens/member_management_flutter.dart';
import 'screens/notice_management_flutter.dart';
import 'screens/permission_management_flutter.dart';
import 'screens/site_management_flutter.dart';
import 'screens/wage_management_flutter.dart';
import 'screens/work_record_remote_management_flutter.dart';
import 'widgets/main_layout_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Allow standalone preview without .env.
  }
  runApp(const AdminAppFlutter());
}

enum AdminView {
  members,
  sites,
  jobRequests,
  dailyWork,
  permissions,
  wage,
  notices,
}

class _AdminSiteCoords {
  const _AdminSiteCoords({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class AdminAppFlutter extends StatefulWidget {
  const AdminAppFlutter({
    super.key,
    this.embedded = false,
    this.startAuthenticated = false,
    this.initialView = AdminView.members,
  });

  final bool embedded;
  final bool startAuthenticated;
  final AdminView initialView;

  @override
  State<AdminAppFlutter> createState() => _AdminAppFlutterState();
}

class _AdminAppFlutterState extends State<AdminAppFlutter> {
  static const String _kakaoRestApiKeyPrimary = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );
  static const String _kakaoLocalApiKeyAlt = String.fromEnvironment(
    'KAKAO_LOCAL_API_KEY',
  );

  late bool _isAuthenticated;
  late AdminView _view;
  Map<String, dynamic>? _selectedMember;
  bool _isRemoteLoading = false;
  String? _remoteLoadError;
  CwmpSessionSnapshot? _session;
  List<Map<String, dynamic>> _remoteSites = const [];
  List<Map<String, dynamic>> _remoteJobRequests = const [];
  List<Map<String, dynamic>> _remoteNotices = const [];
  List<CwmpJobPostResponse> _remotePublishedJobPosts = const [];
  final Map<int, List<CwmpMatchSelectionResponse>> _remoteMatchesByJobPost = {};
  final Set<int> _remoteMatchesLoadingJobPostIds = <int>{};
  final Map<int, List<CwmpWorkRecordResponse>> _remoteWorkRecordsByJobPost = {};
  final Set<int> _remoteWorkRecordsLoadingJobPostIds = <int>{};
  final Map<int, String> _remoteWorkerNamesByUserId = {};
  final Map<int, CwmpNoShowSummaryResponse> _remoteNoShowSummaryByUserId = {};

  final ThemeData _theme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.light,
    ),
    primaryColor: const Color(0xFF6366F1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8FAFC),
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
    useMaterial3: false,
  );

  final List<Map<String, dynamic>> _members = [
    {
      'name': '김테스트',
      'phone': '010-1111-2222',
      'status': '활성',
      'noShowCount': 0,
    },
    {'name': '이철수', 'phone': '010-8000-0001', 'status': '대기', 'noShowCount': 2},
    {'name': '박지영', 'phone': '010-8000-0002', 'status': '활성', 'noShowCount': 1},
  ];

  bool get _hasRemoteSession =>
      _session?.hasToken == true && _session?.role == CwmpUserRole.admin;

  List<Map<String, dynamic>> get _sites {
    if (_hasRemoteSession) return List<Map<String, dynamic>>.from(_remoteSites);
    return MockBackend.sites;
  }

  List<Map<String, dynamic>> get _jobRequests {
    if (_hasRemoteSession) {
      return List<Map<String, dynamic>>.from(_remoteJobRequests);
    }
    return MockBackend.jobRequests;
  }

  @override
  void initState() {
    super.initState();
    _isAuthenticated = widget.startAuthenticated;
    _view = widget.initialView;
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    final session = await CwmpSessionStore.read();
    if (!mounted) return;
    if (session == null || session.role != CwmpUserRole.admin) {
      setState(() {
        _session = null;
        _remoteSites = const [];
        _remoteJobRequests = const [];
        _remoteNotices = const [];
        _remotePublishedJobPosts = const [];
        _remoteMatchesByJobPost.clear();
        _remoteMatchesLoadingJobPostIds.clear();
        _remoteWorkRecordsByJobPost.clear();
        _remoteWorkRecordsLoadingJobPostIds.clear();
        _remoteWorkerNamesByUserId.clear();
        _remoteNoShowSummaryByUserId.clear();
      });
      return;
    }
    setState(() {
      _session = session;
      _isAuthenticated = true;
    });
    await _refreshRemoteAdminData();
  }

  Future<void> _refreshRemoteAdminData() async {
    if (!_hasRemoteSession) return;
    if (_isRemoteLoading) return;
    setState(() {
      _isRemoteLoading = true;
      _remoteLoadError = null;
    });
    try {
      final sites = await CwmpApiRepository.instance
          .getAdminPendingSiteRequests();
      final jobRequests = await CwmpApiRepository.instance
          .getAdminPendingJobRequests();
      final notifications = await CwmpApiRepository.instance.getNotifications();
      final jobPosts = await CwmpApiRepository.instance.getJobPosts(
        includeOtherRegions: true,
      );
      if (!mounted) return;
      setState(() {
        _remoteSites = sites.map(_toAdminSiteMap).toList();
        _remoteJobRequests = jobRequests
            .map(CwmpEmployerAppAdapter.toJobRequestMap)
            .toList();
        _remoteNotices = notifications.map(_toAdminNoticeMap).toList();
        _remotePublishedJobPosts = jobPosts;
        final validIds = jobPosts.map((e) => e.id).toSet();
        _remoteMatchesByJobPost.removeWhere(
          (key, _) => !validIds.contains(key),
        );
        _remoteMatchesLoadingJobPostIds.removeWhere(
          (id) => !validIds.contains(id),
        );
        _remoteWorkRecordsByJobPost.removeWhere(
          (key, _) => !validIds.contains(key),
        );
        _remoteWorkRecordsLoadingJobPostIds.removeWhere(
          (id) => !validIds.contains(id),
        );
      });
      if (_view == AdminView.dailyWork || _view == AdminView.wage) {
        _prefetchRemoteWorkRecordsForPublishedJobPosts(forceRefresh: true);
      }
      if (_view == AdminView.jobRequests) {
        _prefetchRemoteMatchesForPublishedJobPosts(forceRefresh: true);
        _prefetchRemoteWorkRecordsForPublishedJobPosts(forceRefresh: true);
      }
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      setState(() {
        _remoteLoadError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _remoteLoadError = '관리자 데이터 로드 실패: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isRemoteLoading = false);
      }
    }
  }

  Map<String, dynamic> _toAdminSiteMap(CwmpConstructionSiteResponse site) {
    final mapped = CwmpEmployerAppAdapter.toSiteMap(site);
    final status = (mapped['status'] as SiteStatus?) ?? SiteStatus.pending;
    return {
      ...mapped,
      // Backend has no exposed "phone verified" admin field. Keep approval flow usable.
      'phoneVerified': status == SiteStatus.pending
          ? true
          : mapped['phoneVerified'],
    };
  }

  Map<String, dynamic> _toAdminNoticeMap(CwmpNotificationResponse notice) {
    final created = notice.createdAt;
    final createdText = created == null
        ? ''
        : '${created.year.toString().padLeft(4, '0')}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
    return {
      'id': notice.id.toString(),
      'title': notice.title,
      'content': notice.content,
      'emergency': notice.isEmergency,
      'userId': notice.userId,
      'createdAt': createdText,
    };
  }

  Future<Map<String, dynamic>> _loadAdminNoticeDetailMap(String id) async {
    final parsed = int.tryParse(id);
    if (parsed == null) {
      throw Exception('공지 ID 형식이 올바르지 않습니다.');
    }
    final detail = await CwmpApiRepository.instance.getNotification(parsed);
    return _toAdminNoticeMap(detail);
  }

  Future<void> _createAdminNotice(
    String title,
    String content,
    bool emergency,
  ) async {
    if (!_hasRemoteSession) return;
    await CwmpApiRepository.instance.createNotification(
      title: title,
      content: content,
      emergency: emergency,
    );
    await _refreshRemoteAdminData();
  }

  Future<void> _deleteAdminNotice(String id) async {
    if (!_hasRemoteSession) return;
    final parsed = int.tryParse(id);
    if (parsed == null) {
      throw Exception('공지 ID 형식이 올바르지 않습니다.');
    }
    await CwmpApiRepository.instance.deleteNotification(parsed);
    await _refreshRemoteAdminData();
  }

  Future<void> _updateAdminNotice({
    required String id,
    required String title,
    required String content,
    required bool emergency,
  }) async {
    if (!_hasRemoteSession) return;
    final parsed = int.tryParse(id);
    if (parsed == null) {
      throw Exception('공지 ID 형식이 올바르지 않습니다.');
    }
    await CwmpApiRepository.instance.updateNotification(
      id: parsed,
      title: title,
      content: content,
      emergency: emergency,
    );
    await _refreshRemoteAdminData();
  }

  Future<void> _loadRemoteMatchesForJobPost(int jobPostId) async {
    return _loadRemoteMatchesForJobPostInternal(jobPostId);
  }

  Future<void> _loadRemoteMatchesForJobPostInternal(
    int jobPostId, {
    bool skipIfCached = false,
    bool showErrorSnackBar = true,
  }) async {
    if (!_hasRemoteSession) return;
    if (skipIfCached && _remoteMatchesByJobPost.containsKey(jobPostId)) return;
    if (_remoteMatchesLoadingJobPostIds.contains(jobPostId)) return;
    setState(() {
      _remoteMatchesLoadingJobPostIds.add(jobPostId);
    });
    try {
      final matches = await CwmpApiRepository.instance
          .getAdminMatchesForJobPost(jobPostId);
      Map<int, String> workerNames = const {};
      try {
        final workRecords = await CwmpApiRepository.instance
            .getWorkRecordsForJobPost(jobPostId);
        workerNames = {
          for (final record in workRecords)
            if (record.workerId > 0 && record.workerName.trim().isNotEmpty)
              record.workerId: record.workerName.trim(),
        };
      } on CwmpApiException catch (e) {
        if (e.statusCode == 401) {
          rethrow;
        }
        // Worker names are best-effort only; keep matches visible even if work-record lookup fails.
      } catch (_) {
        // Ignore best-effort worker name lookup failures.
      }
      if (!mounted) return;
      setState(() {
        _remoteMatchesByJobPost[jobPostId] = matches;
        _remoteWorkerNamesByUserId.addAll(workerNames);
      });
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      if (showErrorSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('지원 목록 조회 실패: ${e.message}')));
      }
    } catch (e) {
      if (!mounted) return;
      if (showErrorSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('지원 목록 조회 중 오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _remoteMatchesLoadingJobPostIds.remove(jobPostId);
        });
      }
    }
  }

  Future<void> _loadRemoteWorkRecordsForJobPost(int jobPostId) async {
    return _loadRemoteWorkRecordsForJobPostInternal(jobPostId);
  }

  Future<void> _loadRemoteWorkRecordsForJobPostInternal(
    int jobPostId, {
    bool skipIfCached = false,
    bool showErrorSnackBar = true,
  }) async {
    if (!_hasRemoteSession) return;
    if (skipIfCached && _remoteWorkRecordsByJobPost.containsKey(jobPostId)) {
      return;
    }
    if (_remoteWorkRecordsLoadingJobPostIds.contains(jobPostId)) return;
    setState(() {
      _remoteWorkRecordsLoadingJobPostIds.add(jobPostId);
    });
    try {
      final records = await CwmpApiRepository.instance.getWorkRecordsForJobPost(
        jobPostId,
      );
      if (!mounted) return;
      setState(() {
        _remoteWorkRecordsByJobPost[jobPostId] = records;
      });
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      if (showErrorSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('근무기록 조회 실패: ${e.message}')));
      }
    } catch (e) {
      if (!mounted) return;
      if (showErrorSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('근무기록 조회 중 오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _remoteWorkRecordsLoadingJobPostIds.remove(jobPostId);
        });
      }
    }
  }

  Future<void> _prefetchRemoteWorkRecordsForPublishedJobPosts({
    bool forceRefresh = false,
  }) async {
    if (!_hasRemoteSession) return;
    final jobPostIds = _remotePublishedJobPosts
        .map((post) => post.id)
        .where((id) => id > 0)
        .toList();
    if (jobPostIds.isEmpty) return;
    for (final jobPostId in jobPostIds) {
      if (!mounted || !_hasRemoteSession) return;
      await _loadRemoteWorkRecordsForJobPostInternal(
        jobPostId,
        skipIfCached: !forceRefresh,
        showErrorSnackBar: false,
      );
    }
  }

  Future<void> _prefetchRemoteMatchesForPublishedJobPosts({
    bool forceRefresh = false,
  }) async {
    if (!_hasRemoteSession) return;
    final jobPostIds = _remotePublishedJobPosts
        .map((post) => post.id)
        .where((id) => id > 0)
        .toList();
    if (jobPostIds.isEmpty) return;
    for (final jobPostId in jobPostIds) {
      if (!mounted || !_hasRemoteSession) return;
      await _loadRemoteMatchesForJobPostInternal(
        jobPostId,
        skipIfCached: !forceRefresh,
        showErrorSnackBar: false,
      );
    }
  }

  Future<void> _prioritizeRemoteMatch({
    required int jobPostId,
    required int matchId,
    int? selectionOrder,
    String? note,
  }) async {
    if (!_hasRemoteSession) return;
    try {
      await CwmpApiRepository.instance.prioritizeAdminMatch(
        matchId: matchId,
        preferred: true,
        selectionOrder: selectionOrder,
        note: note,
      );
      await _loadRemoteMatchesForJobPost(jobPostId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('우선선발 표시 완료')));
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('우선선발 처리 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('우선선발 처리 중 오류: $e')));
    }
  }

  Future<void> _confirmRemoteMatch({
    required int jobPostId,
    required int matchId,
  }) async {
    if (!_hasRemoteSession) return;
    try {
      await CwmpApiRepository.instance.confirmAdminMatch(matchId);
      await _loadRemoteMatchesForJobPost(jobPostId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('매칭 확정 완료')));
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('매칭 확정 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('매칭 확정 중 오류: $e')));
    }
  }

  Future<void> _recordRemoteNoShow({
    required int jobPostId,
    required int matchId,
    String? reason,
  }) async {
    if (!_hasRemoteSession) return;
    try {
      final match = (_remoteMatchesByJobPost[jobPostId] ?? const [])
          .where((m) => m.id == matchId)
          .cast<CwmpMatchSelectionResponse?>()
          .firstWhere((m) => m != null, orElse: () => null);
      final summary = await CwmpApiRepository.instance.recordNoShow(
        matchId: matchId,
        reason: reason,
      );
      if (match != null && match.workerId > 0) {
        _remoteNoShowSummaryByUserId[match.workerId] = summary;
      }
      await _loadRemoteMatchesForJobPost(jobPostId);
      if (!mounted) return;
      final latest = summary.latestOccurredAt == null
          ? '-'
          : _formatDateTime(summary.latestOccurredAt!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노쇼 기록 완료 (누적 ${summary.count}회, 최근 $latest)')),
      );
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('노쇼 기록 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('노쇼 기록 중 오류: $e')));
    }
  }

  Future<CwmpNoShowSummaryResponse> _fetchNoShowSummaryForUser(
    int userId,
  ) async {
    if (!_hasRemoteSession) {
      throw Exception('관리자 세션이 필요합니다.');
    }
    final cached = _remoteNoShowSummaryByUserId[userId];
    if (cached != null) return cached;
    try {
      final summary = await CwmpApiRepository.instance.getNoShowSummaryForUser(
        userId,
      );
      _remoteNoShowSummaryByUserId[userId] = summary;
      return summary;
    } on CwmpApiException catch (e) {
      if (e.statusCode == 401) {
        await _handleSessionExpired();
      }
      rethrow;
    }
  }

  Future<void> _settleRemoteWorkRecord({
    required int jobPostId,
    required int recordId,
  }) async {
    if (!_hasRemoteSession) return;
    try {
      await CwmpApiRepository.instance.settleWorkRecord(recordId);
      await _loadRemoteWorkRecordsForJobPost(jobPostId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정산 처리 완료')));
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('정산 처리 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('정산 처리 중 오류: $e')));
    }
  }

  Future<void> _reopenRemoteWorkRecord({
    required int jobPostId,
    required int recordId,
  }) async {
    if (!_hasRemoteSession) return;
    try {
      await CwmpApiRepository.instance.reopenWorkRecord(recordId);
      await _loadRemoteWorkRecordsForJobPost(jobPostId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정산 재오픈 완료')));
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('정산 재오픈 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('정산 재오픈 중 오류: $e')));
    }
  }

  Future<void> _upsertRemoteWorkRecordForMatch({
    required int jobPostId,
    required int matchId,
    String? workDate,
    required num workUnits,
    int? rating,
    String? evaluationNote,
  }) async {
    if (!_hasRemoteSession) return;
    try {
      final record = await CwmpApiRepository.instance.upsertWorkRecordForMatch(
        matchId: matchId,
        workDate: workDate,
        workUnits: workUnits,
        rating: rating,
        evaluationNote: evaluationNote,
      );
      if (record.workerId > 0 && record.workerName.trim().isNotEmpty) {
        _remoteWorkerNamesByUserId[record.workerId] = record.workerName.trim();
      }
      await _loadRemoteWorkRecordsForJobPost(jobPostId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('근무기록 저장 완료')));
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired();
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('근무기록 저장 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('근무기록 저장 중 오류: $e')));
    }
  }

  Future<CwmpWorkRecordResponse> _fetchRemoteWorkRecordForMatch(
    int matchId,
  ) async {
    if (!_hasRemoteSession) {
      throw Exception('관리자 세션이 필요합니다.');
    }
    try {
      return await CwmpApiRepository.instance.getWorkRecordForMatch(matchId);
    } on CwmpApiException catch (e) {
      if (e.statusCode == 401) {
        await _handleSessionExpired();
      }
      rethrow;
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

  Future<void> _handleSessionExpired() async {
    await CwmpSessionStore.clear();
    if (!mounted) return;
    setState(() {
      _session = null;
      _remoteSites = const [];
      _remoteJobRequests = const [];
      _remoteNotices = const [];
      _remotePublishedJobPosts = const [];
      _remoteMatchesByJobPost.clear();
      _remoteMatchesLoadingJobPostIds.clear();
      _remoteWorkRecordsByJobPost.clear();
      _remoteWorkRecordsLoadingJobPostIds.clear();
      _remoteWorkerNamesByUserId.clear();
      _remoteNoShowSummaryByUserId.clear();
      _remoteLoadError = '관리자 세션이 만료되었습니다. 다시 로그인해주세요.';
      _isAuthenticated = false;
    });
  }

  String _titleForView(AdminView view) {
    switch (view) {
      case AdminView.members:
        return '회원 관리';
      case AdminView.sites:
        return '현장 관리';
      case AdminView.jobRequests:
        return '공고 요청';
      case AdminView.dailyWork:
        return '일일 작업';
      case AdminView.permissions:
        return '권한 관리';
      case AdminView.wage:
        return '임금 관리';
      case AdminView.notices:
        return '공지 관리';
    }
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '관리자 시스템',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('접속 중: master'),
              ],
            ),
          ),
          _drawerItem(AdminView.members, Icons.people, '회원 관리'),
          _drawerItem(AdminView.sites, Icons.location_city, '현장 관리'),
          _drawerItem(AdminView.jobRequests, Icons.assignment, '공고 요청'),
          _drawerItem(AdminView.dailyWork, Icons.calendar_today, '일일 작업'),
          _drawerItem(AdminView.permissions, Icons.security, '권한 관리'),
          _drawerItem(AdminView.wage, Icons.payments, '임금 관리'),
          _drawerItem(AdminView.notices, Icons.campaign, '공지 관리'),
        ],
      ),
    );
  }

  ListTile _drawerItem(AdminView view, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: _view == view,
      onTap: () {
        setState(() {
          _view = view;
          _selectedMember = null;
        });
        Navigator.of(context).pop();
        if (view == AdminView.jobRequests) {
          _prefetchRemoteMatchesForPublishedJobPosts();
          _prefetchRemoteWorkRecordsForPublishedJobPosts();
        }
        if (view == AdminView.dailyWork || view == AdminView.wage) {
          _prefetchRemoteWorkRecordsForPublishedJobPosts();
        }
      },
    );
  }

  Widget _buildViewBody() {
    switch (_view) {
      case AdminView.members:
        return MemberManagementFlutter(
          members: _members,
          selectedMember: _selectedMember,
          onSelectMember: (member) => setState(() => _selectedMember = member),
          onBack: () => setState(() => _selectedMember = null),
          onAdjustNoShow: _adjustNoShowCount,
          onResetNoShow: _resetNoShowCount,
        );
      case AdminView.sites:
        return SiteManagementFlutter(
          sites: _sites,
          onVerify: _verifySitePhone,
          onApprove: _approveSite,
          onReject: _rejectSite,
        );
      case AdminView.jobRequests:
        if (_hasRemoteSession) {
          return JobRequestRemoteManagementFlutter(
            pendingRequests: _jobRequests,
            publishedJobPosts: _remotePublishedJobPosts,
            matchesByJobPost: _remoteMatchesByJobPost,
            loadingMatchJobPostIds: _remoteMatchesLoadingJobPostIds,
            workRecordsByJobPost: _remoteWorkRecordsByJobPost,
            workerNamesByUserId: _remoteWorkerNamesByUserId,
            noShowSummaryByUserId: _remoteNoShowSummaryByUserId,
            isRefreshing: _isRemoteLoading,
            error: _remoteLoadError,
            onRefresh: _refreshRemoteAdminData,
            onApproveRequest: (requestId, regionCode) =>
                _approveJobRequest(requestId, regionCode: regionCode),
            onRejectRequest: _rejectJobRequest,
            onLoadMatches: _loadRemoteMatchesForJobPost,
            onPrioritizeMatch: (jobPostId, matchId, selectionOrder, note) =>
                _prioritizeRemoteMatch(
                  jobPostId: jobPostId,
                  matchId: matchId,
                  selectionOrder: selectionOrder,
                  note: note,
                ),
            onConfirmMatch: (jobPostId, matchId) =>
                _confirmRemoteMatch(jobPostId: jobPostId, matchId: matchId),
            onRecordNoShow: (jobPostId, matchId, reason) => _recordRemoteNoShow(
              jobPostId: jobPostId,
              matchId: matchId,
              reason: reason,
            ),
            onUpsertWorkRecord: _upsertRemoteWorkRecordForMatch,
            onFetchWorkRecordDetail: _fetchRemoteWorkRecordForMatch,
            onFetchNoShowSummary: _fetchNoShowSummaryForUser,
          );
        }
        return JobRequestManagementFlutter(
          requests: _jobRequests,
          onApprove: _approveJobRequest,
          onReject: _rejectJobRequest,
          onEdit: _editJobRequest,
          onAssignPriority: _assignPriorityWorker,
          onAssignSequence: _assignSequenceWorker,
          onResetAssignments: _resetAssignments,
          onConfirmApplicantPriority: _confirmApplicantPriority,
          onConfirmApplicantSequence: _confirmApplicantSequence,
          onAdjustNoShow: _adjustApplicantNoShow,
          onResetNoShow: _resetApplicantNoShow,
        );
      case AdminView.dailyWork:
        if (_hasRemoteSession) {
          return WorkRecordRemoteManagementFlutter(
            title: '일일 작업 (근무기록)',
            publishedJobPosts: _remotePublishedJobPosts,
            workRecordsByJobPost: _remoteWorkRecordsByJobPost,
            loadingWorkRecordJobPostIds: _remoteWorkRecordsLoadingJobPostIds,
            isRefreshing: _isRemoteLoading,
            error: _remoteLoadError,
            onRefresh: _refreshRemoteAdminData,
            onLoadWorkRecords: _loadRemoteWorkRecordsForJobPost,
          );
        }
        return const DailyWorkManagementFlutter();
      case AdminView.permissions:
        return const PermissionManagementFlutter();
      case AdminView.wage:
        if (_hasRemoteSession) {
          return WorkRecordRemoteManagementFlutter(
            title: '임금 관리 (정산)',
            publishedJobPosts: _remotePublishedJobPosts,
            workRecordsByJobPost: _remoteWorkRecordsByJobPost,
            loadingWorkRecordJobPostIds: _remoteWorkRecordsLoadingJobPostIds,
            isRefreshing: _isRemoteLoading,
            error: _remoteLoadError,
            onRefresh: _refreshRemoteAdminData,
            onLoadWorkRecords: _loadRemoteWorkRecordsForJobPost,
            showSettlementActions: true,
            onSettleRecord: (jobPostId, recordId) => _settleRemoteWorkRecord(
              jobPostId: jobPostId,
              recordId: recordId,
            ),
            onReopenRecord: (jobPostId, recordId) => _reopenRemoteWorkRecord(
              jobPostId: jobPostId,
              recordId: recordId,
            ),
          );
        }
        return const WageManagementFlutter();
      case AdminView.notices:
        if (_hasRemoteSession) {
          return NoticeManagementFlutter(
            notices: _remoteNotices,
            isLoading: _isRemoteLoading,
            error: _remoteLoadError,
            onRefresh: _refreshRemoteAdminData,
            onCreate: _createAdminNotice,
            onLoadDetail: _loadAdminNoticeDetailMap,
            onUpdate: (id, title, content, emergency) => _updateAdminNotice(
              id: id,
              title: title,
              content: content,
              emergency: emergency,
            ),
            onDelete: _deleteAdminNotice,
          );
        }
        return const NoticeManagementFlutter();
    }
  }

  void _adjustNoShowCount(String phone, int delta) {
    setState(() {
      final index = _members.indexWhere((member) => member['phone'] == phone);
      if (index == -1) return;
      final current = _members[index]['noShowCount'] as int? ?? 0;
      final next = current + delta;
      final clamped = next < 0 ? 0 : next;
      _members[index] = {..._members[index], 'noShowCount': clamped};
      if (_selectedMember != null && _selectedMember!['phone'] == phone) {
        _selectedMember = _members[index];
      }
    });
  }

  void _resetNoShowCount(String phone) {
    setState(() {
      final index = _members.indexWhere((member) => member['phone'] == phone);
      if (index == -1) return;
      _members[index] = {..._members[index], 'noShowCount': 0};
      if (_selectedMember != null && _selectedMember!['phone'] == phone) {
        _selectedMember = _members[index];
      }
    });
  }

  void _verifySitePhone(String siteId) {
    if (_hasRemoteSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화 확인 상태는 현재 서버 API 미노출로 로컬 표시만 지원합니다.')),
      );
      return;
    }
    setState(() => MockBackend.verifySitePhone(siteId));
  }

  Future<void> _approveSite(String siteId) async {
    if (_hasRemoteSession) {
      final remoteId = int.tryParse(siteId);
      if (remoteId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현장 ID 형식이 올바르지 않습니다.')));
        return;
      }
      try {
        await CwmpApiRepository.instance.approveAdminSiteRequest(remoteId);
        await _refreshRemoteAdminData();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현장 승인 처리되었습니다.')));
      } on CwmpApiException catch (e) {
        if (!mounted) return;
        if (e.statusCode == 401) {
          await _handleSessionExpired();
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('현장 승인 실패: ${e.message}')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('현장 승인 중 오류: $e')));
      }
      return;
    }
    setState(
      () => MockBackend.updateSiteStatus(
        siteId,
        SiteStatus.approved,
        phoneVerified: true,
      ),
    );
  }

  Future<void> _rejectSite(String siteId, String reason) async {
    if (_hasRemoteSession) {
      final remoteId = int.tryParse(siteId);
      if (remoteId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현장 ID 형식이 올바르지 않습니다.')));
        return;
      }
      try {
        await CwmpApiRepository.instance.rejectAdminSiteRequest(
          remoteId,
          reason: reason,
        );
        await _refreshRemoteAdminData();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현장 반려 처리되었습니다.')));
      } on CwmpApiException catch (e) {
        if (!mounted) return;
        if (e.statusCode == 401) {
          await _handleSessionExpired();
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('현장 반려 실패: ${e.message}')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('현장 반려 중 오류: $e')));
      }
      return;
    }
    setState(
      () => MockBackend.updateSiteStatus(
        siteId,
        SiteStatus.rejected,
        reason: reason,
      ),
    );
  }

  Future<void> _approveJobRequest(String jobId, {String? regionCode}) async {
    if (_hasRemoteSession) {
      final request = _jobRequests.cast<Map<String, dynamic>?>().firstWhere(
        (item) => item?['id'] == jobId,
        orElse: () => null,
      );
      if (request == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('공고 요청 정보를 찾을 수 없습니다.')));
        return;
      }
      final remoteId = int.tryParse(jobId);
      if (remoteId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('요청 ID 형식이 올바르지 않습니다.')));
        return;
      }
      final workDate = (request['date']?.toString() ?? '').trim();
      final headcount = _toInt(request['count']) ?? 0;
      if (workDate.isEmpty || headcount <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('공고 요청 데이터 형식을 확인해주세요.')));
        return;
      }
      final trade = (request['jobType']?.toString() ?? '').trim();
      final siteName = (request['siteName']?.toString() ?? '').trim();
      final title = [
        if (siteName.isNotEmpty && siteName != '-') siteName,
        if (trade.isNotEmpty && trade != '-') trade,
        '모집',
      ].join(' ');
      final rawTime = (request['time']?.toString() ?? '').trim();
      final description = _dashToNull(
        (request['adminNote']?.toString() ?? '').trim().isNotEmpty
            ? request['adminNote']?.toString()
            : request['memo']?.toString(),
      );
      try {
        final resolvedRegionCode =
            _dashToNull(regionCode) ??
            await _resolveRegionCodeForAdminJobRequest(request);
        await CwmpApiRepository.instance.approveAdminJobRequest(
          remoteId,
          title: title.trim().isEmpty ? '인력 모집' : title,
          description: description,
          workDate: workDate,
          startTime: _normalizeApiStartTime(rawTime),
          headcount: headcount,
          dailyRate: _parseMoneyToInt(request['rate']?.toString() ?? ''),
          requirements: _dashToNull(request['notes']?.toString()),
          regionCode: resolvedRegionCode,
        );
        await _refreshRemoteAdminData();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('공고 요청 승인/발행 처리되었습니다.')));
      } on CwmpApiException catch (e) {
        if (!mounted) return;
        if (e.statusCode == 401) {
          await _handleSessionExpired();
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('공고 요청 승인 실패: ${e.message}')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('공고 요청 승인 중 오류: $e')));
      }
      return;
    }
    setState(
      () =>
          MockBackend.updateJobRequestStatus(jobId, JobRequestStatus.approved),
    );
  }

  String _dotenvValue(String key) {
    try {
      return (dotenv.env[key] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  String get _kakaoRestApiKey {
    final explicit = _kakaoRestApiKeyPrimary.trim();
    if (explicit.isNotEmpty) return explicit;

    final dotenvRest = _dotenvValue('KAKAO_REST_API_KEY');
    if (dotenvRest.isNotEmpty) return dotenvRest;

    final alt = _kakaoLocalApiKeyAlt.trim();
    if (alt.isNotEmpty) return alt;

    final dotenvAlt = _dotenvValue('KAKAO_LOCAL_API_KEY');
    if (dotenvAlt.isNotEmpty) return dotenvAlt;

    return '';
  }

  Future<String> _resolveRegionCodeForAdminJobRequest(
    Map<String, dynamic> request,
  ) async {
    final siteId = int.tryParse((request['siteId']?.toString() ?? '').trim());
    if (siteId == null || siteId <= 0) {
      throw Exception('현장 ID(siteId)를 확인할 수 없어 지역코드를 자동 계산할 수 없습니다.');
    }
    final links = await CwmpApiRepository.instance.getSiteNavigationLinks(
      siteId,
    );
    final coords = _extractCoordsFromSiteNavigationLinks(links);
    if (coords == null) {
      throw Exception('네비 링크에서 현장 좌표를 찾지 못했습니다. (siteId: $siteId)');
    }
    return _resolveRegionCodeFromKakaoCoords(lat: coords.lat, lng: coords.lng);
  }

  _AdminSiteCoords? _extractCoordsFromSiteNavigationLinks(
    CwmpSiteNavigationLinksResponse links,
  ) {
    final fromNaver = _extractCoordsFromNaverLink(links.naver);
    if (fromNaver != null) return fromNaver;
    final fromKakao = _extractCoordsFromKakaoLink(links.kakao);
    if (fromKakao != null) return fromKakao;
    final fromTmap = _extractCoordsFromTmapLink(links.tmap);
    if (fromTmap != null) return fromTmap;
    return null;
  }

  _AdminSiteCoords? _extractCoordsFromNaverLink(String? url) {
    final uri = Uri.tryParse((url ?? '').trim());
    if (uri == null) return null;
    final lat = double.tryParse((uri.queryParameters['dlat'] ?? '').trim());
    final lng = double.tryParse((uri.queryParameters['dlng'] ?? '').trim());
    if (lat == null || lng == null) return null;
    return _AdminSiteCoords(lat: lat, lng: lng);
  }

  _AdminSiteCoords? _extractCoordsFromKakaoLink(String? url) {
    final uri = Uri.tryParse((url ?? '').trim());
    if (uri == null) return null;
    final ep = (uri.queryParameters['ep'] ?? '').trim();
    if (ep.isEmpty) return null;
    final parts = ep.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return _AdminSiteCoords(lat: lat, lng: lng);
  }

  _AdminSiteCoords? _extractCoordsFromTmapLink(String? url) {
    final uri = Uri.tryParse((url ?? '').trim());
    if (uri == null) return null;
    final lng = double.tryParse((uri.queryParameters['goalx'] ?? '').trim());
    final lat = double.tryParse((uri.queryParameters['goaly'] ?? '').trim());
    if (lat == null || lng == null) return null;
    return _AdminSiteCoords(lat: lat, lng: lng);
  }

  Future<String> _resolveRegionCodeFromKakaoCoords({
    required double lat,
    required double lng,
  }) async {
    final apiKey = _kakaoRestApiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception(
        '카카오 좌표 변환 API 키가 없습니다. (.env: KAKAO_REST_API_KEY 또는 KAKAO_LOCAL_API_KEY)',
      );
    }

    final uri = Uri.https(
      'dapi.kakao.com',
      '/v2/local/geo/coord2regioncode.json',
      {'x': lng.toString(), 'y': lat.toString()},
    );
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'KakaoAK $apiKey',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.trim();
      throw Exception(
        '카카오 좌표 변환 실패 (HTTP ${response.statusCode})${body.isEmpty ? '' : ' - $body'}',
      );
    }

    final decoded = jsonDecode(response.body);
    final json = Map<String, dynamic>.from(decoded as Map);
    final errorType = (json['errorType']?.toString() ?? '').trim();
    if (errorType.isNotEmpty) {
      final message = (json['message']?.toString() ?? '').trim();
      throw Exception(message.isEmpty ? errorType : '$errorType: $message');
    }
    final documents = (json['documents'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (documents.isEmpty) {
      throw Exception('좌표에 대한 행정구역 결과가 없습니다.');
    }
    final preferred = documents.firstWhere(
      (doc) =>
          (doc['region_type']?.toString() ?? '').trim().toUpperCase() == 'B',
      orElse: () => documents.first,
    );
    final code10 = (preferred['code']?.toString() ?? '').trim();
    if (code10.length < 5 || !RegExp(r'^\d{5,}$').hasMatch(code10)) {
      throw Exception('카카오 응답의 지역코드 형식이 올바르지 않습니다: $code10');
    }
    return code10.substring(0, 5);
  }

  Future<void> _rejectJobRequest(String jobId, String reason) async {
    if (_hasRemoteSession) {
      final remoteId = int.tryParse(jobId);
      if (remoteId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('요청 ID 형식이 올바르지 않습니다.')));
        return;
      }
      try {
        await CwmpApiRepository.instance.rejectAdminJobRequest(remoteId);
        await _refreshRemoteAdminData();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('공고 요청 반려 처리되었습니다.')));
      } on CwmpApiException catch (e) {
        if (!mounted) return;
        if (e.statusCode == 401) {
          await _handleSessionExpired();
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('공고 요청 반려 실패: ${e.message}')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('공고 요청 반려 중 오류: $e')));
      }
      return;
    }
    setState(
      () => MockBackend.updateJobRequestStatus(
        jobId,
        JobRequestStatus.rejected,
        reason: reason,
      ),
    );
  }

  void _editJobRequest(String jobId, Map<String, dynamic> updates) {
    if (_hasRemoteSession) {
      setState(() {
        final index = _remoteJobRequests.indexWhere(
          (job) => job['id'] == jobId,
        );
        if (index == -1) return;
        final current = Map<String, dynamic>.from(_remoteJobRequests[index]);
        current.addAll(updates);
        _remoteJobRequests = List<Map<String, dynamic>>.from(_remoteJobRequests)
          ..[index] = current;
      });
      return;
    }
    setState(() => MockBackend.updateJobRequest(jobId, updates));
  }

  void _assignPriorityWorker(String jobId) {
    final assigned = MockBackend.assignWorker(jobId, priority: true);
    setState(() {});
    if (assigned == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('배정 가능한 인력이 없습니다.')));
    }
  }

  void _assignSequenceWorker(String jobId) {
    final assigned = MockBackend.assignWorker(jobId, priority: false);
    setState(() {});
    if (assigned == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('배정 가능한 인력이 없습니다.')));
    }
  }

  void _resetAssignments(String jobId) {
    setState(() => MockBackend.resetAssignments(jobId));
  }

  void _confirmApplicantPriority(String jobId, String phone) {
    final ok = MockBackend.confirmApplicant(
      jobId: jobId,
      phone: phone,
      priority: true,
    );
    setState(() {});
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('확정 처리에 실패했습니다.')));
    }
  }

  void _confirmApplicantSequence(String jobId, String phone) {
    final ok = MockBackend.confirmApplicant(
      jobId: jobId,
      phone: phone,
      priority: false,
    );
    setState(() {});
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('확정 처리에 실패했습니다.')));
    }
  }

  void _adjustApplicantNoShow(String phone, int delta) {
    if (phone.trim().isEmpty) return;
    final next = MockBackend.adjustNoShowCount(phone: phone, delta: delta);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('노쇼 ${next}회로 업데이트되었습니다.')));
  }

  void _resetApplicantNoShow(String phone) {
    if (phone.trim().isEmpty) return;
    MockBackend.resetNoShowCount(phone: phone);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('노쇼 횟수가 초기화되었습니다.')));
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  int? _parseMoneyToInt(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  String? _normalizeApiStartTime(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '-') return null;
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (match == null) return null;
    final hh = match.group(1)!.padLeft(2, '0');
    final mm = match.group(2)!.padLeft(2, '0');
    return '$hh:$mm:00';
  }

  String? _dashToNull(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty || text == '-') return null;
    return text;
  }

  Widget _buildHome() {
    if (_isAuthenticated) {
      final content = Padding(
        padding: const EdgeInsets.all(16),
        child: _buildViewBody(),
      );
      return MainLayoutFlutter(
        title: _titleForView(_view),
        drawer: _buildDrawer(),
        onLogout: () => setState(() {
          if (_hasRemoteSession) {
            CwmpSessionStore.clear();
          }
          _isAuthenticated = false;
          _session = null;
          _remoteSites = const [];
          _remoteJobRequests = const [];
          _remoteNotices = const [];
          _remotePublishedJobPosts = const [];
          _remoteMatchesByJobPost.clear();
          _remoteMatchesLoadingJobPostIds.clear();
          _remoteWorkRecordsByJobPost.clear();
          _remoteWorkRecordsLoadingJobPostIds.clear();
          _remoteWorkerNamesByUserId.clear();
          _remoteNoShowSummaryByUserId.clear();
          _selectedMember = null;
        }),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _hasRemoteSession
              ? Column(
                  children: [
                    _buildRemoteAdminBanner(),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
      );
    }
    return Scaffold(
      body: AdminLoginFlutter(
        onLogin: () => setState(() => _isAuthenticated = true),
      ),
    );
  }

  Widget _buildRemoteAdminBanner() {
    final hasError = (_remoteLoadError ?? '').trim().isNotEmpty;
    final bg = hasError ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF);
    final border = hasError ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE);
    final titleColor = hasError
        ? const Color(0xFF991B1B)
        : const Color(0xFF1E3A8A);
    final subtitle = hasError
        ? _remoteLoadError!.trim()
        : (_isRemoteLoading ? '실서버 관리자 대기 목록 동기화 중...' : '실서버 관리자 대기 목록 기준');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError ? '실서버 연동 오류' : '실서버 관리자 연동',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: titleColor, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _isRemoteLoading ? null : _refreshRemoteAdminData,
            icon: _isRemoteLoading
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = _buildHome();
    if (widget.embedded) {
      return Theme(data: _theme, child: home);
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: home,
    );
  }
}
