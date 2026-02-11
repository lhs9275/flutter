import 'package:flutter/material.dart';

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
  });

  final bool embedded;
  final UserView initialView;

  @override
  State<UserAppFlutter> createState() => _UserAppFlutterState();
}

class _UserAppFlutterState extends State<UserAppFlutter> {
  late UserView _view;
  SiteTab _tab = SiteTab.list;
  bool _rememberMe = true;
  Map<String, dynamic>? _selectedSite;
  String? _selectedRegionFilter;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ownerController = TextEditingController();
  String _gender = 'male';

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

  final List<Map<String, dynamic>> _sites = const [
    {
      'name': '서초 아파트 재건축',
      'address': '서울 서초구 반포동',
      'region': '서울',
      'type': '보통인부',
      'date': '2024-08-01',
      'pay': '150,000',
      'lat': 37.5036,
      'lng': 127.0056,
    },
    {
      'name': '판교 IT센터',
      'address': '경기 성남시 분당구',
      'region': '경기',
      'type': '조공',
      'date': '2024-08-02',
      'pay': '170,000',
      'lat': 37.3946,
      'lng': 127.1112,
    },
    {
      'name': '성수동 카페 리모델링',
      'address': '서울 성동구 성수동',
      'region': '서울',
      'type': '기공',
      'date': '2024-08-03',
      'pay': '220,000',
      'lat': 37.5448,
      'lng': 127.0564,
    },
  ];

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _idNumberController.dispose();
    _nationalityController.dispose();
    _regionController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  bool _isKnownUser(String phone) {
    return _normalizePhone(phone) == '01011112222';
  }

  void _handleLogin() {
    final raw = _phoneController.text.trim();
    final normalized = _normalizePhone(raw);
    if (normalized.isEmpty) {
      setState(() {
        _view = UserView.register;
      });
      return;
    }
    _phoneController.text = normalized;
    setState(() {
      _view = _isKnownUser(normalized) ? UserView.authenticate : UserView.register;
    });
  }

  void _handleAuthSuccess() {
    final phone = _phoneController.text.trim();
    setState(() {
      _view = _isKnownUser(phone) ? UserView.sites : UserView.register;
    });
  }

  void _handleRegister() {
    setState(() {
      _view = UserView.sites;
    });
  }

  String _formatPhone(String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized.length < 10) return phone;
    if (normalized.length == 10) {
      return '${normalized.substring(0, 3)}-${normalized.substring(3, 6)}-${normalized.substring(6)}';
    }
    return '${normalized.substring(0, 3)}-${normalized.substring(3, 7)}-${normalized.substring(7)}';
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
    final preferredRegion =
        _regionController.text.trim().isEmpty ? null : _regionController.text.trim();
    final availableRegions = _sites
        .map((site) => site['region'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    if (preferredRegion != null && !availableRegions.contains(preferredRegion)) {
      availableRegions.insert(0, preferredRegion);
    }
    final visibleSites = _filterSitesByRegion(
      preferredRegion: preferredRegion,
      selectedRegion: _selectedRegionFilter,
    );
    switch (_tab) {
      case SiteTab.list:
        return SiteListFlutter(
          sites: visibleSites,
          preferredRegion: preferredRegion,
          selectedRegion: _selectedRegionFilter,
          availableRegions: availableRegions,
          onRegionSelected: (region) => setState(() => _selectedRegionFilter = region),
          onViewDetail: (site) => setState(() {
            _selectedSite = site;
            _view = UserView.siteDetail;
          }),
          onApply: (_) {},
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
          region: _regionController.text.trim().isEmpty ? '-' : _regionController.text.trim(),
          onEditProfile: () => setState(() => _view = UserView.editProfile),
        );
      case SiteTab.notices:
        return const NoticeViewFlutter();
      case SiteTab.games:
        return const GameCenterFlutter();
    }
  }

  List<Map<String, dynamic>> _filterSitesByRegion({
    required String? preferredRegion,
    required String? selectedRegion,
  }) {
    final sorted = [..._sites];
    if (selectedRegion != null) {
      return sorted.where((site) => site['region'] == selectedRegion).toList();
    }
    if (preferredRegion == null) return sorted;
    final preferredSites = sorted.where((site) => site['region'] == preferredRegion).toList();
    final otherSites = sorted.where((site) => site['region'] != preferredRegion).toList();
    return [...preferredSites, ...otherSites];
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
                onContinue: _handleLogin,
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
            onVerified: _handleAuthSuccess,
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
            regionController: _regionController,
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SiteDetailFlutter(
            site: _selectedSite ?? _sites.first,
            onApply: () {},
          ),
        );
      case UserView.editProfile:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: EditProfileFormFlutter(
            onCancel: () => setState(() => _view = UserView.sites),
            onSave: () => setState(() => _view = UserView.sites),
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
