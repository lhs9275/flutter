import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/mock_backend.dart';
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

void main() {
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
  final TextEditingController _regionInputController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
  String _gender = 'male';
  String? _sentOtp;
  final Set<String> _verifiedPhones = {};
  final Set<String> _registeredPhones = {'01011112222'};
  final List<String> _preferredRegions = [];
  final Map<String, ApplicationRecord> _applications = {};
  final Random _random = Random();

  static const Color _accent = Color(0xFF6366F1);

  final ThemeData _theme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    colorScheme: ColorScheme.fromSeed(seedColor: _accent, brightness: Brightness.light),
    primaryColor: _accent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8FAFC),
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
    useMaterial3: false,
  );

  List<Map<String, dynamic>> get _sites => MockBackend.approvedJobPosts();

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
    final phone = widget.initialPhone?.trim() ?? '';
    if (phone.isNotEmpty) {
      _phoneController.text = phone;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _idNumberController.dispose();
    _nationalityController.dispose();
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
    return _registeredPhones.contains(_normalizePhone(phone));
  }

  void _handleLogin(BuildContext context) {
    final raw = _phoneController.text.trim();
    final normalized = _normalizePhone(raw);
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴대폰 번호를 입력해주세요.')),
      );
      return;
    }
    _phoneController.text = normalized;
    if (_verifiedPhones.contains(normalized)) {
      setState(() {
        _view = _isKnownUser(normalized) ? UserView.sites : UserView.register;
      });
      return;
    }
    _sendOtp(normalized);
  }

  void _sendOtp(String phone) {
    final code = (_random.nextInt(900000) + 100000).toString();
    setState(() {
      _sentOtp = code;
      _otpController.clear();
      _view = UserView.authenticate;
    });
  }

  void _handleAuthSuccess(BuildContext context) {
    final input = _otpController.text.trim();
    final expected = _sentOtp;
    if (expected == null || input != expected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호가 올바르지 않습니다.')),
      );
      return;
    }
    final phone = _phoneController.text.trim();
    _verifiedPhones.add(phone);
    setState(() {
      _view = _isKnownUser(phone) ? UserView.sites : UserView.register;
    });
  }

  void _handleRegister() {
    final phone = _normalizePhone(_phoneController.text.trim());
    if (phone.isNotEmpty) {
      _registeredPhones.add(phone);
    }
    setState(() => _view = UserView.sites);
  }

  String _currentUserName() {
    if (_isKnownUser(_phoneController.text)) return '김테스트';
    final name = _nameController.text.trim();
    return name.isEmpty ? '근로자' : name;
  }

  String _currentUserPhone() {
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
    final region = value.trim();
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

  ApplicationRecord? _applicationForSite(Map<String, dynamic> site) {
    final id = site['id'] as String?;
    if (id == null) return null;
    return _applications[id];
  }

  Future<void> _applyToSite(BuildContext context, Map<String, dynamic> site) async {
    final id = site['id'] as String?;
    if (id == null) return;
    final record = _applications[id];
    if (record != null && record.status == ApplicationStatus.confirmed) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지원하기'),
        content: Text('${site['name']} 현장에 지원하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('지원')),
        ],
      ),
    );
    if (approved != true) return;
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('지원이 완료되었습니다.')),
    );
  }

  Future<void> _cancelApplication(BuildContext context, Map<String, dynamic> site) async {
    final id = site['id'] as String?;
    if (id == null) return;
    final record = _applications[id];
    if (record == null || record.status == ApplicationStatus.confirmed) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지원 취소'),
        content: Text('${site['name']} 지원을 취소하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('닫기')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('취소하기')),
        ],
      ),
    );
    if (approved != true) return;
    setState(() {
      _applications.remove(id);
    });
    MockBackend.cancelApplication(jobId: id, phone: _currentUserPhone());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('지원이 취소되었습니다.')),
    );
  }

  void _confirmApplicationDemo(BuildContext context, Map<String, dynamic> site) {
    final id = site['id'] as String?;
    if (id == null) return;
    final record = _applications[id];
    if (record == null) return;
    if (record.status == ApplicationStatus.confirmed) return;
    setState(() {
      _applications[id] = record.copyWith(
        status: ApplicationStatus.confirmed,
        confirmedAt: DateTime.now(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('확정 처리되었습니다.')),
    );
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
        final name = _isKnownUser(_phoneController.text)
            ? '김테스트'
            : (_nameController.text.trim().isEmpty ? '사용자' : _nameController.text.trim());
        return UserHeaderFlutter(
          title: '인력 관리 시스템',
          subtitle: '$name님 환영합니다.',
          onLogout: () => setState(() {
            _phoneController.clear();
            _selectedRegionFilter = null;
            _showAllRegions = false;
            _view = UserView.login;
          }),
        );
      case UserView.siteDetail:
        return AppBar(
          title: const Text('현장 상세'),
          leading: BackButton(onPressed: () => setState(() => _view = UserView.sites)),
        );
      case UserView.editProfile:
        return AppBar(
          title: const Text('프로필 수정'),
          leading: BackButton(onPressed: () => setState(() => _view = UserView.sites)),
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
    final availableRegions = sites
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
        return SiteListFlutter(
          sites: visibleSites,
          preferredRegions: preferredRegions,
          selectedRegion: _selectedRegionFilter,
          availableRegions: availableRegions,
          showAllRegions: _showAllRegions,
          onToggleShowAll: (value) => setState(() => _showAllRegions = value),
          onRegionSelected: (region) => setState(() => _selectedRegionFilter = region),
          onViewDetail: (site) => setState(() {
            _selectedSite = site;
            _view = UserView.siteDetail;
          }),
          onApply: (site) => _applyToSite(context, site),
          onCancel: (site) => _cancelApplication(context, site),
          applications: _applications,
        );
      case SiteTab.calendar:
        return const CalendarViewFlutter();
      case SiteTab.history:
        return const HistoryDetailViewFlutter();
      case SiteTab.userInfo:
        return UserInfoViewFlutter(
          name: _isKnownUser(_phoneController.text)
              ? '김테스트'
              : (_nameController.text.trim().isEmpty ? '사용자' : _nameController.text.trim()),
          phone: _phoneController.text.isEmpty ? '-' : _formatPhone(_phoneController.text),
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
      return sorted.where((site) => preferredRegions.contains(site['region'])).toList();
    }
    final regionOrder = <String, int>{
      for (var i = 0; i < preferredRegions.length; i += 1) preferredRegions[i]: i,
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
              const Text('건설 인력 매칭', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('근로자 전용 앱', style: TextStyle(color: Color(0xFF475569))),
              const SizedBox(height: 16),
              LoginFlutter(
                phoneController: _phoneController,
                rememberMe: _rememberMe,
                onRememberChanged: (value) => setState(() => _rememberMe = value),
                onContinue: () => _handleLogin(context),
              ),
              const SizedBox(height: 8),
              const Text('테스트 계정: 01011112222', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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
            onResend: () => _sendOtp(_normalizePhone(_phoneController.text)),
            onVerified: () => _handleAuthSuccess(context),
            onRegister: () => setState(() => _view = UserView.register),
          ),
        );
      case UserView.register:
        return _wrapAuthCard(
          RegistrationFormFlutter(
            phoneController: _phoneController,
            nameController: _nameController,
            idNumberController: _idNumberController,
            nationalityController: _nationalityController,
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
            onGenderChanged: (value) => setState(() => _gender = value ?? 'male'),
            onSubmit: _handleRegister,
          ),
        );
      case UserView.sites:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: _buildSitesTabContent(),
        );
      case UserView.siteDetail:
        final sites = _sites;
        final selected = _selectedSite ?? (sites.isNotEmpty ? sites.first : null);
        if (selected == null) {
          return const Center(
            child: Text('노출된 공고가 없습니다.', style: TextStyle(color: Color(0xFF64748B))),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SiteDetailFlutter(
            site: selected,
            application: _applicationForSite(selected),
            onApply: () => _applyToSite(context, selected),
            onCancel: () => _cancelApplication(context, selected),
            onConfirmDemo: () => _confirmApplicationDemo(context, selected),
          ),
        );
      case UserView.editProfile:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: EditProfileFormFlutter(
            onCancel: () => setState(() => _view = UserView.sites),
            onSave: () => setState(() => _view = UserView.sites),
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
