import 'package:flutter/material.dart';

import 'screens/admin_login_flutter.dart';
import 'screens/daily_work_management_flutter.dart';
import 'screens/member_management_flutter.dart';
import 'screens/notice_management_flutter.dart';
import 'screens/permission_management_flutter.dart';
import 'screens/site_management_flutter.dart';
import 'screens/wage_management_flutter.dart';
import 'widgets/main_layout_flutter.dart';

void main() {
  runApp(const AdminAppFlutter());
}

enum AdminView { members, sites, dailyWork, permissions, wage, notices }

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
  late bool _isAuthenticated;
  late AdminView _view;
  Map<String, String>? _selectedMember;

  final ThemeData _theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    colorSchemeSeed: const Color(0xFF0EA5E9),
    useMaterial3: false,
  );

  final List<Map<String, String>> _members = const [
    {'name': '김테스트', 'phone': '010-1111-2222', 'status': '활성'},
    {'name': '이철수', 'phone': '010-8000-0001', 'status': '대기'},
    {'name': '박지영', 'phone': '010-8000-0002', 'status': '활성'},
  ];

  final List<Map<String, String>> _sites = const [
    {'name': '서초 아파트 재건축', 'status': '승인됨'},
    {'name': '홍대 리모델링', 'status': '승인 대기'},
    {'name': '판교 IT센터', 'status': '반려'},
  ];

  @override
  void initState() {
    super.initState();
    _isAuthenticated = widget.startAuthenticated;
    _view = widget.initialView;
  }

  String _titleForView(AdminView view) {
    switch (view) {
      case AdminView.members:
        return '회원 관리';
      case AdminView.sites:
        return '현장 관리';
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
            decoration: const BoxDecoration(color: Color(0xFF1F2937)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('관리자 시스템', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('접속 중: master'),
              ],
            ),
          ),
          _drawerItem(AdminView.members, Icons.people, '회원 관리'),
          _drawerItem(AdminView.sites, Icons.location_city, '현장 관리'),
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
        );
      case AdminView.sites:
        return SiteManagementFlutter(sites: _sites);
      case AdminView.dailyWork:
        return const DailyWorkManagementFlutter();
      case AdminView.permissions:
        return const PermissionManagementFlutter();
      case AdminView.wage:
        return const WageManagementFlutter();
      case AdminView.notices:
        return const NoticeManagementFlutter();
    }
  }

  Widget _buildHome() {
    if (_isAuthenticated) {
      return MainLayoutFlutter(
        title: _titleForView(_view),
        drawer: _buildDrawer(),
        onLogout: () => setState(() {
          _isAuthenticated = false;
          _selectedMember = null;
        }),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildViewBody(),
          ),
        ),
      );
    }
    return Scaffold(
      body: AdminLoginFlutter(onLogin: () => setState(() => _isAuthenticated = true)),
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
