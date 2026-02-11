import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../widgets/attendance_qr_helper.dart';
import '../../../widgets/map_launcher_card_flutter.dart';

void main() {
  runApp(const EmployerAppFlutter());
}

enum EmployerView { login, auth, register, dashboard, siteRegister, jobRequest, notices }

enum SiteStatus { approved, pending, rejected }

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
  late EmployerView _view;
  bool _rememberMe = true;
  int _selectedSiteIndex = 0;
  bool _showNoShowOnly = false;
  AttendanceQrPayload? _attendanceQr;

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

  final List<Map<String, dynamic>> _sites = [
    {
      'name': '서초 아파트 재건축',
      'address': '서울 서초구 반포동',
      'jobType': '조공',
      'status': SiteStatus.approved,
      'createdAt': '2024-07-25 10:00',
      'lat': 37.5036,
      'lng': 127.0056,
    },
    {
      'name': '판교 IT센터',
      'address': '경기 성남시 분당구',
      'jobType': '보통인부',
      'status': SiteStatus.pending,
      'createdAt': '2024-08-01 09:20',
      'lat': 37.3946,
      'lng': 127.1112,
    },
    {
      'name': '홍대 리모델링',
      'address': '서울 마포구',
      'jobType': '기공',
      'status': SiteStatus.rejected,
      'createdAt': '2024-08-03 14:10',
      'lat': 37.5563,
      'lng': 126.9227,
    },
  ];

  final List<Map<String, String>> _notices = const [
    {
      'title': '현장 등록 절차 변경 안내',
      'date': '2024-08-05',
      'content': '필수 서류 제출 후 승인까지 1~2일 소요됩니다.'
    },
    {
      'title': '구인 공고 운영 정책',
      'date': '2024-08-01',
      'content': '허위 공고는 즉시 비공개 처리됩니다.'
    },
  ];

  final List<Map<String, String>> _jobRequests = const [
    {
      'date': '2024-08-06',
      'jobType': '조공',
      'count': '3',
      'rate': '150,000',
      'status': '승인 대기',
    },
    {
      'date': '2024-08-07',
      'jobType': '보통인부',
      'count': '5',
      'rate': '160,000',
      'status': '배정 완료',
    },
  ];

  final List<Map<String, dynamic>> _assignedWorkers = const [
    {'name': '김근로', 'role': '조공', 'phone': '010-1234-5678', 'noShowCount': 0},
    {'name': '이인부', 'role': '보통인부', 'phone': '010-2222-3333', 'noShowCount': 1},
    {'name': '박기공', 'role': '기공', 'phone': '010-4444-5555', 'noShowCount': 3},
  ];

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
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
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => setState(() => _view = EmployerView.login),
            ),
          ],
        );
      case EmployerView.siteRegister:
        return AppBar(
          title: const Text('신규 현장 등록'),
          leading: BackButton(onPressed: () => setState(() => _view = EmployerView.dashboard)),
        );
      case EmployerView.jobRequest:
        return AppBar(
          title: const Text('구인 요청'),
          leading: BackButton(onPressed: () => setState(() => _view = EmployerView.dashboard)),
        );
      case EmployerView.notices:
        return AppBar(
          title: const Text('파트너 공지사항'),
          leading: BackButton(onPressed: () => setState(() => _view = EmployerView.dashboard)),
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('구인자 파트너 앱', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('현장 관리자 전용', style: TextStyle(color: Color(0xFF475569))),
            const SizedBox(height: 24),
            _sectionCard(
              title: '로그인',
              children: [
                TextField(
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: '휴대폰 번호', filled: true),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _rememberMe,
                  onChanged: (value) => setState(() => _rememberMe = value),
                  title: const Text('로그인 상태 유지'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _view = EmployerView.auth),
                    child: const Text('인증번호 받기'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('테스트 계정: 01099998888', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAuth() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _sectionCard(
          title: '인증번호 입력',
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '인증번호 6자리', filled: true),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _view = EmployerView.dashboard),
                child: const Text('인증 완료 (기존 계정)'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() => _view = EmployerView.register),
              child: const Text('신규 가입하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _sectionCard(
            title: '기본 정보',
            children: [
              TextField(decoration: const InputDecoration(labelText: '이름', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '상호명 (건설사)', filled: true)),
            ],
          ),
          _sectionCard(
            title: '명함 첨부',
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                ),
                child: const Center(child: Text('명함 촬영 또는 업로드')),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _view = EmployerView.dashboard),
              child: const Text('가입 완료'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('내 현장 목록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _view = EmployerView.notices),
                    icon: const Icon(Icons.campaign),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _view = EmployerView.siteRegister),
                    icon: const Icon(Icons.add_business),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          ..._sites.asMap().entries.map((entry) {
            final index = entry.key;
            final site = entry.value;
            final status = site['status'] as SiteStatus;
            final statusText = status == SiteStatus.approved
                ? '승인됨'
                : status == SiteStatus.rejected
                    ? '반려됨'
                    : '전화 확인 대기';
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
                  setState(() {
                    _selectedSiteIndex = index;
                    _view = EmployerView.jobRequest;
                  });
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.7)),
                          ),
                          child: Text(statusText, style: TextStyle(color: statusTextColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(site['address'] as String, style: const TextStyle(color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Text('직종: ${site['jobType']}', style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text('등록: ${site['createdAt']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    if (status == SiteStatus.approved)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedSiteIndex = index;
                              _view = EmployerView.jobRequest;
                            });
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
            title: '사업자 정보',
            children: [
              TextField(decoration: const InputDecoration(labelText: '사업자명', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '사업자등록번호', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '대표자명', filled: true)),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '사업자 연락처', filled: true),
              ),
            ],
          ),
          _sectionCard(
            title: '현장 대리인 연락처',
            children: [
              TextField(decoration: const InputDecoration(labelText: '대리인 이름', filled: true)),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '대리인 연락처', filled: true),
              ),
            ],
          ),
          _sectionCard(
            title: '현장 정보 입력',
            children: [
              TextField(decoration: const InputDecoration(labelText: '현장명', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '주소', filled: true)),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                items: const [
                  DropdownMenuItem(value: '보통인부', child: Text('보통인부')),
                  DropdownMenuItem(value: '조공', child: Text('조공')),
                  DropdownMenuItem(value: '기공', child: Text('기공')),
                ],
                onChanged: (_) {},
                decoration: const InputDecoration(labelText: '직종', filled: true),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _view = EmployerView.dashboard),
              child: const Text('등록 요청 (전화 확인 후 승인)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobRequest() {
    final site = _sites[_selectedSiteIndex];
    final qrPayload = _attendanceQr;
    final isQrExpired = qrPayload != null && DateTime.now().isAfter(qrPayload.expiresAtDate);
    final filteredWorkers = _showNoShowOnly
        ? _assignedWorkers.where((worker) => (worker['noShowCount'] as int? ?? 0) > 0).toList()
        : _assignedWorkers;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _sectionCard(
            title: site['name'] as String,
            children: [
              Text(site['address'] as String, style: const TextStyle(color: Color(0xFF475569))),
              const SizedBox(height: 12),
              MapLauncherCardFlutter(
                name: site['name'] as String,
                address: site['address'] as String,
                latitude: site['lat'] as double?,
                longitude: site['lng'] as double?,
                height: 120,
              ),
              const SizedBox(height: 12),
              const Text('인력 요청', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(decoration: const InputDecoration(labelText: '근무일 (YYYY-MM-DD)', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '인원', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '단가', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '특별 요청사항', filled: true)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () {}, child: const Text('구인 요청하기')),
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
                  onPressed: () => _generateAttendanceQr(context, site['name'] as String),
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
                  child: const Center(
                    child: Text('QR 생성 후 근로자에게 스캔 요청'),
                  ),
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
                          color: isQrExpired ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
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
                      isQrExpired ? '만료됨 · 다시 생성 필요' : '만료 ${formatTime(qrPayload.expiresAtDate)}',
                      style: TextStyle(
                        color: isQrExpired ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '발급 ${formatDateTime(qrPayload.issuedAtDate)}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
          _sectionCard(
            title: '요청 내역',
            children: _jobRequests
                .map(
                  (job) => ListTile(
                    title: Text('${job['date']} · ${job['jobType']} ${job['count']}명'),
                    subtitle: Text('단가 ${job['rate']}원'),
                    trailing: Text(job['status']!, style: const TextStyle(color: Color(0xFF475569))),
                  ),
                )
                .toList(),
          ),
          _sectionCard(
            title: '배정 인력',
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('전체'),
                    selected: !_showNoShowOnly,
                    onSelected: (_) => setState(() => _showNoShowOnly = false),
                    selectedColor: const Color(0xFFDBEAFE),
                    labelStyle: TextStyle(
                      color: !_showNoShowOnly ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('노쇼 있음'),
                    selected: _showNoShowOnly,
                    onSelected: (_) => setState(() => _showNoShowOnly = true),
                    selectedColor: const Color(0xFFFEE2E2),
                    labelStyle: TextStyle(
                      color: _showNoShowOnly ? const Color(0xFFB91C1C) : const Color(0xFF475569),
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${worker['role']} · ${worker['phone']}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
          ),
        ],
      ),
    );
  }

  Future<void> _generateAttendanceQr(BuildContext context, String siteName) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 연결이 필요합니다.')),
      );
      return;
    }
    setState(() {
      _attendanceQr = AttendanceQrPayload.create(siteName: siteName);
    });
  }

  Widget _buildNotices() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _notices
          .map(
            (notice) => _sectionCard(
              title: notice['title']!,
              children: [
                Text(notice['date']!, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Text(notice['content']!, style: const TextStyle(color: Color(0xFF475569))),
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
        border: Border.all(color: hasNoShow ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5F5)),
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
