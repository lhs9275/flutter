import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/cwmp_api_models.dart';
import '../../data/cwmp_api_repository.dart';
import '../../data/cwmp_session_store.dart';
import '../../data/cwmp_user_app_adapter.dart';
import '../../data/mock_backend.dart';
import '../../widgets/remote_status_banner_flutter.dart';
import 'data/region_code_catalog.dart';
import 'models/application_record.dart';
import 'screens/calendar_view_flutter.dart';
import 'screens/game_center_flutter.dart';
import 'screens/history_detail_view_flutter.dart';
import 'screens/notice_view_flutter.dart';
import 'screens/site_detail_flutter.dart';
import 'screens/site_list_flutter.dart';
import 'screens/user_info_view_flutter.dart';
import 'widgets/authentication_flutter.dart';
import 'widgets/edit_profile_form_flutter.dart';
import 'widgets/footer_flutter.dart';
import 'widgets/header_flutter.dart';
import 'widgets/keyword_input_flutter.dart';
import 'widgets/login_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Allow standalone preview without .env.
  }
  runApp(const UserAppFlutter());
}

enum UserView { login, authenticate, register, sites, siteDetail, editProfile }

enum SiteTab { list, calendar, history, userInfo, notices, games }

class UserAppFlutter extends StatefulWidget {
  const UserAppFlutter({
    super.key,
    this.embedded = false,
    this.initialView = UserView.login,
    this.initialPhone,
  });

  final bool embedded;
  final UserView initialView;
  final String? initialPhone;

  @override
  State<UserAppFlutter> createState() => _UserAppFlutterState();
}

class _UserAppFlutterState extends State<UserAppFlutter> {
  static const String _kPrefShowAllRegions = 'cwmp_user_show_all_regions';

  late UserView _view;
  SiteTab _tab = SiteTab.list;
  bool _rememberMe = true;
  Map<String, dynamic>? _selectedSite;
  String? _selectedRegionFilter;
  bool _showAllRegions = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _regionInputController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
  String _gender = 'male';
  String? _sentOtp;
  bool _isAuthLoading = false;
  bool _isSitesLoading = false;
  bool _isProfileSaving = false;
  bool _isSiteDetailLoading = false;
  bool _isSiteDetailNavLinksLoading = false;
  String? _sitesLoadError;
  String? _siteDetailLoadError;
  String? _siteDetailNavLinksError;
  CwmpSessionSnapshot? _session;
  List<Map<String, dynamic>> _remoteSites = const [];
  CwmpSiteNavigationLinksResponse? _siteDetailNavLinks;
  final Set<String> _verifiedPhones = {};
  final Set<String> _registeredPhones = {'01011112222'};
  final List<String> _preferredRegions = [];
  final Map<String, ApplicationRecord> _applications = {};

  static const Color _accent = Color(0xFF6366F1);

