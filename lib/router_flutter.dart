import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'apps/admin_app/main_flutter.dart';
import 'apps/admin_app/screens/admin_login_flutter.dart';
import 'apps/employer_app/main_flutter.dart';
import 'apps/user_app/main_flutter.dart';
import 'apps/user_app/widgets/authentication_flutter.dart';
import 'apps/user_app/widgets/icons/loading_spinner_flutter.dart';
import 'data/cwmp_api_models.dart';
import 'data/cwmp_api_repository.dart';
import 'data/cwmp_session_store.dart';

enum RouterView { landing, user, admin, employer }

enum Role { user, employer, admin }

enum AuthStep { login, verify }

class RoleConfig {
  const RoleConfig({
    required this.label,
    required this.description,
    required this.testHint,
    required this.accent,
  });

  final String label;
  final String description;
  final String testHint;
  final Color accent;
}

class RouterFlutter extends StatefulWidget {
  const RouterFlutter({super.key, this.initialSession});

  final CwmpSessionSnapshot? initialSession;

  @override
  State<RouterFlutter> createState() => _RouterFlutterState();
}

class _RouterFlutterState extends State<RouterFlutter> {
  RouterView _view = RouterView.landing;
  Role _activeRole = Role.user;
  Role? _authRole;
  AuthStep _authStep = AuthStep.login;
  String? _phoneToVerify;
  bool _rememberMe = true;
  bool _isAdminPanelOpen = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _sentOtp;
  bool _isAuthLoading = false;
  bool _isSessionBootstrapping = true;
  UserView _userInitialView = UserView.sites;
  EmployerView _employerInitialView = EmployerView.dashboard;
  String? _userInitialPhone;

