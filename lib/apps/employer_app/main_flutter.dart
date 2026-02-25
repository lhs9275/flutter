import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/cwmp_api_models.dart';
import '../../data/cwmp_api_repository.dart';
import '../../data/cwmp_employer_app_adapter.dart';
import '../../data/cwmp_session_store.dart';
import '../../data/mock_backend.dart';
import '../../../widgets/attendance_qr_helper.dart';
import '../../../widgets/map_launcher_card_flutter.dart';
import '../../widgets/remote_status_banner_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Allow standalone screen preview without .env.
  }
  runApp(const EmployerAppFlutter());
}

enum EmployerView {
  login,
  auth,
  register,
  dashboard,
  siteRegister,
  jobRequest,
  notices,
}

class EmployerAppFlutter extends StatefulWidget {
  const EmployerAppFlutter({
    super.key,
    this.embedded = false,
    this.initialView = EmployerView.login,
  });

  final bool embedded;
  final EmployerView initialView;

  @override
  State<EmployerAppFlutter> createState() => _EmployerAppFlutterState();
}

class _EmployerAppFlutterState extends State<EmployerAppFlutter> {
  static const String _kPrefEmployerView = 'cwmp_employer_view';
  static const String _kPrefEmployerSelectedSiteIndex =
      'cwmp_employer_selected_site_index';
  static const String _kPrefEmployerShowNoShowOnly =
      'cwmp_employer_show_noshow_only';

  late EmployerView _view;
  EmployerView? _restoredAuthedEmployerView;
  bool _rememberMe = true;
  int _selectedSiteIndex = 0;
  bool _showNoShowOnly = false;
  AttendanceQrPayload? _attendanceQr;
  bool _isRemoteLoading = false;
  String? _remoteLoadError;
  CwmpSessionSnapshot? _session;
  List<Map<String, dynamic>> _remoteSites = const [];
  List<Map<String, dynamic>> _remoteJobRequests = const [];
  List<CwmpNotificationResponse> _remoteNotices = const [];
  bool _remoteNoticesLoadedFromUserEndpoint = false;
  final Map<int, CwmpSiteNavigationLinksResponse> _remoteNavLinksBySiteId = {};
  final Set<int> _remoteNavLinksLoadingSiteIds = <int>{};

  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _siteAddressController = TextEditingController();
  final TextEditingController _siteLatitudeController = TextEditingController();
  final TextEditingController _siteLongitudeController =
      TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _businessNumberController =
      TextEditingController();
  final TextEditingController _businessInfoController = TextEditingController();
  String? _selectedSiteJobType;

  final TextEditingController _requestDateController = TextEditingController();
  final TextEditingController _requestTimeController = TextEditingController();
  final TextEditingController _requestCountController = TextEditingController();
  final TextEditingController _requestRateController = TextEditingController();
  final TextEditingController _requestMeetingController =
      TextEditingController();
  final TextEditingController _requestNotesController = TextEditingController();
  final TextEditingController _requestMemoController = TextEditingController();

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

  bool get _hasRemoteSession =>
      _session?.hasToken == true &&
      (_session!.role == CwmpUserRole.employer ||
          _session!.role == CwmpUserRole.admin);

  List<Map<String, dynamic>> get _sites {
    if (_hasRemoteSession) return List<Map<String, dynamic>>.from(_remoteSites);
    return MockBackend.sites;
  }

  final List<Map<String, String>> _notices = const [
    {
      'title': '현장 등록 절차 변경 안내',
      'date': '2024-08-05',
      'content': '필수 서류 제출 후 승인까지 1~2일 소요됩니다.',
    },
    {
      'title': '구인 공고 운영 정책',
      'date': '2024-08-01',
      'content': '허위 공고는 즉시 비공개 처리됩니다.',
    },
  ];

  static const List<String> _siteJobTypeOptions = [
    '철근공',
    '형틀목공',
    '콘크리트공',
    '조적공',
    '미장공',
    '방수공',
    '전기공',
    '설비공',
    '용접공',
    '잡부',
    '기타',
  ];

  List<Map<String, dynamic>> _jobRequestsForSite(String siteId) {
    if (_hasRemoteSession) {
      return _remoteJobRequests
          .where((job) => (job['siteId']?.toString() ?? '') == siteId)
          .toList();
    }
    return MockBackend.jobRequestsForSite(siteId);
  }

  List<Map<String, dynamic>> _assignedWorkersForSite(String siteId) {
    if (_hasRemoteSession) return const [];
    return MockBackend.confirmedApplicantsForSite(siteId);
  }

  static const List<Map<String, String>> _laborOptions = [
    {'value': '1.0', 'label': '1.0'},
    {'value': '0.5', 'label': '조퇴 0.5'},
    {'value': '1.5', 'label': '야근 1.5'},
    {'value': 'custom', 'label': '기타'},
  ];

  List<Map<String, dynamic>> _todayWorkersForSite(String siteId) {
    if (_hasRemoteSession) return const [];
    return MockBackend.todayWorkersForSite(siteId);
  }

