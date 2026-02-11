import 'package:flutter/material.dart';

import '../../data/mock_backend.dart';
import 'screens/admin_login_flutter.dart';
import 'screens/daily_work_management_flutter.dart';
import 'screens/job_request_management_flutter.dart';
import 'screens/member_management_flutter.dart';
import 'screens/notice_management_flutter.dart';
import 'screens/permission_management_flutter.dart';
import 'screens/site_management_flutter.dart';
import 'screens/wage_management_flutter.dart';
import 'widgets/main_layout_flutter.dart';

void main() {
  runApp(const AdminAppFlutter());
}

enum AdminView { members, sites, jobRequests, dailyWork, permissions, wage, notices }

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
  Map<String, dynamic>? _selectedMember;

  final ThemeData _theme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1), brightness: Brightness.light),
    primaryColor: const Color(0xFF6366F1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8FAFC),
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
    useMaterial3: false,
  );

  final List<Map<String, dynamic>> _members = [
    {'name': '김테스트', 'phone': '010-1111-2222', 'status': '활성', 'noShowCount': 0},
    {'name': '이철수', 'phone': '010-8000-0001', 'status': '대기', 'noShowCount': 2},
    {'name': '박지영', 'phone': '010-8000-0002', 'status': '활성', 'noShowCount': 1},
  ];

  List<Map<String, dynamic>> get _sites => MockBackend.sites;

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
                Text('관리자 시스템', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
        return JobRequestManagementFlutter(
          requests: MockBackend.jobRequests,
          onApprove: _approveJobRequest,
          onReject: _rejectJobRequest,
          onEdit: _editJobRequest,
          onAssignPriority: _assignPriorityWorker,
          onAssignSequence: _assignSequenceWorker,
          onResetAssignments: _resetAssignments,
        );
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
    setState(() => MockBackend.verifySitePhone(siteId));
  }

  void _approveSite(String siteId) {
    setState(() => MockBackend.updateSiteStatus(siteId, SiteStatus.approved, phoneVerified: true));
  }

  void _rejectSite(String siteId, String reason) {
    setState(() => MockBackend.updateSiteStatus(siteId, SiteStatus.rejected, reason: reason));
  }

  void _approveJobRequest(String jobId) {
    setState(() => MockBackend.updateJobRequestStatus(jobId, JobRequestStatus.approved));
  }

  void _rejectJobRequest(String jobId, String reason) {
    setState(() => MockBackend.updateJobRequestStatus(jobId, JobRequestStatus.rejected, reason: reason));
  }

  void _editJobRequest(String jobId, Map<String, dynamic> updates) {
    setState(() => MockBackend.updateJobRequest(jobId, updates));
  }

  void _assignPriorityWorker(String jobId) {
    final assigned = MockBackend.assignWorker(jobId, priority: true);
    setState(() {});
    if (assigned == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배정 가능한 인력이 없습니다.')),
      );
    }
  }

  void _assignSequenceWorker(String jobId) {
    final assigned = MockBackend.assignWorker(jobId, priority: false);
    setState(() {});
    if (assigned == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배정 가능한 인력이 없습니다.')),
      );
    }
  }

  void _resetAssignments(String jobId) {
    setState(() => MockBackend.resetAssignments(jobId));
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
