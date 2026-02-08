import 'package:flutter/material.dart';

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

  final ThemeData _theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    colorSchemeSeed: const Color(0xFF4F46E5),
    useMaterial3: false,
  );

  final List<Map<String, dynamic>> _sites = [
    {
      'name': '서초 아파트 재건축',
      'address': '서울 서초구 반포동',
      'jobType': '조공',
      'status': SiteStatus.approved,
      'createdAt': '2024-07-25 10:00'
    },
    {
      'name': '판교 IT센터',
      'address': '경기 성남시 분당구',
      'jobType': '보통인부',
      'status': SiteStatus.pending,
      'createdAt': '2024-08-01 09:20'
    },
    {
      'name': '홍대 리모델링',
      'address': '서울 마포구',
      'jobType': '기공',
      'status': SiteStatus.rejected,
      'createdAt': '2024-08-03 14:10'
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
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF374151)),
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
            const Text('현장 관리자 전용', style: TextStyle(color: Colors.white70)),
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
            const Text('테스트 계정: 01099998888', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF374151), style: BorderStyle.solid),
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
                    : '승인 대기';
            final statusColor = status == SiteStatus.approved
                ? Colors.green
                : status == SiteStatus.rejected
                    ? Colors.red
                    : Colors.amber;

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
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF374151)),
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
                          ),
                          child: Text(statusText, style: TextStyle(color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(site['address'] as String, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text('직종: ${site['jobType']}', style: const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 4),
                    Text('등록: ${site['createdAt']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
          _sectionCard(
            title: '현장 정보 입력',
            children: [
              TextField(decoration: const InputDecoration(labelText: '현장명', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '주소', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '담당자 이름', filled: true)),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: '담당자 연락처', filled: true)),
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
              child: const Text('등록 요청 (관리자 승인 필요)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobRequest() {
    final site = _sites[_selectedSiteIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _sectionCard(
            title: site['name'] as String,
            children: [
              Text(site['address'] as String, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF374151)),
                ),
                child: const Center(child: Text('지도 연동 화면 (네이버/카카오맵)')),
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
            title: '요청 내역',
            children: _jobRequests
                .map(
                  (job) => ListTile(
                    title: Text('${job['date']} · ${job['jobType']} ${job['count']}명'),
                    subtitle: Text('단가 ${job['rate']}원'),
                    trailing: Text(job['status']!, style: const TextStyle(color: Colors.white70)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotices() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _notices
          .map(
            (notice) => _sectionCard(
              title: notice['title']!,
              children: [
                Text(notice['date']!, style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 8),
                Text(notice['content']!, style: const TextStyle(color: Colors.white70)),
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