  final Map<String, TextEditingController> _customLaborControllers = {};

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
    _selectedSiteJobType = _siteJobTypeOptions.first;
    _requestDateController.text = _formatDate(DateTime.now());
    _requestTimeController.text = '07:30 ~ 17:00';
    _requestCountController.text = '1';
    _requestRateController.text = '150,000';
    _requestMeetingController.text = '현장 정문';
    _bootstrapSession();
  }

  @override
  void dispose() {
    for (final controller in _customLaborControllers.values) {
      controller.dispose();
    }
    _siteNameController.dispose();
    _projectNameController.dispose();
    _siteAddressController.dispose();
    _siteLatitudeController.dispose();
    _siteLongitudeController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _businessNumberController.dispose();
    _businessInfoController.dispose();
    _requestDateController.dispose();
    _requestTimeController.dispose();
    _requestCountController.dispose();
    _requestRateController.dispose();
    _requestMeetingController.dispose();
    _requestNotesController.dispose();
    _requestMemoController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapSession() async {
    await _restoreEmployerUiState();
    final session = await CwmpSessionStore.read();
    if (!mounted || session == null) return;
    if (!(session.role == CwmpUserRole.employer ||
        session.role == CwmpUserRole.admin)) {
      return;
    }
    setState(() {
      _session = session;
      if (_restoredAuthedEmployerView != null) {
        _view = _restoredAuthedEmployerView!;
      } else if (_view == EmployerView.login || _view == EmployerView.auth) {
        _view = EmployerView.dashboard;
      }
    });
    await _refreshRemoteEmployerData();
  }

  Future<void> _refreshRemoteEmployerData() async {
    if (!_hasRemoteSession) return;
    setState(() {
      _isRemoteLoading = true;
      _remoteLoadError = null;
    });
    try {
      final sites = await CwmpApiRepository.instance.getMyConstructionSites();
      final jobs = await CwmpApiRepository.instance.getMyJobRequests();
      List<CwmpNotificationResponse> notices;
      var noticesFromUserEndpoint = false;
      final userId = _session?.userId ?? 0;
      if (userId > 0) {
        try {
          notices = await CwmpApiRepository.instance.getNotificationsForUser(
            userId,
          );
          noticesFromUserEndpoint = true;
        } on CwmpApiException catch (e) {
          if (e.statusCode == 401) rethrow;
          notices = await CwmpApiRepository.instance.getNotifications();
        }
      } else {
        notices = await CwmpApiRepository.instance.getNotifications();
      }
      if (!mounted) return;
      var clampedSelectedSiteIndex = false;
      setState(() {
        _remoteSites = sites.map(CwmpEmployerAppAdapter.toSiteMap).toList();
        _remoteJobRequests = jobs
            .map(CwmpEmployerAppAdapter.toJobRequestMap)
            .toList();
        _remoteNotices = notices;
        _remoteNoticesLoadedFromUserEndpoint = noticesFromUserEndpoint;
        final validSiteIds = sites.map((e) => e.id).toSet();
        _remoteNavLinksBySiteId.removeWhere(
          (key, _) => !validSiteIds.contains(key),
        );
        _remoteNavLinksLoadingSiteIds.removeWhere(
          (id) => !validSiteIds.contains(id),
        );
        if (_selectedSiteIndex >= _remoteSites.length) {
          _selectedSiteIndex = 0;
          clampedSelectedSiteIndex = true;
        }
      });
      if (clampedSelectedSiteIndex) {
        _persistEmployerUiState();
      }
      if (_view == EmployerView.jobRequest) {
        _prefetchNavigationLinksForSelectedSite();
      }
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired(showMessage: false);
        return;
      }
      setState(() => _remoteLoadError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _remoteLoadError = '현장/요청 내역을 불러오지 못했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isRemoteLoading = false);
      }
    }
  }

  Future<void> _handleSessionExpired({bool showMessage = true}) async {
    await CwmpSessionStore.clear();
    if (!mounted) return;
    setState(() {
      _session = null;
      _remoteSites = const [];
      _remoteJobRequests = const [];
      _remoteNotices = const [];
      _remoteNoticesLoadedFromUserEndpoint = false;
      _remoteNavLinksBySiteId.clear();
      _remoteNavLinksLoadingSiteIds.clear();
      _remoteLoadError = null;
      _view = EmployerView.login;
    });
    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 세션이 만료되었습니다. 다시 로그인해주세요.')),
      );
    }
  }

  bool _isPersistableEmployerView(EmployerView view) {
    return view != EmployerView.login &&
        view != EmployerView.auth &&
        view != EmployerView.register;
  }

  Future<void> _restoreEmployerUiState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_kPrefEmployerSelectedSiteIndex) ?? 0;
    final savedNoShowOnly =
        prefs.getBool(_kPrefEmployerShowNoShowOnly) ?? false;
    final savedViewName = (prefs.getString(_kPrefEmployerView) ?? '').trim();
    EmployerView? restoredView;
    for (final value in EmployerView.values) {
      if (value.name == savedViewName && _isPersistableEmployerView(value)) {
        restoredView = value;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedSiteIndex = savedIndex < 0 ? 0 : savedIndex;
      _showNoShowOnly = savedNoShowOnly;
      _restoredAuthedEmployerView = restoredView;
    });
  }

  Future<void> _persistEmployerUiState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefEmployerSelectedSiteIndex, _selectedSiteIndex);
    await prefs.setBool(_kPrefEmployerShowNoShowOnly, _showNoShowOnly);
    if (_isPersistableEmployerView(_view)) {
      await prefs.setString(_kPrefEmployerView, _view.name);
    }
  }

  void _setEmployerView(EmployerView view) {
    if (_view == view) return;
    setState(() => _view = view);
    _persistEmployerUiState();
    if (view == EmployerView.jobRequest) {
      _prefetchNavigationLinksForSelectedSite();
    }
  }

  void _openEmployerJobRequestForSite(int index) {
    setState(() {
      _selectedSiteIndex = index;
      _view = EmployerView.jobRequest;
    });
    _persistEmployerUiState();
    _prefetchNavigationLinksForSelectedSite();
  }

  void _setShowNoShowOnly(bool value) {
    if (_showNoShowOnly == value) return;
    setState(() => _showNoShowOnly = value);
    _persistEmployerUiState();
  }

  void _prefetchNavigationLinksForSelectedSite({bool forceRefresh = false}) {
    if (!_hasRemoteSession) return;
    final sites = _sites;
    if (sites.isEmpty) return;
    final safeIndex = _selectedSiteIndex >= sites.length
        ? 0
        : _selectedSiteIndex;
    final site = sites[safeIndex];
    final remoteSiteId = CwmpEmployerAppAdapter.siteIdFromMap(site);
    if (remoteSiteId == null) return;
    if (!forceRefresh && _remoteNavLinksBySiteId.containsKey(remoteSiteId)) {
      return;
    }
    _loadNavigationLinksForSite(context, site, silent: true);
  }

  Future<void> _logout() async {
    await CwmpSessionStore.clear();
    if (!mounted) return;
    setState(() {
      _session = null;
      _remoteSites = const [];
      _remoteJobRequests = const [];
      _remoteNotices = const [];
      _remoteNoticesLoadedFromUserEndpoint = false;
      _remoteNavLinksBySiteId.clear();
      _remoteNavLinksLoadingSiteIds.clear();
      _remoteLoadError = null;
      _view = EmployerView.login;
    });
  }

  Future<void> _loadNavigationLinksForSite(
    BuildContext context,
    Map<String, dynamic> site, {
    bool silent = false,
  }) async {
    if (!_hasRemoteSession) return;
    final remoteSiteId = CwmpEmployerAppAdapter.siteIdFromMap(site);
    if (remoteSiteId == null) {
      if (!silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('서버 현장 ID를 확인할 수 없습니다.')));
      }
      return;
    }
    if (_remoteNavLinksLoadingSiteIds.contains(remoteSiteId)) return;
    setState(() => _remoteNavLinksLoadingSiteIds.add(remoteSiteId));
    try {
      final links = await CwmpApiRepository.instance.getSiteNavigationLinks(
        remoteSiteId,
      );
      if (!mounted) return;
      setState(() {
        _remoteNavLinksBySiteId[remoteSiteId] = links;
      });
      if (!links.hasAnyLink && !silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용 가능한 네비 링크가 없습니다.')));
      }
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired(showMessage: true);
        return;
      }
      if (!silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('네비 링크 조회 실패: ${e.message}')));
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('네비 링크 조회 중 오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _remoteNavLinksLoadingSiteIds.remove(remoteSiteId));
      }
    }
  }

  Future<void> _openRemoteNavLink(BuildContext context, String? rawLink) async {
    final link = (rawLink ?? '').trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('링크가 없습니다.')));
      return;
    }
    final uri = Uri.tryParse(link);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('유효하지 않은 링크입니다.')));
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('네비 앱을 열 수 없습니다.')));
  }

  PreferredSizeWidget? _buildAppBar() {
    switch (_view) {
      case EmployerView.login:
        return null;
      case EmployerView.auth:
        return AppBar(title: const Text('휴대폰 인증'));
      case EmployerView.register:
        return AppBar(title: const Text('구인자 회원가입'));
      case EmployerView.dashboard:
        return AppBar(
          title: const Text('구인자 파트너'),
          actions: [
            if (_hasRemoteSession)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isRemoteLoading ? null : _refreshRemoteEmployerData,
              ),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        );
      case EmployerView.siteRegister:
        return AppBar(
          title: const Text('신규 현장 등록'),
          leading: BackButton(
            onPressed: () => _setEmployerView(EmployerView.dashboard),
          ),
        );
      case EmployerView.jobRequest:
        return AppBar(
          title: const Text('구인 요청'),
          leading: BackButton(
            onPressed: () => _setEmployerView(EmployerView.dashboard),
          ),
        );
      case EmployerView.notices:
        return AppBar(
          title: const Text('파트너 공지사항'),
          leading: BackButton(
            onPressed: () => _setEmployerView(EmployerView.dashboard),
          ),
        );
    }
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  TextEditingController _customLaborControllerFor(
    String entryKey,
    String initial,
  ) {
    final controller = _customLaborControllers.putIfAbsent(
      entryKey,
      () => TextEditingController(text: initial),
    );
    if (controller.text != initial) {
      controller.text = initial;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
    return controller;
  }

  Widget _buildLogin() {
    return _buildStandaloneAuthNotice();
  }

  Widget _buildAuth() {
    return _buildStandaloneAuthNotice();
  }

  Widget _buildRegister() {
    return _buildStandaloneAuthNotice();
  }

  Widget _buildStandaloneAuthNotice() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '구인자 파트너 앱',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('현장 관리자 전용', style: TextStyle(color: Color(0xFF475569))),
            const SizedBox(height: 24),
            _sectionCard(
              title: '전화인증 로그인 안내',
              children: [
                const Text(
                  '구인자/관리자 전화 OTP 로그인은 통합 시작 화면(라우터)에서 진행됩니다.',
                  style: TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    '통합 앱에서 전화인증 완료 후 이 화면으로 돌아오면 저장된 세션으로 자동 진입합니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _bootstrapSession,
                    icon: const Icon(Icons.refresh),
                    label: const Text('저장된 세션 다시 확인'),
                  ),
                ),
                if (!widget.embedded) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _setEmployerView(EmployerView.dashboard),
                      child: const Text('목업 미리보기로 열기'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          RemoteStatusBannerFlutter(
            isLoading: _hasRemoteSession && _isRemoteLoading,
            error: _remoteLoadError,
            infoMessage: _hasRemoteSession ? '실서버 내 현장/요청 내역 기준' : null,
            showInfoOnlyWhenNoError: true,
            onRefresh: _hasRemoteSession ? _refreshRemoteEmployerData : null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '내 현장 목록',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _setEmployerView(EmployerView.notices),
                    icon: const Icon(Icons.campaign),
                  ),
                  IconButton(
                    onPressed: () =>
                        _setEmployerView(EmployerView.siteRegister),
                    icon: const Icon(Icons.add_business),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_sites.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                '등록된 현장이 없습니다.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ..._sites.asMap().entries.map((entry) {
            final index = entry.key;
            final site = entry.value;
            final status = site['status'] as SiteStatus;
            final statusText = MockBackend.siteStatusLabel(status);
            final statusColor = status == SiteStatus.approved
                ? Colors.green
                : status == SiteStatus.rejected
                ? Colors.red
                : const Color(0xFFFBBF24);
            final statusTextColor = status == SiteStatus.approved
                ? Colors.green
                : status == SiteStatus.rejected
                ? Colors.red
                : const Color(0xFF92400E);

            return GestureDetector(
              onTap: () {
                if (status == SiteStatus.approved) {
                  _openEmployerJobRequestForSite(index);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            site['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withOpacity(0.7),
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: statusTextColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      site['address'] as String,
                      style: const TextStyle(color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '직종: ${site['jobType']}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '등록: ${site['createdAt']}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    if (status == SiteStatus.approved)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _openEmployerJobRequestForSite(index);
                          },
                          child: const Text('구인 요청하기 >'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSiteRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: const [
                Icon(Icons.phone_in_talk, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '현장 등록은 담당자에게 전화로 진위 확인 후 승인됩니다. (최초 1회)',
                    style: TextStyle(color: Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
          ),
          _sectionCard(
            title: '현장 기본 정보',
            children: [
              TextField(
                controller: _siteNameController,
                decoration: const InputDecoration(
                  labelText: '현장명 *',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _projectNameController,
                decoration: const InputDecoration(
                  labelText: '프로젝트명 (선택)',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSiteJobType,
                decoration: const InputDecoration(
                  labelText: '주요 직종 *',
                  filled: true,
                ),
                items: _siteJobTypeOptions
                    .map(
                      (jobType) => DropdownMenuItem<String>(
                        value: jobType,
                        child: Text(jobType),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedSiteJobType = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _siteAddressController,
                decoration: const InputDecoration(
                  labelText: '주소 *',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _openAddressSearch(context),
                  icon: const Icon(Icons.search),
                  label: const Text('주소 검색'),
                ),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '검색 결과 선택 시 전체 주소와 위도/경도가 자동 입력됩니다.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _siteLatitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '위도 (선택)',
                        hintText: '37.4979',
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _siteLongitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '경도 (선택)',
                        hintText: '127.0276',
                        filled: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _sectionCard(
            title: '현장 담당자 연락처',
            children: [
              TextField(
                controller: _contactNameController,
                decoration: const InputDecoration(
                  labelText: '담당자명 *',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '담당자 연락처 *',
                  filled: true,
                ),
              ),
            ],
          ),
          _sectionCard(
            title: '사업자/추가 정보',
            children: [
              TextField(
                controller: _businessNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '사업자등록번호 *',
                  hintText: '123-45-67890',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _businessInfoController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '사업자 정보 / 메모 (선택)',
                  hintText: '예: ABC건설(주), 현장 특이사항 메모',
                  filled: true,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitSiteRegistration(context),
              child: const Text('등록 요청 (전화 확인 후 승인)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobRequest() {
    final sites = _sites;
    if (_isRemoteLoading && _hasRemoteSession && sites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sites.isEmpty) {
      return const Center(
        child: Text(
          '등록된 현장이 없습니다.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }
    final safeIndex = _selectedSiteIndex >= sites.length
        ? 0
        : _selectedSiteIndex;
    final site = sites[safeIndex];
    final siteId = site['id'] as String? ?? '';
    final remoteSiteId = _hasRemoteSession
        ? CwmpEmployerAppAdapter.siteIdFromMap(site)
        : null;
    final remoteNavLinks = remoteSiteId == null
        ? null
        : _remoteNavLinksBySiteId[remoteSiteId];
    final remoteNavLoading =
        remoteSiteId != null &&
        _remoteNavLinksLoadingSiteIds.contains(remoteSiteId);
    final qrPayload = _attendanceQr;
    final isQrExpired =
        qrPayload != null && DateTime.now().isAfter(qrPayload.expiresAtDate);
    final todayLabel = _formatDate(DateTime.now());
    final todayWorkers = siteId.isEmpty
        ? <Map<String, dynamic>>[]
        : _todayWorkersForSite(siteId);
    final canBulkApprove = todayWorkers.any(
      (worker) =>
          worker['approved'] != true && _isWorkerReadyForApproval(worker),
    );
    final assignedWorkers = siteId.isEmpty
        ? <Map<String, dynamic>>[]
        : _assignedWorkersForSite(siteId);
    final filteredWorkers = _showNoShowOnly
        ? assignedWorkers
              .where((worker) => (worker['noShowCount'] as int? ?? 0) > 0)
              .toList()
        : assignedWorkers;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          RemoteStatusBannerFlutter(
            error: _remoteLoadError,
            showLoadingBar: false,
          ),
          _sectionCard(
            title: site['name'] as String,
            children: [
              Text(
                site['address'] as String,
                style: const TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              MapLauncherCardFlutter(
                name: site['name'] as String,
                address: site['address'] as String,
                latitude: site['lat'] as double?,
                longitude: site['lng'] as double?,
                height: 120,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.alt_route,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '네비 링크',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      !_hasRemoteSession
                          ? '실서버 로그인 후 네이버/카카오/Tmap 네비 링크를 사용할 수 있습니다.'
                          : remoteSiteId == null
                          ? '현장 ID를 확인할 수 없어 네비 링크를 조회할 수 없습니다.'
                          : remoteNavLinks != null
                          ? '현장 선택 시 자동 조회된 네비 링크입니다. 필요하면 새로고침하세요.'
                          : '현장 선택 시 네비 링크를 자동으로 조회합니다.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              (!_hasRemoteSession ||
                                  remoteSiteId == null ||
                                  remoteNavLoading)
                              ? null
                              : () =>
                                    _loadNavigationLinksForSite(context, site),
                          icon: remoteNavLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.alt_route),
                          label: Text(
                            remoteNavLinks == null
                                ? '네비 링크 다시 조회'
                                : '네비 링크 새로고침',
                          ),
                        ),
                        if ((remoteNavLinks?.naver ?? '').trim().isNotEmpty)
                          ElevatedButton(
                            onPressed: () => _openRemoteNavLink(
                              context,
                              remoteNavLinks!.naver,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF03C75A),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('네이버'),
                          ),
                        if ((remoteNavLinks?.kakao ?? '').trim().isNotEmpty)
                          ElevatedButton(
                            onPressed: () => _openRemoteNavLink(
                              context,
                              remoteNavLinks!.kakao,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE500),
                              foregroundColor: const Color(0xFF191919),
                            ),
                            child: const Text('카카오'),
                          ),
                        if ((remoteNavLinks?.tmap ?? '').trim().isNotEmpty)
                          ElevatedButton(
                            onPressed: () => _openRemoteNavLink(
                              context,
                              remoteNavLinks!.tmap,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tmap'),
                          ),
                      ],
                    ),
                    if (_hasRemoteSession &&
                        remoteSiteId != null &&
                        !remoteNavLoading &&
                        remoteNavLinks != null &&
                        !remoteNavLinks.hasAnyLink) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '사용 가능한 네비 링크가 없습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '인력 요청',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _requestDateController,
                decoration: const InputDecoration(
                  labelText: '근무일 (YYYY-MM-DD)',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestTimeController,
                decoration: const InputDecoration(
                  labelText: '근무 시간',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '인원',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '단가',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestMeetingController,
                decoration: const InputDecoration(
                  labelText: '집결지',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestNotesController,
                decoration: const InputDecoration(
                  labelText: '준비물/특이사항',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestMemoController,
                decoration: const InputDecoration(
                  labelText: '구인자 메모',
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submitJobRequest(context, site),
                  child: const Text('구인 요청하기'),
                ),
              ),
            ],
          ),
          _sectionCard(
            title: '출근 확인 (QR)',
            children: [
              const Text(
                'QR은 당일 10분 유효이며, 네트워크 연결 상태에서만 확인됩니다.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _HintChip(label: '당일 10분 유효'),
                  _HintChip(label: '네트워크 필요'),
                  _HintChip(label: '근로자 앱 스캔'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _generateAttendanceQr(context, site),
                  child: Text(qrPayload == null ? 'QR 생성' : 'QR 다시 생성'),
                ),
              ),
              const SizedBox(height: 12),
              if (qrPayload == null)
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(child: Text('QR 생성 후 근로자에게 스캔 요청')),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isQrExpired
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: QrImageView(
                        data: qrPayload.encode(),
                        size: 180,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isQrExpired
                          ? '만료됨 · 다시 생성 필요'
                          : '만료 ${formatTime(qrPayload.expiresAtDate)}',
                      style: TextStyle(
                        color: isQrExpired
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '발급 ${formatDateTime(qrPayload.issuedAtDate)}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          _sectionCard(
            title: '오늘 일한 근로자',
            children: [
              if (_hasRemoteSession) ...[
                Text(
                  '근무일 $todayLabel',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '실서버 연동 대기: 구인자가 자신의 공고에 확정된 매칭(matchId) 목록을 조회하는 API가 없어 근무기록 입력 대상을 구성할 수 없습니다.',
                  style: TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    '확인된 사항\n'
                    '• 사용 가능: POST /api/work-records/matches/{matchId}\n'
                    '• 필요(미노출): 구인자용 공고별 매칭/확정자 조회 (matchId 포함)\n'
                    '• 추가로 있으면 좋음: jobRequest 응답에 jobPostId',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 12),
                  ),
                ),
              ] else ...[
                Text(
                  '근무일 $todayLabel',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '공수 입력과 근무 태도 별점 평가 후 최종 승인해 주세요.',
                  style: TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: canBulkApprove
                        ? () => setState(() {
                            for (final worker in todayWorkers) {
                              if (worker['approved'] == true) continue;
                              if (_isWorkerReadyForApproval(worker)) {
                                final entryKey =
                                    worker['entryKey']?.toString() ?? '';
                                if (entryKey.isNotEmpty) {
                                  MockBackend.updateWorkEntry(
                                    entryKey: entryKey,
                                    approved: true,
                                  );
                                }
                              }
                            }
                          })
                        : null,
                    child: const Text('전체 최종 승인'),
                  ),
                ),
                const SizedBox(height: 12),
                if (todayWorkers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '오늘 근무한 근로자가 없습니다.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                else
                  ...todayWorkers.map(
                    (worker) => _buildTodayWorkerCard(worker),
                  ),
              ],
            ],
          ),
          _sectionCard(
            title: '요청 내역',
            children: () {
              final jobs = _jobRequestsForSite(site['id'] as String? ?? '');
              if (jobs.isEmpty) {
                return const [
                  Text(
                    '요청 내역이 없습니다.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ];
              }
              return jobs.map((job) {
                final isRemoteJob =
                    _hasRemoteSession && job['source']?.toString() == 'cwmp';
                final status =
                    job['status'] as JobRequestStatus? ??
                    JobRequestStatus.pending;
                final statusText = MockBackend.jobStatusLabel(status);
                final note = job['rejectReason'] ?? job['adminNote'];
                final total = job['count'] as int? ?? 0;
                final assigned = isRemoteJob
                    ? null
                    : MockBackend.assignedCountForJob(job);
                final assignmentLabel = !isRemoteJob && total > 0
                    ? '배정 $assigned/$total명'
                    : null;
                final applicants = isRemoteJob
                    ? const <Map<String, dynamic>>[]
                    : MockBackend.applicantsForJob(job['id'] as String);
                final confirmedApplicants = applicants
                    .where(
                      (applicant) =>
                          applicant['status'] == ApplicantStatus.confirmed,
                    )
                    .toList();
                final assignedPriority = isRemoteJob
                    ? const <String>[]
                    : List<String>.from(job['assignedPriority'] as List? ?? []);
                final assignedSequence = isRemoteJob
                    ? const <String>[]
                    : List<String>.from(job['assignedSequence'] as List? ?? []);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
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
                              '${job['date']} · ${job['jobType']} ${job['count']}명',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            statusText,
                            style: const TextStyle(color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '단가 ${job['rate']}원${assignmentLabel == null ? '' : ' · $assignmentLabel'}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          note.toString(),
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (isRemoteJob)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Text(
                            '실서버 연동 대기: 구인자용 지원자/배정 인력 조회 API가 없어 목록을 가져올 수 없습니다.\n'
                            '필요 항목: jobRequest -> jobPostId 연결값, 공고별 매칭(지원자/확정자) 조회 endpoint.',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Text(
                          '지원자 ${applicants.length}명 · 확정 ${confirmedApplicants.length}명',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      if (!isRemoteJob && applicants.isEmpty)
                        const Text(
                          '지원자가 없습니다.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        )
                      else if (!isRemoteJob)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: applicants.map((applicant) {
                            final name = applicant['name']?.toString() ?? '-';
                            final status =
                                applicant['status'] as ApplicantStatus? ??
                                ApplicantStatus.applied;
                            final isConfirmed =
                                status == ApplicantStatus.confirmed;
                            return Chip(
                              label: Text(isConfirmed ? '$name · 확정' : name),
                              backgroundColor: isConfirmed
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF1F5F9),
                              labelStyle: TextStyle(
                                color: isConfirmed
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF475569),
                              ),
                            );
                          }).toList(),
                        ),
                      if (assignedPriority.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '우선 배정',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: assignedPriority
                              .map(
                                (name) => Chip(
                                  label: Text(name),
                                  backgroundColor: const Color(0xFFEFF6FF),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (assignedSequence.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '순차 배정',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: assignedSequence
                              .map(
                                (name) => Chip(
                                  label: Text(name),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList();
            }(),
          ),
          _sectionCard(
            title: '배정 인력',
            children: [
              if (_hasRemoteSession) ...[
                const Text(
                  '실서버 연동 대기: 구인자용 배정 인력/노쇼 대상 조회 API가 필요합니다.',
                  style: TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    '현재 노쇼 조회(/api/noshow/users/{userId})는 userId를 알아야 호출할 수 있습니다.\n'
                    '구인자 화면에서 userId 목록을 얻으려면 공고별 매칭/확정자 조회 endpoint가 먼저 필요합니다.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ),
              ] else ...[
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('전체'),
                      selected: !_showNoShowOnly,
                      onSelected: (_) => _setShowNoShowOnly(false),
                      selectedColor: const Color(0xFFDBEAFE),
                      labelStyle: TextStyle(
                        color: !_showNoShowOnly
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF475569),
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('노쇼 있음'),
                      selected: _showNoShowOnly,
                      onSelected: (_) => _setShowNoShowOnly(true),
                      selectedColor: const Color(0xFFFEE2E2),
                      labelStyle: TextStyle(
                        color: _showNoShowOnly
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filteredWorkers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '노쇼 인력이 없습니다.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ...filteredWorkers.map(
                  (worker) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                worker['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${worker['role']} · ${worker['phone']}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _adjustNoShow(
                                      context,
                                      worker['phone'] as String? ?? '',
                                      1,
                                    ),
                                    child: const Text('노쇼 +1'),
                                  ),
                                  OutlinedButton(
                                    onPressed:
                                        (worker['noShowCount'] as int? ?? 0) > 0
                                        ? () => _adjustNoShow(
                                            context,
                                            worker['phone'] as String? ?? '',
                                            -1,
                                          )
                                        : null,
                                    child: const Text('노쇼 -1'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        (worker['noShowCount'] as int? ?? 0) > 0
                                        ? () => _resetNoShow(
                                            context,
                                            worker['phone'] as String? ?? '',
                                          )
                                        : null,
                                    child: const Text('초기화'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _NoShowBadge(count: worker['noShowCount'] as int? ?? 0),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openAddressSearch(BuildContext context) async {
    final result = await showModalBottomSheet<_AddressSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF1F5F9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddressSearchSheet(),
    );
    if (!mounted || result == null) return;

    setState(() {
      _siteAddressController.text = result.fullAddress;
      _siteLatitudeController.text = result.latitude.toStringAsFixed(6);
      _siteLongitudeController.text = result.longitude.toStringAsFixed(6);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('주소와 좌표를 불러왔습니다.')));
  }

  Future<void> _submitSiteRegistration(BuildContext context) async {
    final name = _siteNameController.text.trim();
    final projectName = _projectNameController.text.trim();
    final address = _siteAddressController.text.trim();
    final latitude = _parseOptionalDouble(_siteLatitudeController.text);
    final longitude = _parseOptionalDouble(_siteLongitudeController.text);
    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();
    final jobType = (_selectedSiteJobType ?? '').trim();
    final businessNumber = _normalizeBusinessNumber(
      _businessNumberController.text,
    );
    final businessInfo = _businessInfoController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현장명과 주소를 입력해주세요.')));
      return;
    }
    if (contactName.isEmpty || contactPhone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현장 담당자명과 연락처를 입력해주세요.')));
      return;
    }
    if (jobType.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('직종을 선택해주세요.')));
      return;
    }
    if (_businessNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사업자등록번호를 입력해주세요.')));
      return;
    }
    if (businessNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사업자등록번호 형식을 확인해주세요. (예: 123-45-67890)')),
      );
      return;
    }
    if ((_siteLatitudeController.text.trim().isNotEmpty && latitude == null) ||
        (_siteLongitudeController.text.trim().isNotEmpty &&
            longitude == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('위도/경도 형식을 확인해주세요.')));
      return;
    }
    final composedBusinessInfo = _composeConstructionSiteBusinessInfo(
      jobType: jobType,
      businessNumber: businessNumber,
      businessInfoMemo: businessInfo,
    );
    if ((composedBusinessInfo?.length ?? 0) > 255) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사업자/추가 정보가 너무 깁니다. (최대 255자)')),
      );
      return;
    }

    if (_hasRemoteSession) {
      try {
        await CwmpApiRepository.instance.createConstructionSiteRequest(
          siteName: name,
          projectName: projectName.isEmpty ? null : projectName,
          address: address,
          latitude: latitude,
          longitude: longitude,
          contactName: contactName,
          contactPhone: contactPhone,
          businessInfo: composedBusinessInfo,
        );
        await _refreshRemoteEmployerData();
      } on CwmpApiException catch (e) {
        if (!mounted) return;
        if (e.statusCode == 401) {
          await _handleSessionExpired();
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('현장 등록 요청 실패: ${e.message}')));
        return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('현장 등록 요청 중 오류가 발생했습니다: $e')));
        return;
      }
    } else {
      MockBackend.addSiteRequest(
        name: name,
        address: address,
        jobType: jobType,
        bizName: composedBusinessInfo ?? '-',
        bizNumber: businessNumber,
        representative: contactName,
        bizPhone: contactPhone,
        agentName: contactName,
        agentPhone: contactPhone,
      );
    }
    _siteNameController.clear();
    _projectNameController.clear();
    _siteAddressController.clear();
    _siteLatitudeController.clear();
    _siteLongitudeController.clear();
    _contactNameController.clear();
    _contactPhoneController.clear();
    _businessNumberController.clear();
    _businessInfoController.clear();
    setState(() => _selectedSiteJobType = _siteJobTypeOptions.first);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('현장 등록 요청이 접수되었습니다.')));
    _setEmployerView(EmployerView.dashboard);
  }

  Future<void> _submitJobRequest(
    BuildContext context,
    Map<String, dynamic> site,
  ) async {
    final siteId = site['id'] as String?;
    if (siteId == null || siteId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현장 정보가 올바르지 않습니다.')));
      return;
    }
    final date = _requestDateController.text.trim();
    final time = _requestTimeController.text.trim();
    final count = int.tryParse(_requestCountController.text.trim());
    final rate = _requestRateController.text.trim();
    final meetingPoint = _requestMeetingController.text.trim();
    final notes = _requestNotesController.text.trim();
    final memo = _requestMemoController.text.trim();
    if (date.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('근무일과 시간을 입력해주세요.')));
      return;
    }
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인원을 올바르게 입력해주세요.')));
      return;
    }
    if (rate.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('단가를 입력해주세요.')));
      return;
    }
    if (_hasRemoteSession) {
      final remoteSiteId = CwmpEmployerAppAdapter.siteIdFromMap(site);
      if (remoteSiteId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('서버 현장 ID를 확인할 수 없습니다.')));
        return;
      }
      final startTime = _normalizeApiStartTime(time);
      final rateValue = _parseMoneyToInt(rate);
      final siteTradeRaw = (site['jobType'] as String?)?.trim() ?? '';
      final trade = (siteTradeRaw.isNotEmpty && siteTradeRaw != '-')
          ? siteTradeRaw
          : '보통인부';
      try {
        await CwmpApiRepository.instance.createJobRequest(
          siteId: remoteSiteId,
          workDate: date,
          startTime: startTime,
          trade: trade,
          headcount: count,
          dailyRate: rateValue,
          gatheringAddress: meetingPoint,
          requirements: notes,
          employerMemo: memo,
        );
        await _refreshRemoteEmployerData();
      } on CwmpApiException catch (e) {
        if (!mounted) return;
        if (e.statusCode == 401) {
          await _handleSessionExpired();
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('구인 요청 등록 실패: ${e.message}')));
        return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('구인 요청 등록 중 오류가 발생했습니다: $e')));
        return;
      }
    } else {
      MockBackend.addJobRequest(
        siteId: siteId,
        siteName: site['name'] as String? ?? '-',
        date: date,
        time: time,
        jobType: site['jobType'] as String? ?? '-',
        count: count,
        rate: rate,
        meetingPoint: meetingPoint.isEmpty ? '-' : meetingPoint,
        notes: notes.isEmpty ? '-' : notes,
        memo: memo.isEmpty ? '-' : memo,
      );
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('구인 요청이 등록되었습니다.')));
    setState(() {
      _requestCountController.text = '1';
      _requestMemoController.clear();
    });
  }

  int? _parseMoneyToInt(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  double? _parseOptionalDouble(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String? _normalizeBusinessNumber(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return null;
    return '${digits.substring(0, 3)}-${digits.substring(3, 5)}-${digits.substring(5)}';
  }

  String? _composeConstructionSiteBusinessInfo({
    required String jobType,
    required String? businessNumber,
    required String businessInfoMemo,
  }) {
    final lines = <String>[];
    final normalizedJobType = jobType.trim();
    if (normalizedJobType.isNotEmpty) {
      lines.add('직종: $normalizedJobType');
    }
    if ((businessNumber ?? '').trim().isNotEmpty) {
      lines.add('사업자번호: ${businessNumber!.trim()}');
    }
    final memo = businessInfoMemo.trim();
    if (memo.isNotEmpty) {
      lines.add('메모: $memo');
    }
    if (lines.isEmpty) return null;
    return lines.join('\n');
  }

  String? _normalizeApiStartTime(String raw) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) return null;
    final hh = match.group(1)!.padLeft(2, '0');
    final mm = match.group(2)!.padLeft(2, '0');
    return '$hh:$mm:00';
  }

  void _adjustNoShow(BuildContext context, String phone, int delta) {
    if (phone.trim().isEmpty) return;
    final next = MockBackend.adjustNoShowCount(phone: phone, delta: delta);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('노쇼 ${next}회로 업데이트되었습니다.')));
  }

  void _resetNoShow(BuildContext context, String phone) {
    if (phone.trim().isEmpty) return;
    MockBackend.resetNoShowCount(phone: phone);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('노쇼 횟수가 초기화되었습니다.')));
  }

  Widget _buildTodayWorkerCard(Map<String, dynamic> worker) {
    final approved = worker['approved'] == true;
    final selectedLabor = worker['labor'] as String? ?? '1.0';
    final rating = worker['attitude'] as int? ?? 0;
    final customLabor = (worker['customLabor'] as String? ?? '').trim();
    final entryKey = (worker['entryKey']?.toString() ?? '').trim();
    final controllerKey = entryKey.isEmpty
        ? 'local-${worker['phone'] ?? worker['name'] ?? 'worker'}'
        : entryKey;
    final laborController = _customLaborControllerFor(
      controllerKey,
      customLabor,
    );
    final canApprove = _isWorkerReadyForApproval(worker);
    final statusColor = approved
        ? const Color(0xFF16A34A)
        : const Color(0xFF2563EB);
    final statusBg = approved
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFEFF6FF);
    final statusBorder = approved
        ? const Color(0xFF86EFAC)
        : const Color(0xFFBFDBFE);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  worker['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  approved ? '승인 완료' : '승인 전',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${worker['role']} · ${worker['phone']} · 출근 ${worker['checkedInAt']}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text('공수 입력', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _laborOptions.map((option) {
              final value = option['value']!;
              final selected = selectedLabor == value;
              return ChoiceChip(
                label: Text(option['label']!),
                selected: selected,
                onSelected: approved
                    ? null
                    : (_) {
                        setState(() {
                          if (value != 'custom') {
                            laborController.text = '';
                          }
                          if (entryKey.isNotEmpty) {
                            MockBackend.updateWorkEntry(
                              entryKey: entryKey,
                              labor: value,
                              customLabor: value == 'custom' ? customLabor : '',
                            );
                          }
                        });
                      },
                selectedColor: const Color(0xFFDBEAFE),
                labelStyle: TextStyle(
                  color: selected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF475569),
                ),
              );
            }).toList(),
          ),
          if (selectedLabor == 'custom') ...[
            const SizedBox(height: 10),
            TextField(
              controller: laborController,
              enabled: !approved,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '기타 공수',
                hintText: '예: 1.2',
                filled: true,
              ),
              onChanged: (value) {
                if (entryKey.isNotEmpty) {
                  MockBackend.updateWorkEntry(
                    entryKey: entryKey,
                    customLabor: value,
                  );
                }
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '근무 태도',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              _buildStarRating(
                rating: rating,
                enabled: !approved,
                onChanged: (value) {
                  if (entryKey.isNotEmpty) {
                    MockBackend.updateWorkEntry(
                      entryKey: entryKey,
                      attitude: value,
                    );
                  }
                  setState(() {});
                },
              ),
              const SizedBox(width: 8),
              Text(
                rating == 0 ? '미평가' : '$rating.0',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: approved || !canApprove
                    ? null
                    : () {
                        if (entryKey.isNotEmpty) {
                          MockBackend.updateWorkEntry(
                            entryKey: entryKey,
                            approved: true,
                          );
                        }
                        setState(() {});
                      },
                child: Text(approved ? '승인 완료' : '최종 승인'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isWorkerReadyForApproval(Map<String, dynamic> worker) {
    final rating = worker['attitude'] as int? ?? 0;
    final selectedLabor = worker['labor'] as String? ?? '1.0';
    final customLabor = (worker['customLabor'] as String? ?? '').trim();
    return rating > 0 && (selectedLabor != 'custom' || customLabor.isNotEmpty);
  }

  Widget _buildStarRating({
    required int rating,
    required bool enabled,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isSelected = rating >= value;
        return IconButton(
          icon: Icon(
            isSelected ? Icons.star : Icons.star_border,
            color: isSelected
                ? const Color(0xFFF59E0B)
                : const Color(0xFFCBD5F5),
          ),
          onPressed: enabled ? () => onChanged(value) : null,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          tooltip: '$value',
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Future<void> _generateAttendanceQr(
    BuildContext context,
    Map<String, dynamic> site,
  ) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('네트워크 연결이 필요합니다.')));
      return;
    }
    setState(() {
      _attendanceQr = AttendanceQrPayload.create(
        siteName: site['name']?.toString() ?? '-',
        siteId: site['id']?.toString(),
      );
    });
  }

  Future<void> _openRemoteNoticeDetail(CwmpNotificationResponse notice) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    try {
      final detail = await CwmpApiRepository.instance.getNotification(
        notice.id,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(detail.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (detail.isEmergency)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Text(
                      '긴급 공지',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  detail.content,
                  style: const TextStyle(color: Color(0xFF334155)),
                ),
                const SizedBox(height: 10),
                Text(
                  '작성자 ID: ${detail.userId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
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
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공지 상세 조회 실패: $e')));
    }
  }

  Widget _buildNotices() {
    if (_hasRemoteSession) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RemoteStatusBannerFlutter(
            isLoading: _isRemoteLoading,
            error: _remoteLoadError,
            infoMessage: _remoteNoticesLoadedFromUserEndpoint
                ? '실서버 내 알림 목록 기준'
                : '실서버 공지 목록 기준',
            showInfoOnlyWhenNoError: true,
            onRefresh: _refreshRemoteEmployerData,
          ),
          if (_remoteNotices.isEmpty)
            _sectionCard(
              title: '공지사항',
              children: const [
                Text('공지사항이 없습니다.', style: TextStyle(color: Color(0xFF64748B))),
              ],
            )
          else
            ..._remoteNotices.map((notice) {
              final created = notice.createdAt;
              final dateText = created == null
                  ? '-'
                  : '${created.year.toString().padLeft(4, '0')}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openRemoteNoticeDetail(notice),
                  child: _sectionCard(
                    title: notice.title,
                    children: [
                      Row(
                        children: [
                          Text(
                            dateText,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                          if (notice.isEmergency) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: const Text(
                                '긴급',
                                style: TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notice.content,
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _notices
          .map(
            (notice) => _sectionCard(
              title: notice['title']!,
              children: [
                Text(
                  notice['date']!,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Text(
                  notice['content']!,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case EmployerView.login:
        return _buildLogin();
      case EmployerView.auth:
        return _buildAuth();
      case EmployerView.register:
        return _buildRegister();
      case EmployerView.dashboard:
        return _buildDashboard();
      case EmployerView.siteRegister:
        return _buildSiteRegister();
      case EmployerView.jobRequest:
        return _buildJobRequest();
      case EmployerView.notices:
        return _buildNotices();
    }
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildBody(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = _buildScaffold();
    if (widget.embedded) {
      return Theme(data: _theme, child: scaffold);
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: scaffold,
    );
  }
}

class _NoShowBadge extends StatelessWidget {
  const _NoShowBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final hasNoShow = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasNoShow ? const Color(0xFFFEE2E2) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasNoShow ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5F5),
        ),
      ),
      child: Text(
        '노쇼 ${count}회',
        style: TextStyle(
          color: hasNoShow ? const Color(0xFFB91C1C) : const Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
      ),
    );
  }
}

class _AddressSearchResult {
  const _AddressSearchResult({
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
  });

  final String fullAddress;
  final double latitude;
  final double longitude;

  factory _AddressSearchResult.fromKakaoAddress(Map<String, dynamic> json) {
    final road = json['road_address'];
    final address = json['address'];
    final roadMap = road is Map ? Map<String, dynamic>.from(road) : null;
    final addressMap = address is Map
        ? Map<String, dynamic>.from(address)
        : null;
    final roadAddress = (roadMap?['address_name']?.toString() ?? '').trim();
    final jibunAddress = (addressMap?['address_name']?.toString() ?? '').trim();
    final fullAddress = roadAddress.isNotEmpty
        ? roadAddress
        : ((json['address_name']?.toString() ?? '').trim().isNotEmpty
              ? (json['address_name']?.toString() ?? '').trim()
              : jibunAddress);
    final latitude = double.tryParse((json['y']?.toString() ?? '').trim());
    final longitude = double.tryParse((json['x']?.toString() ?? '').trim());
    return _AddressSearchResult(
      fullAddress: fullAddress,
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
    );
  }
}

class _AddressSearchSheet extends StatefulWidget {
  const _AddressSearchSheet();

  @override
  State<_AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<_AddressSearchSheet> {
  static const String _kakaoRestApiKeyPrimary = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );
  static const String _kakaoLocalApiKeyAlt = String.fromEnvironment(
    'KAKAO_LOCAL_API_KEY',
  );

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

  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  List<_AddressSearchResult> _results = const [];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.length < 2) {
      setState(() {
        _hasSearched = true;
        _results = const [];
        _error = '두 글자 이상 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      if (_kakaoRestApiKey.trim().isEmpty) {
        throw Exception(
          '카카오 주소검색 API 키가 없습니다. '
          '(.env: KAKAO_REST_API_KEY 또는 KAKAO_LOCAL_API_KEY) '
          '.env가 앱에 포함되도록 `flutter pub get` 후 다시 실행해주세요.',
        );
      }

      final uri = Uri.https('dapi.kakao.com', '/v2/local/search/address.json', {
        'query': query,
        'size': '10',
      });
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'KakaoAK ${_kakaoRestApiKey.trim()}',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body.trim();
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception(
            'HTTP ${response.statusCode} (카카오 Local API는 REST API 키 필요: '
            'Authorization: KakaoAK <KAKAO_REST_API_KEY>)'
            '${body.isEmpty ? '' : ' - $body'}',
          );
        }
        throw Exception(
          'HTTP ${response.statusCode}${body.isEmpty ? '' : ' - $body'}',
        );
      }
      final decoded = jsonDecode(response.body);
      final decodedMap = Map<String, dynamic>.from(decoded as Map);
      if ((decodedMap['errorType']?.toString() ?? '').trim().isNotEmpty) {
        final errorType = (decodedMap['errorType']?.toString() ?? '').trim();
        final message = (decodedMap['message']?.toString() ?? '').trim();
        throw Exception(message.isEmpty ? errorType : '$errorType: $message');
      }
      final next = (decodedMap['documents'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) => _AddressSearchResult.fromKakaoAddress(
              Map<String, dynamic>.from(e),
            ),
          )
          .where(
            (e) =>
                e.fullAddress.isNotEmpty && e.latitude != 0 && e.longitude != 0,
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _results = next;
        _error = next.isEmpty ? '검색 결과가 없습니다.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _error = '주소 검색 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '주소 검색',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: const InputDecoration(
                          labelText: '주소 검색어',
                          hintText: '예: 강남역, 역삼동 123-45',
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _search,
                      child: const Text('검색'),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if ((_error ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              if (!_hasSearched)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '검색 결과를 선택하면 전체 주소와 위도/경도가 자동 입력됩니다.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: _results.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.of(context).pop(item),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.fullAddress,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '위도 ${item.latitude.toStringAsFixed(6)} / 경도 ${item.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
