import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'apps/admin_app/main_flutter.dart';
import 'apps/admin_app/screens/admin_login_flutter.dart';
import 'apps/employer_app/main_flutter.dart';
import 'apps/user_app/main_flutter.dart';
import 'apps/user_app/widgets/authentication_flutter.dart';

enum RouterView { landing, user, admin, employer }

enum Role { user, employer }

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
  const RouterFlutter({super.key});

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
  UserView _userInitialView = UserView.sites;
  EmployerView _employerInitialView = EmployerView.dashboard;

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
  };

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _resetAuthFlow() {
    _authStep = AuthStep.login;
    _phoneToVerify = null;
    _authRole = null;
    _phoneController.clear();
  }

  void _handleRoleChange(Role role) {
    setState(() {
      _activeRole = role;
      _resetAuthFlow();
    });
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  bool _isKnownRolePhone(Role role, String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized.isEmpty) return false;
    final testHint = _normalizePhone(_roleConfig[role]!.testHint);
    return normalized == testHint;
  }

  void _openRoleApp({required Role role, required bool register}) {
    setState(() {
      if (role == Role.user) {
        _userInitialView = register ? UserView.register : UserView.sites;
        _view = RouterView.user;
      } else {
        _employerInitialView = register ? EmployerView.register : EmployerView.dashboard;
        _view = RouterView.employer;
      }
      _resetAuthFlow();
      _isAdminPanelOpen = false;
    });
  }

  void _handlePhoneLogin() {
    final raw = _phoneController.text.trim();
    final normalized = _normalizePhone(raw);
    if (normalized.isEmpty || !_isKnownRolePhone(_activeRole, normalized)) {
      _openRoleApp(role: _activeRole, register: true);
      return;
    }
    setState(() {
      _phoneController.text = normalized;
      _phoneToVerify = normalized;
      _authRole = _activeRole;
      _authStep = AuthStep.verify;
    });
  }

  void _handlePhoneAuthSuccess() {
    final role = _authRole;
    if (role == null) return;
    _openRoleApp(role: role, register: false);
  }

  void _handlePhoneRegister() {
    final role = _authRole ?? _activeRole;
    _openRoleApp(role: role, register: true);
  }

  void _handleBackToLanding() {
    setState(() {
      _view = RouterView.landing;
      _userInitialView = UserView.sites;
      _employerInitialView = EmployerView.dashboard;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        onPressed: _handleBackToLanding,
        child: const Text('모드 변경', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAdminPanel() {
    if (!_isAdminPanelOpen) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      right: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => setState(() => _isAdminPanelOpen = false),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF475569)),
                    splashRadius: 18,
                  ),
                ),
                AdminLoginFlutter(onLogin: _handleAdminLogin),
                const SizedBox(height: 12),
                const Text('테스트 계정: master / 1', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: Role.values.map((role) {
          final roleConfig = _roleConfig[role]!;
          final isActive = _activeRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => _handleRoleChange(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFF1F5F9) : Colors.transparent,
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
                    color: isActive ? roleConfig.accent : const Color(0xFF64748B),
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
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('로그인 / 회원가입', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
          const SizedBox(height: 8),
          const Text('비밀번호 없이 휴대폰 번호로 간편하게 시작하세요.', style: TextStyle(color: Color(0xFF64748B))),
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
            subtitle: const Text('로그인 상태 유지 브라우저에 로그인 정보가 저장됩니다.', style: TextStyle(color: Color(0xFF64748B))),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: config.accent),
              onPressed: _handlePhoneLogin,
              child: const Text('로그인 / 가입하기', style: TextStyle(color: Colors.white)),
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
        onVerified: _handlePhoneAuthSuccess,
        onRegister: _handlePhoneRegister,
      ),
    );
  }

  Widget _buildLanding() {
    if (kDebugMode) {
      debugPrint('_buildLanding view=$_view authStep=$_authStep remember=$_rememberMe adminPanel=$_isAdminPanelOpen');
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
                          child: const Icon(Icons.domain, size: 40, color: Colors.white),
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
                          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 24),
                        _buildRoleSelector(),
                        const SizedBox(height: 12),
                        Text(
                          config.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 24),
                        _authStep == AuthStep.verify ? _buildVerifyCard(config) : _buildLoginCard(config),
                        const SizedBox(height: 12),
                        Text(
                          '테스트 계정: ${config.testHint}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => setState(() => _isAdminPanelOpen = true),
                          child: const Text(
                            '관리자 로그인',
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
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
    switch (_view) {
      case RouterView.user:
        return _buildEmbeddedView(
          UserAppFlutter(
            embedded: true,
            initialView: _userInitialView,
          ),
        );
      case RouterView.employer:
        return _buildEmbeddedView(
          EmployerAppFlutter(
            embedded: true,
            initialView: _employerInitialView,
          ),
        );
      case RouterView.admin:
        return _buildEmbeddedView(
          const AdminAppFlutter(
            embedded: true,
            startAuthenticated: true,
          ),
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