  final Map<Role, RoleConfig> _roleConfig = const {
    Role.user: RoleConfig(
      label: '근로자',
      description: '내 주변 현장을 찾고 간편하게 지원하세요.',
      testHint: '01011112222',
      accent: Color(0xFF6366F1),
    ),
    Role.employer: RoleConfig(
      label: '구인자',
      description: '현장 등록부터 출석 관리까지 한 번에.',
      testHint: '01099998888',
      accent: Color(0xFF4F46E5),
    ),
    Role.admin: RoleConfig(
      label: '관리자',
      description: '승인/반려, 매칭 확정, 정산 업무를 관리합니다.',
      testHint: '01000000000',
      accent: Color(0xFF0F172A),
    ),
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSession;
    if (initial != null && initial.accessToken.isNotEmpty) {
      _applySavedSession(initial);
      _isSessionBootstrapping = false;
    } else {
      _bootstrapSavedSession();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapSavedSession() async {
    try {
      final session = await CwmpSessionStore.read();
      if (kDebugMode) {
        debugPrint(
          '[Router] bootstrap session found=${session != null} role=${session?.role} phone=${session?.phoneNumber}',
        );
      }
      if (!mounted) return;
      if (session != null && session.accessToken.isNotEmpty) {
        _applySavedSession(session);
      }
    } finally {
      if (mounted) {
        setState(() => _isSessionBootstrapping = false);
      }
    }
  }

  void _applySavedSession(CwmpSessionSnapshot session) {
    if (kDebugMode) {
      debugPrint(
        '[Router] apply saved session role=${session.role} phone=${session.phoneNumber}',
      );
    }
    setState(() {
      switch (session.role) {
        case CwmpUserRole.worker:
          _activeRole = Role.user;
          _userInitialView = UserView.sites;
          _userInitialPhone = session.phoneNumber.isEmpty
              ? null
              : session.phoneNumber;
          _view = RouterView.user;
          break;
        case CwmpUserRole.employer:
          _activeRole = Role.employer;
          _employerInitialView = EmployerView.dashboard;
          _view = RouterView.employer;
          break;
        case CwmpUserRole.admin:
          _view = RouterView.admin;
          break;
      }
    });
  }

  void _resetAuthFlow() {
    _authStep = AuthStep.login;
    _phoneToVerify = null;
    _authRole = null;
    _phoneController.clear();
    _otpController.clear();
    _sentOtp = null;
  }

  void _handleRoleChange(Role role) {
    setState(() {
      _activeRole = role;
      _resetAuthFlow();
      _isAdminPanelOpen = role == Role.admin;
    });
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  CwmpUserRole _toApiRole(Role role) {
    switch (role) {
      case Role.user:
        return CwmpUserRole.worker;
      case Role.employer:
        return CwmpUserRole.employer;
      case Role.admin:
        return CwmpUserRole.admin;
    }
  }

  void _openRoleApp({
    required Role role,
    required bool register,
    String? phone,
  }) {
    final normalized = phone == null ? '' : _normalizePhone(phone);
    setState(() {
      switch (role) {
        case Role.user:
          _userInitialView = register ? UserView.register : UserView.sites;
          _userInitialPhone = normalized.isEmpty ? null : normalized;
          _view = RouterView.user;
          break;
        case Role.employer:
          _employerInitialView = register
              ? EmployerView.register
              : EmployerView.dashboard;
          _view = RouterView.employer;
          break;
        case Role.admin:
          _view = RouterView.admin;
          break;
      }
      _resetAuthFlow();
      _isAdminPanelOpen = false;
    });
  }

  Future<void> _handlePhoneLogin() async {
    if (_isAuthLoading) return;
    final raw = _phoneController.text.trim();
    final normalized = _normalizePhone(raw);
    if (normalized.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 번호를 입력해주세요.')));
      return;
    }
    _phoneController.text = normalized;
    _phoneToVerify = normalized;
    _authRole = _activeRole;
    await _requestOtp(normalized, _activeRole);
  }

  Future<void> _handlePhoneAuthSuccess(BuildContext context) async {
    if (_isAuthLoading) return;
    final input = _otpController.text.trim();
    final phone = _phoneToVerify ?? _normalizePhone(_phoneController.text);
    final role = _authRole ?? _activeRole;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('휴대폰 번호를 다시 입력해주세요.')));
      return;
    }
    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증번호를 입력해주세요.')));
      return;
    }
    setState(() => _isAuthLoading = true);
    try {
      final response = await CwmpApiRepository.instance.verifyPhoneAuth(
        phoneNumber: phone,
        code: input,
        role: _toApiRole(role),
      );
      if (!mounted) return;
      _openRoleApp(
        role: role,
        register: response.firstLogin,
        phone: response.user.phoneNumber,
      );
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

  Future<void> _requestOtp(String phone, Role role) async {
    if (_isAuthLoading) return;
    setState(() => _isAuthLoading = true);
    try {
      final response = await CwmpApiRepository.instance.requestPhoneAuth(
        phoneNumber: phone,
        role: _toApiRole(role),
      );
      if (!mounted) return;
      setState(() {
        _phoneToVerify = response.phoneNumber.isEmpty
            ? phone
            : response.phoneNumber;
        _sentOtp = response.debugCode;
        _otpController.clear();
        _authStep = AuthStep.verify;
      });
      final deliveryStatus = response.deliveryStatus.toLowerCase();
      if (deliveryStatus == 'failed' || deliveryStatus == 'unavailable') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인증번호 발송 상태: ${response.deliveryStatus}')),
        );
      }
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

  Future<void> _handlePhoneRegister() async {
    // Backend registration is completed by OTP verification; reuse the same flow.
    await _handlePhoneAuthSuccess(context);
  }

  void _handleBackToLanding() {
    setState(() {
      _view = RouterView.landing;
      _activeRole = Role.user;
      _userInitialView = UserView.sites;
      _employerInitialView = EmployerView.dashboard;
      _userInitialPhone = null;
      _resetAuthFlow();
      _isAdminPanelOpen = false;
    });
  }

  void _handleAdminLogin() {
    setState(() {
      _view = RouterView.admin;
      _isAdminPanelOpen = false;
    });
  }

  Widget _buildModeSwitchButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: _handleBackToLanding,
        child: const Text(
          '모드 변경',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAdminPanel() {
    return const SizedBox.shrink();
  }

  Widget _buildRoleSelector() {
    final roles = _isAdminPanelOpen
        ? const [Role.user, Role.employer, Role.admin]
        : const [Role.user, Role.employer];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: roles.map((role) {
          final roleConfig = _roleConfig[role]!;
          final isActive = _activeRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => _handleRoleChange(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFF1F5F9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? roleConfig.accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  roleConfig.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive
                        ? roleConfig.accent
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoginCard(RoleConfig config) {
    final isAdmin = _activeRole == Role.admin;
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAdmin ? '관리자 로그인' : '로그인 / 회원가입',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: config.accent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '비밀번호 없이 휴대폰 번호로 간편하게 시작하세요.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '휴대폰 번호',
              hintText: "'-' 없이 입력",
              filled: true,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _rememberMe,
            onChanged: (value) => setState(() => _rememberMe = value),
            subtitle: const Text(
              '로그인 상태 유지 브라우저에 로그인 정보가 저장됩니다.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: config.accent),
              onPressed: _isAuthLoading ? null : _handlePhoneLogin,
              child: _isAuthLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingSpinnerFlutter(size: 18),
                        SizedBox(width: 8),
                        Text('요청 중...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : Text(
                      isAdmin ? '로그인' : '로그인 / 가입하기',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyCard(RoleConfig config) {
    final phone = _phoneToVerify ?? config.testHint;
    return _AuthCard(
      child: AuthenticationFlutter(
        phone: phone,
        onBack: () => setState(() => _resetAuthFlow()),
        codeController: _otpController,
        debugCode: _sentOtp,
        isLoading: _isAuthLoading,
        onResend: () {
          final phone =
              _phoneToVerify ?? _normalizePhone(_phoneController.text);
          final role = _authRole ?? _activeRole;
          if (phone.isEmpty) return;
          _requestOtp(phone, role);
        },
        onVerified: () => _handlePhoneAuthSuccess(context),
        onRegister: _handlePhoneRegister,
        showRegisterButton: (_authRole ?? _activeRole) != Role.admin,
      ),
    );
  }

  Widget _buildLanding() {
    if (kDebugMode) {
      debugPrint(
        '_buildLanding view=$_view authStep=$_authStep remember=$_rememberMe adminPanel=$_isAdminPanelOpen',
      );
    }
    final config = _roleConfig[_activeRole]!;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33243388),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.domain,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '건설 인력 매칭 플랫폼',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '현장과 인력을 잇는 스마트한 솔루션.\n'
                          '채용부터 급여 정산까지, 하나의 플랫폼에서 관리하세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildRoleSelector(),
                        const SizedBox(height: 12),
                        Text(
                          config.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _authStep == AuthStep.verify
                            ? _buildVerifyCard(config)
                            : _buildLoginCard(config),
                        const SizedBox(height: 12),
                        Text(
                          '테스트 계정: ${config.testHint}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => _handleRoleChange(Role.admin),
                          child: const Text(
                            '관리자 전화인증 로그인',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          '© 2024 Construction Workforce Matching Platform. All rights reserved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildAdminPanel(),
        ],
      ),
    );
  }

  Widget _buildEmbeddedView(Widget child) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        _buildModeSwitchButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSessionBootstrapping) {
      return const Material(
        color: Color(0xFFF1F5F9),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_view) {
      case RouterView.user:
        return _buildEmbeddedView(
          UserAppFlutter(
            embedded: true,
            initialView: _userInitialView,
            initialPhone: _userInitialPhone,
          ),
        );
      case RouterView.employer:
        return _buildEmbeddedView(
          EmployerAppFlutter(embedded: true, initialView: _employerInitialView),
        );
      case RouterView.admin:
        return _buildEmbeddedView(
          const AdminAppFlutter(embedded: true, startAuthenticated: true),
        );
      case RouterView.landing:
        return _buildLanding();
    }
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}