  final ThemeData _theme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
    ),
    primaryColor: _accent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8FAFC),
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
    useMaterial3: false,
  );

  bool get _hasRemoteSession => _session?.hasToken ?? false;

  List<Map<String, dynamic>> get _sites {
    if (_hasRemoteSession) return List<Map<String, dynamic>>.from(_remoteSites);
    return MockBackend.approvedJobPosts();
  }

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
    final phone = widget.initialPhone?.trim() ?? '';
    if (phone.isNotEmpty) {
      _phoneController.text = phone;
    }
    _bootstrapSession();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _idNumberController.dispose();
    _nationalityController.dispose();
    _addressController.dispose();
    _regionInputController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  bool _isKnownUser(String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized.isEmpty) return false;
    if (_session != null && _session!.phoneNumber == normalized) return true;
    return _registeredPhones.contains(normalized);
  }

  Future<void> _bootstrapSession() async {
    await _restoreUiPreferences();
    final session = await CwmpSessionStore.read();
    if (!mounted) return;
    if (session == null) {
      return;
    }
    setState(() {
      _session = session;
      if (_view == UserView.login) {
        _view = UserView.sites;
      }
      if (_phoneController.text.trim().isEmpty) {
        _phoneController.text = session.phoneNumber;
      }
      if ((_nameController.text.trim().isEmpty) &&
          (session.name?.trim().isNotEmpty ?? false)) {
        _nameController.text = session.name!.trim();
      }
    });
    await _loadRemotePreferences();
    await _refreshRemoteSites();
  }

  Future<void> _refreshRemoteSites() async {
    if (!_hasRemoteSession) return;
    if (mounted) {
      setState(() {
        _isSitesLoading = true;
        _sitesLoadError = null;
      });
    }
    try {
      final posts = await CwmpApiRepository.instance.getJobPosts(
        includeOtherRegions: _showAllRegions,
      );
      List<CwmpMatchSelectionResponse> myMatches = const [];
      var matchesLoaded = false;
      String? matchesLoadError;
      try {
        myMatches = await CwmpApiRepository.instance.getMyMatches();
        matchesLoaded = true;
      } on CwmpApiException catch (e) {
        if (e.statusCode == 401) rethrow;
        matchesLoadError = '지원 상태를 불러오지 못했습니다: ${e.message}';
      } catch (e) {
        matchesLoadError = '지원 상태를 불러오지 못했습니다: $e';
      }
      if (!mounted) return;
      setState(() {
        _remoteSites = posts.map(CwmpUserAppAdapter.toSiteMap).toList();
        if (matchesLoaded) {
          _replaceApplicationsFromRemoteMatches(myMatches);
        }
        if ((matchesLoadError ?? '').isNotEmpty) {
          _sitesLoadError = matchesLoadError;
        }
      });
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      setState(() => _sitesLoadError = e.message);
      if (e.statusCode == 401) {
        await _handleSessionExpired(showMessage: false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sitesLoadError = '공고 목록을 불러오지 못했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isSitesLoading = false);
      }
    }
  }

  void _handleToggleShowAllRegions(bool value) {
    if (_showAllRegions == value) return;
    setState(() => _showAllRegions = value);
    _persistShowAllRegionsPreference(value);
    if (_hasRemoteSession) {
      _refreshRemoteSites();
    }
  }

  Future<void> _restoreUiPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_kPrefShowAllRegions) ?? false;
    if (!mounted) return;
    if (_showAllRegions == value) return;
    setState(() => _showAllRegions = value);
  }

  Future<void> _persistShowAllRegionsPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefShowAllRegions, value);
  }

  Future<void> _refreshSelectedSiteDetail() async {
    if (!_hasRemoteSession) return;
    final current = _selectedSite;
    if (current == null) return;
    if (current['source']?.toString() != 'cwmp') return;
    final jobPostId = CwmpUserAppAdapter.jobPostIdFromSite(current);
    if (jobPostId == null) return;

    setState(() {
      _isSiteDetailLoading = true;
      _siteDetailLoadError = null;
    });
    try {
      final detail = await CwmpApiRepository.instance.getJobPostDetail(
        jobPostId,
      );
      final mapped = CwmpUserAppAdapter.toSiteMap(detail);
      if (!mounted) return;
      setState(() {
        final selectedId = _selectedSite?['id']?.toString();
        if (selectedId == mapped['id']?.toString()) {
          _selectedSite = mapped;
        }
        final index = _remoteSites.indexWhere(
          (site) => site['id']?.toString() == mapped['id']?.toString(),
        );
        if (index >= 0) {
          _remoteSites[index] = mapped;
        }
      });
      await _refreshSelectedSiteNavigationLinks();
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired(showMessage: false);
        return;
      }
      setState(() => _siteDetailLoadError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _siteDetailLoadError = '공고 상세를 불러오지 못했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isSiteDetailLoading = false);
      }
    }
  }

  void _openSiteDetail(Map<String, dynamic> site) {
    setState(() {
      _selectedSite = site;
      _siteDetailLoadError = null;
      _siteDetailNavLinks = null;
      _siteDetailNavLinksError = null;
      _isSiteDetailNavLinksLoading = false;
      _view = UserView.siteDetail;
    });
    _refreshSelectedSiteDetail();
  }

  int? _selectedSiteCwmpSiteId() {
    final raw = _selectedSite?['cwmpSiteId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  Future<void> _refreshSelectedSiteNavigationLinks() async {
    if (!_hasRemoteSession) return;
    final siteId = _selectedSiteCwmpSiteId();
    if (siteId == null) {
      if (!mounted) return;
      setState(() {
        _siteDetailNavLinks = null;
        _siteDetailNavLinksError =
            '현장 ID(siteId)를 읽지 못해 네비 링크를 조회할 수 없습니다. 공고 상세를 새로고침해 주세요.';
        _isSiteDetailNavLinksLoading = false;
      });
      return;
    }

    setState(() {
      _isSiteDetailNavLinksLoading = true;
      _siteDetailNavLinksError = null;
    });
    try {
      final links = await CwmpApiRepository.instance.getSiteNavigationLinks(
        siteId,
      );
      if (!mounted) return;
      setState(() {
        _siteDetailNavLinks = links;
      });
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleSessionExpired(showMessage: false);
        return;
      }
      setState(() => _siteDetailNavLinksError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _siteDetailNavLinksError = '네비 링크를 불러오지 못했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isSiteDetailNavLinksLoading = false);
      }
    }
  }

  void _replaceApplicationsFromRemoteMatches(
    List<CwmpMatchSelectionResponse> matches,
  ) {
    final next = <String, ApplicationRecord>{};
    final seenJobPostIds = <int>{};

    for (final match in matches) {
      final jobPostId = match.jobPostId;
      if (jobPostId <= 0) continue;
      if (!seenJobPostIds.add(jobPostId)) continue;

      final normalized = match.status.trim().toUpperCase();
      ApplicationStatus? status;
      switch (normalized) {
        case 'CONFIRMED':
          status = ApplicationStatus.confirmed;
          break;
        case 'APPLIED':
        case 'PREFERRED':
          status = ApplicationStatus.applied;
          break;
        case 'CANCELLED':
        case 'NO_SHOW':
        default:
          status = null;
          break;
      }
      if (status == null) continue;

      next[jobPostId.toString()] = ApplicationRecord(
        status: status,
        appliedAt: DateTime.now(),
        confirmedAt: status == ApplicationStatus.confirmed
            ? DateTime.now()
            : null,
      );
    }

    _applications
      ..clear()
      ..addAll(next);
  }

  Future<void> _loadRemotePreferences() async {
    if (!_hasRemoteSession) return;
    try {
      final regions = await CwmpApiRepository.instance.getPreferenceRegions();
      if (!mounted) return;
      final codes =
          regions
              .map((e) => e.regionCode.trim())
              .where((e) => e.isNotEmpty)
              .toList()
            ..sort((a, b) {
              final aPriority =
                  regions
                      .firstWhere((r) => r.regionCode.trim() == a)
                      .priority ??
                  9999;
              final bPriority =
                  regions
                      .firstWhere((r) => r.regionCode.trim() == b)
                      .priority ??
                  9999;
              return aPriority.compareTo(bPriority);
            });
      if (codes.isEmpty) return;
      setState(() {
        _preferredRegions
          ..clear()
          ..addAll(codes);
      });
    } catch (_) {
      // Preferences are optional for now. Keep local state when loading fails.
    }
  }

  Future<void> _handleSessionExpired({bool showMessage = true}) async {
    await CwmpSessionStore.clear();
    if (!mounted) return;
    setState(() {
      _session = null;
      _remoteSites = const [];
      _siteDetailNavLinks = null;
      _siteDetailLoadError = null;
      _siteDetailNavLinksError = null;
      _isSiteDetailLoading = false;
      _isSiteDetailNavLinksLoading = false;
      _view = UserView.login;
    });
    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 세션이 만료되었습니다. 다시 인증해주세요.')),
      );
    }
  }

  CwmpUserRole _userAppRole() => CwmpUserRole.worker;

  Future<void> _handleLogin(BuildContext context) async {
    if (_isAuthLoading) return;
    final raw = _phoneController.text.trim();
    final normalized = _normalizePhone(raw);
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 번호를 입력해주세요.')));
      return;
    }
    _phoneController.text = normalized;
    await _sendOtp(normalized);
  }

  Future<void> _sendOtp(String phone) async {
    if (_isAuthLoading) return;
    setState(() => _isAuthLoading = true);
    try {
      final response = await CwmpApiRepository.instance.requestPhoneAuth(
        phoneNumber: phone,
        role: _userAppRole(),
      );
      if (!mounted) return;
      setState(() {
        _sentOtp = response.debugCode;
        _otpController.clear();
        _view = UserView.authenticate;
        if (response.phoneNumber.isNotEmpty) {
          _phoneController.text = response.phoneNumber;
        }
      });
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증번호 요청 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
      }
    }
  }

  Future<void> _handleAuthSuccess(BuildContext context) async {
    if (_isAuthLoading) return;
    final input = _otpController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호를 입력해주세요.')));
      return;
    }
    final phone = _normalizePhone(_phoneController.text.trim());
    if (phone.isEmpty) return;
    setState(() => _isAuthLoading = true);
    try {
      final response = await CwmpApiRepository.instance.verifyPhoneAuth(
        phoneNumber: phone,
        code: input,
        role: _userAppRole(),
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      );
      if (!mounted) return;
      _verifiedPhones.add(phone);
      setState(() {
        _session = CwmpSessionSnapshot(
          accessToken: response.tokens.accessToken,
          refreshToken: response.tokens.refreshToken,
          tokenType: response.tokens.tokenType,
          userId: response.user.id,
          phoneNumber: response.user.phoneNumber,
          role: response.user.role,
          name: response.user.name,
        );
        if (response.user.name?.trim().isNotEmpty ?? false) {
          _nameController.text = response.user.name!.trim();
        }
        _view = response.firstLogin ? UserView.register : UserView.sites;
      });
      await _loadRemotePreferences();
      await _refreshRemoteSites();
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증 처리 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
      }
    }
  }

  Future<void> _handleRegister(BuildContext context) async {
    final phone = _normalizePhone(_phoneController.text.trim());
    if (phone.isNotEmpty) {
      _registeredPhones.add(phone);
    }
    await _savePreferencesToBackend(context);
    if (!mounted) return;
    setState(() => _view = UserView.sites);
    await _refreshRemoteSites();
  }

  String _currentUserName() {
    final sessionName = _session?.name?.trim();
    if (sessionName != null && sessionName.isNotEmpty) return sessionName;
    if (_isKnownUser(_phoneController.text)) return '김테스트';
    final name = _nameController.text.trim();
    return name.isEmpty ? '근로자' : name;
  }

  String _currentUserPhone() {
    final sessionPhone = _session?.phoneNumber.trim() ?? '';
    if (sessionPhone.isNotEmpty) return sessionPhone;
    final normalized = _normalizePhone(_phoneController.text.trim());
    return normalized.isEmpty ? '00000000000' : normalized;
  }

  String _formatPhone(String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized.length < 10) return phone;
    if (normalized.length == 10) {
      return '${normalized.substring(0, 3)}-${normalized.substring(3, 6)}-${normalized.substring(6)}';
    }
    return '${normalized.substring(0, 3)}-${normalized.substring(3, 7)}-${normalized.substring(7)}';
  }

  bool _addPreferredRegion(String value) {
    final region = (extractPreferredRegionCode(value) ?? value.trim()).trim();
    if (region.isEmpty) return false;
    if (_preferredRegions.contains(region)) return false;
    setState(() {
      _preferredRegions.add(region);
      _regionInputController.clear();
    });
    return true;
  }

  void _removePreferredRegion(int index) {
    setState(() {
      if (index < 0 || index >= _preferredRegions.length) return;
      _preferredRegions.removeAt(index);
    });
  }

  void _movePreferredRegion(int index, int delta) {
    final nextIndex = index + delta;
    if (nextIndex < 0 || nextIndex >= _preferredRegions.length) return;
    setState(() {
      final region = _preferredRegions.removeAt(index);
      _preferredRegions.insert(nextIndex, region);
    });
  }

  List<CwmpPreferenceRegionItem>? _buildPreferenceRegionPayload() {
    final result = <CwmpPreferenceRegionItem>[];
    for (var i = 0; i < _preferredRegions.length; i += 1) {
      final raw = _preferredRegions[i].trim();
      if (raw.isEmpty) continue;
      final code = extractPreferredRegionCode(raw);
      if (code == null) {
        return null;
      }
      result.add(
        CwmpPreferenceRegionItem(
          regionCode: code,
          regionName: preferredRegionNameByCode(code) ?? code,
          priority: i,
        ),
      );
    }
    return result;
  }

  Future<void> _savePreferencesToBackend(BuildContext context) async {
    if (!_hasRemoteSession) return;
    if (_preferredRegions.isEmpty) return;
    final payload = _buildPreferenceRegionPayload();
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선호지역 서버 저장은 지역코드 5자리(예: 11680) 입력 시 지원됩니다.'),
        ),
      );
      return;
    }
    try {
      final saved = await CwmpApiRepository.instance.savePreferenceRegions(
        payload,
      );
      if (!mounted) return;
      setState(() {
        _preferredRegions
          ..clear()
          ..addAll(saved.map((e) => e.regionCode));
      });
    } on CwmpApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('선호지역 저장 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('선호지역 저장 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _saveProfileAndClose(BuildContext context) async {
    if (_isProfileSaving) return;
    setState(() => _isProfileSaving = true);
    try {
      await _savePreferencesToBackend(context);
      if (!mounted) return;
      setState(() => _view = UserView.sites);
      await _refreshRemoteSites();
    } finally {
      if (mounted) {
        setState(() => _isProfileSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    await CwmpSessionStore.clear();
    if (!mounted) return;
    setState(() {
      _session = null;
      _remoteSites = const [];
      _sitesLoadError = null;
      _phoneController.clear();
      _otpController.clear();
      _sentOtp = null;
      _applications.clear();
      _preferredRegions.clear();
      _selectedRegionFilter = null;
      _siteDetailNavLinks = null;
      _siteDetailLoadError = null;
      _siteDetailNavLinksError = null;
      _isSiteDetailLoading = false;
      _isSiteDetailNavLinksLoading = false;
      _view = UserView.login;
    });
  }

  ApplicantStatus? _mockBackendApplicantStatusForSite(
    Map<String, dynamic> site,
  ) {
    if (site['source']?.toString() == 'cwmp') {
      return null;
    }
    final jobId = site['id']?.toString();
    if (jobId == null || jobId.isEmpty) return null;
    return MockBackend.applicantStatus(jobId, _currentUserPhone());
  }

  ApplicationRecord? _applicationForSite(Map<String, dynamic> site) {
    final id = site['id'] as String?;
    if (id == null) return null;
    final record = _applications[id];
    final backendStatus = _mockBackendApplicantStatusForSite(site);
    if (backendStatus == ApplicantStatus.confirmed) {
      return ApplicationRecord(
        status: ApplicationStatus.confirmed,
        appliedAt: record?.appliedAt ?? DateTime.now(),
        confirmedAt: record?.confirmedAt ?? DateTime.now(),
      );
    }
    return record;
  }

  Future<void> _applyToSite(
    BuildContext context,
    Map<String, dynamic> site,
  ) async {
    final id = site['id'] as String?;
    if (id == null) return;
    final record = _applications[id];
    final backendStatus = _mockBackendApplicantStatusForSite(site);
    if (backendStatus == ApplicantStatus.confirmed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 확정된 공고입니다.')));
      return;
    }
    if (backendStatus == ApplicantStatus.applied) {
      setState(() {
        _applications[id] =
            (record ??
                    ApplicationRecord(
                      status: ApplicationStatus.applied,
                      appliedAt: DateTime.now(),
                    ))
                .copyWith(status: ApplicationStatus.applied);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 지원한 공고입니다.')));
      return;
    }
    if (record != null && record.status == ApplicationStatus.confirmed) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지원하기'),
        content: Text('${site['name']} 현장에 지원하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('지원'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    if (site['source']?.toString() == 'cwmp') {
      final jobPostId = CwmpUserAppAdapter.jobPostIdFromSite(site);
      if (jobPostId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('공고 ID를 확인할 수 없습니다.')));
        return;
      }
      try {
        final response = await CwmpApiRepository.instance.applyJobPost(
          jobPostId,
        );
        if (!mounted) return;
        final status = response.status.toUpperCase();
        setState(() {
          _applications[id] = ApplicationRecord(
            status: status == 'CONFIRMED'
                ? ApplicationStatus.confirmed
                : ApplicationStatus.applied,
            appliedAt: record?.appliedAt ?? DateTime.now(),
            confirmedAt: status == 'CONFIRMED' ? DateTime.now() : null,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'CONFIRMED' ? '지원이 확정되었습니다.' : '지원이 완료되었습니다.',
            ),
          ),
        );
      } on CwmpApiException catch (e) {
        if (!mounted) return;
        if (e.statusCode == 401) {
          await _handleSessionExpired();
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('지원 처리 중 오류가 발생했습니다: $e')));
      }
      return;
    }

    setState(() {
      _applications[id] = ApplicationRecord(
        status: ApplicationStatus.applied,
        appliedAt: DateTime.now(),
      );
    });
    MockBackend.addApplication(
      jobId: id,
      name: _currentUserName(),
      phone: _currentUserPhone(),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('지원이 완료되었습니다.')));
  }

  Future<void> _cancelApplication(
    BuildContext context,
    Map<String, dynamic> site,
  ) async {
    final id = site['id'] as String?;
    if (id == null) return;
    final record = _applications[id];
    final backendStatus = _mockBackendApplicantStatusForSite(site);
    if (backendStatus == ApplicantStatus.confirmed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('확정된 공고는 취소할 수 없습니다.')));
      return;
    }
    if (record == null || record.status == ApplicationStatus.confirmed) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지원 취소'),
        content: Text('${site['name']} 지원을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (approved != true) return;

    if (site['source']?.toString() == 'cwmp') {
      final jobPostId = CwmpUserAppAdapter.jobPostIdFromSite(site);
      if (jobPostId == null) return;
      try {
        await CwmpApiRepository.instance.cancelJobPost(jobPostId);
        if (!mounted) return;
        setState(() {
          _applications.remove(id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('지원이 취소되었습니다.')));
      } on CwmpApiException catch (e) {
        if (!mounted) return;
        if (e.statusCode == 401) {
          await _handleSessionExpired();
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('지원 취소 중 오류가 발생했습니다: $e')));
      }
      return;
    }

    setState(() {
      _applications.remove(id);
    });
    MockBackend.cancelApplication(jobId: id, phone: _currentUserPhone());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('지원이 취소되었습니다.')));
  }

  PreferredSizeWidget? _buildAppBar() {
    switch (_view) {
      case UserView.login:
        return null;
      case UserView.authenticate:
        return AppBar(title: const Text('휴대폰 인증'));
      case UserView.register:
        return AppBar(title: const Text('회원가입'));
      case UserView.sites:
        final name = _currentUserName();
        return UserHeaderFlutter(
          title: '인력 관리 시스템',
          subtitle: '$name님 환영합니다.',
          onLogout: _logout,
        );
      case UserView.siteDetail:
        final canRefreshDetail =
            _hasRemoteSession && _selectedSite?['source']?.toString() == 'cwmp';
        return AppBar(
          title: const Text('현장 상세'),
          leading: BackButton(
            onPressed: () => setState(() {
              _siteDetailNavLinks = null;
              _siteDetailLoadError = null;
              _siteDetailNavLinksError = null;
              _isSiteDetailLoading = false;
              _isSiteDetailNavLinksLoading = false;
              _view = UserView.sites;
            }),
          ),
          actions: [
            if (canRefreshDetail)
              IconButton(
                onPressed: _isSiteDetailLoading
                    ? null
                    : _refreshSelectedSiteDetail,
                icon: _isSiteDetailLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: '공고 상세 새로고침',
              ),
          ],
        );
      case UserView.editProfile:
        return AppBar(
          title: const Text('프로필 수정'),
          leading: BackButton(
            onPressed: () => setState(() => _view = UserView.sites),
          ),
        );
    }
  }

  Widget _wrapAuthCard(Widget child) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSitesTabContent() {
    final preferredRegions = List<String>.from(_preferredRegions);
    final sites = _sites;
    if (_tab == SiteTab.list &&
        _hasRemoteSession &&
        _isSitesLoading &&
        sites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final applicationSnapshot = <String, ApplicationRecord>{};
    for (final site in sites) {
      final id = site['id'] as String?;
      if (id == null) continue;
      final backendStatus = _mockBackendApplicantStatusForSite(site);
      final local = _applications[id];
      if (backendStatus == ApplicantStatus.confirmed) {
        applicationSnapshot[id] = ApplicationRecord(
          status: ApplicationStatus.confirmed,
          appliedAt: local?.appliedAt ?? DateTime.now(),
          confirmedAt: DateTime.now(),
        );
        continue;
      }
      if (backendStatus == ApplicantStatus.applied) {
        applicationSnapshot[id] = ApplicationRecord(
          status: ApplicationStatus.applied,
          appliedAt: local?.appliedAt ?? DateTime.now(),
        );
        continue;
      }
      if (local != null) {
        applicationSnapshot[id] = local;
      }
    }
    final availableRegions =
        sites
            .map((site) => site['region'] as String?)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    if (preferredRegions.isNotEmpty) {
      for (final region in preferredRegions.reversed) {
        if (!availableRegions.contains(region)) {
          availableRegions.insert(0, region);
        }
      }
    }
    final visibleSites = _filterSitesByRegion(
      sites: sites,
      preferredRegions: preferredRegions,
      selectedRegion: _selectedRegionFilter,
      showAllRegions: _showAllRegions,
    );
    switch (_tab) {
      case SiteTab.list:
        final list = SiteListFlutter(
          sites: visibleSites,
          preferredRegions: preferredRegions,
          selectedRegion: _selectedRegionFilter,
          availableRegions: availableRegions,
          showAllRegions: _showAllRegions,
          onToggleShowAll: _handleToggleShowAllRegions,
          onRegionSelected: (region) =>
              setState(() => _selectedRegionFilter = region),
          onViewDetail: _openSiteDetail,
          onApply: (site) => _applyToSite(context, site),
          onCancel: (site) => _cancelApplication(context, site),
          applications: applicationSnapshot,
          onRefresh: _hasRemoteSession ? _refreshRemoteSites : null,
        );
        return Column(
          children: [
            RemoteStatusBannerFlutter(
              isLoading: _hasRemoteSession && _isSitesLoading,
              error: _sitesLoadError,
              infoMessage: _hasRemoteSession ? '실서버 공고 목록 기준' : null,
              showInfoOnlyWhenNoError: true,
              onRefresh: _hasRemoteSession ? _refreshRemoteSites : null,
            ),
            Expanded(child: list),
          ],
        );
      case SiteTab.calendar:
        return const CalendarViewFlutter();
      case SiteTab.history:
        return HistoryDetailViewFlutter(
          currentUserName: _currentUserName(),
          currentUserPhone: _currentUserPhone(),
        );
      case SiteTab.userInfo:
        return UserInfoViewFlutter(
          name: _isKnownUser(_phoneController.text)
              ? _currentUserName()
              : (_nameController.text.trim().isEmpty
                    ? '사용자'
                    : _nameController.text.trim()),
          phone: _currentUserPhone() == '00000000000'
              ? '-'
              : _formatPhone(_currentUserPhone()),
          address: _addressController.text.trim().isEmpty
              ? '-'
              : _addressController.text.trim(),
          regions: preferredRegions,
          onEditProfile: () => setState(() => _view = UserView.editProfile),
        );
      case SiteTab.notices:
        return const NoticeViewFlutter();
      case SiteTab.games:
        return const GameCenterFlutter();
    }
  }

  List<Map<String, dynamic>> _filterSitesByRegion({
    required List<Map<String, dynamic>> sites,
    required List<String> preferredRegions,
    required String? selectedRegion,
    required bool showAllRegions,
  }) {
    final sorted = [...sites];
    if (selectedRegion != null) {
      return sorted.where((site) => site['region'] == selectedRegion).toList();
    }
    if (preferredRegions.isEmpty) return sorted;
    if (!showAllRegions) {
      return sorted
          .where((site) => preferredRegions.contains(site['region']))
          .toList();
    }
    final regionOrder = <String, int>{
      for (var i = 0; i < preferredRegions.length; i += 1)
        preferredRegions[i]: i,
    };
    sorted.sort((a, b) {
      final aRegion = a['region']?.toString() ?? '';
      final bRegion = b['region']?.toString() ?? '';
      final aRank = regionOrder[aRegion] ?? 9999;
      final bRank = regionOrder[bRegion] ?? 9999;
      if (aRank != bRank) return aRank.compareTo(bRank);
      final aDate = a['date']?.toString() ?? '';
      final bDate = b['date']?.toString() ?? '';
      return aDate.compareTo(bDate);
    });
    return sorted;
  }

  Widget _buildBody() {
    switch (_view) {
      case UserView.login:
        return _wrapAuthCard(
          Column(
            children: [
              const Text(
                '건설 인력 매칭',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '근로자 전용 앱',
                style: TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              LoginFlutter(
                phoneController: _phoneController,
                rememberMe: _rememberMe,
                onRememberChanged: (value) =>
                    setState(() => _rememberMe = value),
                onContinue: () => _handleLogin(context),
                isLoading: _isAuthLoading,
              ),
              const SizedBox(height: 8),
              const Text(
                '테스트 계정: 01011112222',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 8),
              const FooterFlutter(),
            ],
          ),
        );
      case UserView.authenticate:
        return _wrapAuthCard(
          AuthenticationFlutter(
            phone: _phoneController.text,
            onBack: () => setState(() => _view = UserView.login),
            codeController: _otpController,
            debugCode: _sentOtp,
            isLoading: _isAuthLoading,
            onResend: () => _sendOtp(_normalizePhone(_phoneController.text)),
            onVerified: () => _handleAuthSuccess(context),
            onRegister: () => _handleAuthSuccess(context),
          ),
        );
      case UserView.register:
        return _wrapAuthCard(
          RegistrationFormFlutter(
            phoneController: _phoneController,
            nameController: _nameController,
            idNumberController: _idNumberController,
            nationalityController: _nationalityController,
            addressController: _addressController,
            regionInputController: _regionInputController,
            preferredRegions: _preferredRegions,
            onAddRegion: _addPreferredRegion,
            onRemoveRegion: _removePreferredRegion,
            onMoveRegionUp: (index) => _movePreferredRegion(index, -1),
            onMoveRegionDown: (index) => _movePreferredRegion(index, 1),
            bankController: _bankController,
            accountController: _accountController,
            ownerController: _ownerController,
            gender: _gender,
            onGenderChanged: (value) =>
                setState(() => _gender = value ?? 'male'),
            onSubmit: () => _handleRegister(context),
          ),
        );
      case UserView.sites:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _buildSitesTabContent(),
        );
      case UserView.siteDetail:
        final sites = _sites;
        final selected =
            _selectedSite ?? (sites.isNotEmpty ? sites.first : null);
        if (selected == null) {
          return const Center(
            child: Text(
              '노출된 공고가 없습니다.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }
        final canServerNavLinks =
            _hasRemoteSession && selected['source']?.toString() == 'cwmp';
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: RemoteStatusBannerFlutter(
                isLoading: _isSiteDetailLoading,
                error: _siteDetailLoadError,
                showLoadingBar: true,
                margin: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SiteDetailFlutter(
                  site: selected,
                  application: _applicationForSite(selected),
                  onApply: () => _applyToSite(context, selected),
                  onCancel: () => _cancelApplication(context, selected),
                  canUseServerNavigationLinks: canServerNavLinks,
                  serverNavigationLinks: _siteDetailNavLinks,
                  isServerNavigationLinksLoading: _isSiteDetailNavLinksLoading,
                  serverNavigationLinksError: _siteDetailNavLinksError,
                  onReloadServerNavigationLinks: canServerNavLinks
                      ? _refreshSelectedSiteNavigationLinks
                      : null,
                ),
              ),
            ),
          ],
        );
      case UserView.editProfile:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: EditProfileFormFlutter(
            onCancel: () => setState(() => _view = UserView.sites),
            onSave: () => _saveProfileAndClose(context),
            addressController: _addressController,
            preferredRegions: _preferredRegions,
            regionInputController: _regionInputController,
            onAddRegion: _addPreferredRegion,
            onRemoveRegion: _removePreferredRegion,
            onMoveRegionUp: (index) => _movePreferredRegion(index, -1),
            onMoveRegionDown: (index) => _movePreferredRegion(index, 1),
          ),
        );
    }
  }

  BottomNavigationBar? _buildBottomNav() {
    if (_view != UserView.sites) return null;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: SiteTab.values.indexOf(_tab),
      onTap: (index) => setState(() => _tab = SiteTab.values[index]),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '리스트'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: '이력'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '내정보'),
        BottomNavigationBarItem(icon: Icon(Icons.campaign), label: '공지'),
        BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: '게임'),
      ],
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
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
