import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/mock_backend.dart';
import '../../../widgets/attendance_qr_helper.dart';
import '../../../widgets/map_launcher_card_flutter.dart';

void main() {
  runApp(const EmployerAppFlutter());
}

enum EmployerView { login, auth, register, dashboard, siteRegister, jobRequest, notices }

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

  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _siteAddressController = TextEditingController();
  String _siteJobType = '조공';
  final TextEditingController _bizNameController = TextEditingController();
  final TextEditingController _bizNumberController = TextEditingController();
  final TextEditingController _representativeController = TextEditingController();
  final TextEditingController _bizPhoneController = TextEditingController();
  final TextEditingController _agentNameController = TextEditingController();
  final TextEditingController _agentPhoneController = TextEditingController();

  final TextEditingController _requestDateController = TextEditingController();
  final TextEditingController _requestTimeController = TextEditingController();
  final TextEditingController _requestCountController = TextEditingController();
  final TextEditingController _requestRateController = TextEditingController();
  final TextEditingController _requestMeetingController = TextEditingController();
  final TextEditingController _requestNotesController = TextEditingController();
  final TextEditingController _requestMemoController = TextEditingController();

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

  List<Map<String, dynamic>> get _sites => MockBackend.sites;

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

  List<Map<String, dynamic>> _jobRequestsForSite(String siteId) {
    return MockBackend.jobRequestsForSite(siteId);
  }

  List<Map<String, dynamic>> _assignedWorkersForSite(String siteId) {
    return MockBackend.confirmedApplicantsForSite(siteId);
  }

  static const List<Map<String, String>> _laborOptions = [
    {'value': '1.0', 'label': '1.0'},
    {'value': '0.5', 'label': '조퇴 0.5'},
    {'value': '1.5', 'label': '야근 1.5'},
    {'value': 'custom', 'label': '기타'},
  ];

  List<Map<String, dynamic>> _todayWorkersForSite(String siteId) {
    return MockBackend.todayWorkersForSite(siteId);
  }

  final Map<String, TextEditingController> _customLaborControllers = {};

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
    _requestDateController.text = _formatDate(DateTime.now());
    _requestTimeController.text = '07:30 ~ 17:00';
    _requestCountController.text = '1';
    _requestRateController.text = '150,000';
    _requestMeetingController.text = '현장 정문';
  }

  @override
  void dispose() {
    for (final controller in _customLaborControllers.values) {
      controller.dispose();
    }
    _siteNameController.dispose();
    _siteAddressController.dispose();
    _bizNameController.dispose();
    _bizNumberController.dispose();
    _representativeController.dispose();
    _bizPhoneController.dispose();
    _agentNameController.dispose();
    _agentPhoneController.dispose();
    _requestDateController.dispose();
    _requestTimeController.dispose();
    _requestCountController.dispose();
    _requestRateController.dispose();
    _requestMeetingController.dispose();
    _requestNotesController.dispose();
    _requestMemoController.dispose();
    super.dispose();
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

  TextEditingController _customLaborControllerFor(String entryKey, String initial) {
    final controller = _customLaborControllers.putIfAbsent(
      entryKey,
      () => TextEditingController(text: initial),
    );
    if (controller.text != initial) {
      controller.text = initial;
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
    return controller;
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
              TextField(
                controller: _siteNameController,
                decoration: const InputDecoration(labelText: '현장명', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _siteAddressController,
                decoration: const InputDecoration(labelText: '주소', filled: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                items: const [
                  DropdownMenuItem(value: '보통인부', child: Text('보통인부')),
                  DropdownMenuItem(value: '조공', child: Text('조공')),
                  DropdownMenuItem(value: '기공', child: Text('기공')),
                ],
                value: _siteJobType,
                onChanged: (value) => setState(() => _siteJobType = value?.toString() ?? '조공'),
                decoration: const InputDecoration(labelText: '직종', filled: true),
              ),
            ],
          ),
          _sectionCard(
            title: '사업자 정보',
            children: [
              TextField(
                controller: _bizNameController,
                decoration: const InputDecoration(labelText: '사업자명', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bizNumberController,
                decoration: const InputDecoration(labelText: '사업자등록번호', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _representativeController,
                decoration: const InputDecoration(labelText: '대표자명', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bizPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '사업자 연락처', filled: true),
              ),
            ],
          ),
          _sectionCard(
            title: '현장 대리인 연락처',
            children: [
              TextField(
                controller: _agentNameController,
                decoration: const InputDecoration(labelText: '이름', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _agentPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '연락처', filled: true),
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
    if (sites.isEmpty) {
      return const Center(
        child: Text('등록된 현장이 없습니다.', style: TextStyle(color: Color(0xFF64748B))),
      );
    }
    final safeIndex = _selectedSiteIndex >= sites.length ? 0 : _selectedSiteIndex;
    final site = sites[safeIndex];
    final siteId = site['id'] as String? ?? '';
    final qrPayload = _attendanceQr;
    final isQrExpired = qrPayload != null && DateTime.now().isAfter(qrPayload.expiresAtDate);
    final todayLabel = _formatDate(DateTime.now());
    final todayWorkers = siteId.isEmpty ? <Map<String, dynamic>>[] : _todayWorkersForSite(siteId);
    final canBulkApprove = todayWorkers.any(
      (worker) => worker['approved'] != true && _isWorkerReadyForApproval(worker),
    );
    final assignedWorkers = siteId.isEmpty ? <Map<String, dynamic>>[] : _assignedWorkersForSite(siteId);
    final filteredWorkers = _showNoShowOnly
        ? assignedWorkers.where((worker) => (worker['noShowCount'] as int? ?? 0) > 0).toList()
        : assignedWorkers;
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
              TextField(
                controller: _requestDateController,
                decoration: const InputDecoration(labelText: '근무일 (YYYY-MM-DD)', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestTimeController,
                decoration: const InputDecoration(labelText: '근무 시간', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '인원', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '단가', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestMeetingController,
                decoration: const InputDecoration(labelText: '집결지', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestNotesController,
                decoration: const InputDecoration(labelText: '준비물/특이사항', filled: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _requestMemoController,
                decoration: const InputDecoration(labelText: '구인자 메모', filled: true),
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
            title: '오늘 일한 근로자',
            children: [
              Text('근무일 $todayLabel', style: const TextStyle(color: Color(0xFF64748B))),
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
                                final entryKey = worker['entryKey']?.toString() ?? '';
                                if (entryKey.isNotEmpty) {
                                  MockBackend.updateWorkEntry(entryKey: entryKey, approved: true);
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
                  child: Text('오늘 근무한 근로자가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8))),
                )
              else
                ...todayWorkers.map(
                      (worker) => _buildTodayWorkerCard(worker),
                    ),
            ],
          ),
          _sectionCard(
            title: '요청 내역',
            children: () {
              final jobs = _jobRequestsForSite(site['id'] as String? ?? '');
              if (jobs.isEmpty) {
                return const [
                  Text('요청 내역이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8))),
                ];
              }
              return jobs
                  .map(
                    (job) {
                      final status = job['status'] as JobRequestStatus? ?? JobRequestStatus.pending;
                      final statusText = MockBackend.jobStatusLabel(status);
                      final note = job['rejectReason'] ?? job['adminNote'];
                      final assigned = MockBackend.assignedCountForJob(job);
                      final total = job['count'] as int? ?? 0;
                      final assignmentLabel = total > 0 ? '배정 $assigned/$total명' : null;
                      final applicants = MockBackend.applicantsForJob(job['id'] as String);
                      final confirmedApplicants = applicants
                          .where((applicant) =>
                              applicant['status'] == ApplicantStatus.confirmed)
                          .toList();
                      final assignedPriority = List<String>.from(job['assignedPriority'] as List? ?? []);
                      final assignedSequence = List<String>.from(job['assignedSequence'] as List? ?? []);
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
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(statusText, style: const TextStyle(color: Color(0xFF475569))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '단가 ${job['rate']}원${assignmentLabel == null ? '' : ' · $assignmentLabel'}',
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                            if (note != null) ...[
                              const SizedBox(height: 4),
                              Text(note.toString(), style: const TextStyle(color: Color(0xFF94A3B8))),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              '지원자 ${applicants.length}명 · 확정 ${confirmedApplicants.length}명',
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                            if (applicants.isEmpty)
                              const Text('지원자가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: applicants
                                    .map(
                                      (applicant) {
                                        final name = applicant['name']?.toString() ?? '-';
                                        final status = applicant['status'] as ApplicantStatus? ?? ApplicantStatus.applied;
                                        final isConfirmed = status == ApplicantStatus.confirmed;
                                        return Chip(
                                          label: Text(isConfirmed ? '$name · 확정' : name),
                                          backgroundColor: isConfirmed
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFF1F5F9),
                                          labelStyle: TextStyle(
                                            color: isConfirmed ? const Color(0xFF166534) : const Color(0xFF475569),
                                          ),
                                        );
                                      },
                                    )
                                    .toList(),
                              ),
                            if (assignedPriority.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('우선 배정', style: TextStyle(color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: assignedPriority
                                    .map((name) => Chip(label: Text(name), backgroundColor: const Color(0xFFEFF6FF)))
                                    .toList(),
                              ),
                            ],
                            if (assignedSequence.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('순차 배정', style: TextStyle(color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: assignedSequence
                                    .map((name) => Chip(label: Text(name), backgroundColor: const Color(0xFFF1F5F9)))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  )
                  .toList();
            }(),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _adjustNoShow(context, worker['phone'] as String? ?? '', 1),
                                  child: const Text('노쇼 +1'),
                                ),
                                OutlinedButton(
                                  onPressed: (worker['noShowCount'] as int? ?? 0) > 0
                                      ? () => _adjustNoShow(context, worker['phone'] as String? ?? '', -1)
                                      : null,
                                  child: const Text('노쇼 -1'),
                                ),
                                TextButton(
                                  onPressed: (worker['noShowCount'] as int? ?? 0) > 0
                                      ? () => _resetNoShow(context, worker['phone'] as String? ?? '')
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
          ),
        ],
      ),
    );
  }

  void _submitSiteRegistration(BuildContext context) {
    final name = _siteNameController.text.trim();
    final address = _siteAddressController.text.trim();
    final bizName = _bizNameController.text.trim();
    final bizNumber = _bizNumberController.text.trim();
    final representative = _representativeController.text.trim();
    final bizPhone = _bizPhoneController.text.trim();
    final agentName = _agentNameController.text.trim();
    final agentPhone = _agentPhoneController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현장명과 주소를 입력해주세요.')),
      );
      return;
    }
    if (bizName.isEmpty || bizNumber.isEmpty || representative.isEmpty || bizPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사업자 정보를 모두 입력해주세요.')),
      );
      return;
    }
    if (agentName.isEmpty || agentPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현장 대리인 연락처를 입력해주세요.')),
      );
      return;
    }
    MockBackend.addSiteRequest(
      name: name,
      address: address,
      jobType: _siteJobType,
      bizName: bizName,
      bizNumber: bizNumber,
      representative: representative,
      bizPhone: bizPhone,
      agentName: agentName,
      agentPhone: agentPhone,
    );
    _siteNameController.clear();
    _siteAddressController.clear();
    _bizNameController.clear();
    _bizNumberController.clear();
    _representativeController.clear();
    _bizPhoneController.clear();
    _agentNameController.clear();
    _agentPhoneController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('현장 등록 요청이 접수되었습니다.')),
    );
    setState(() => _view = EmployerView.dashboard);
  }

  void _submitJobRequest(BuildContext context, Map<String, dynamic> site) {
    final siteId = site['id'] as String?;
    if (siteId == null || siteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현장 정보가 올바르지 않습니다.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('근무일과 시간을 입력해주세요.')),
      );
      return;
    }
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인원을 올바르게 입력해주세요.')),
      );
      return;
    }
    if (rate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('단가를 입력해주세요.')),
      );
      return;
    }
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('구인 요청이 등록되었습니다.')),
    );
    setState(() {
      _requestCountController.text = '1';
      _requestMemoController.clear();
    });
  }

  void _adjustNoShow(BuildContext context, String phone, int delta) {
    if (phone.trim().isEmpty) return;
    final next = MockBackend.adjustNoShowCount(phone: phone, delta: delta);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('노쇼 ${next}회로 업데이트되었습니다.')),
    );
  }

  void _resetNoShow(BuildContext context, String phone) {
    if (phone.trim().isEmpty) return;
    MockBackend.resetNoShowCount(phone: phone);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('노쇼 횟수가 초기화되었습니다.')),
    );
  }

  Widget _buildTodayWorkerCard(Map<String, dynamic> worker) {
    final approved = worker['approved'] == true;
    final selectedLabor = worker['labor'] as String? ?? '1.0';
    final rating = worker['attitude'] as int? ?? 0;
    final customLabor = (worker['customLabor'] as String? ?? '').trim();
    final entryKey = (worker['entryKey']?.toString() ?? '').trim();
    final controllerKey = entryKey.isEmpty ? 'local-${worker['phone'] ?? worker['name'] ?? 'worker'}' : entryKey;
    final laborController = _customLaborControllerFor(controllerKey, customLabor);
    final canApprove = _isWorkerReadyForApproval(worker);
    final statusColor = approved ? const Color(0xFF16A34A) : const Color(0xFF2563EB);
    final statusBg = approved ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF);
    final statusBorder = approved ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE);

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  approved ? '승인 완료' : '승인 전',
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
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
                  color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                ),
              );
            }).toList(),
          ),
          if (selectedLabor == 'custom') ...[
            const SizedBox(height: 10),
            TextField(
              controller: laborController,
              enabled: !approved,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '기타 공수',
                hintText: '예: 1.2',
                filled: true,
              ),
              onChanged: (value) {
                if (entryKey.isNotEmpty) {
                  MockBackend.updateWorkEntry(entryKey: entryKey, customLabor: value);
                }
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('근무 태도', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _buildStarRating(
                rating: rating,
                enabled: !approved,
                onChanged: (value) {
                  if (entryKey.isNotEmpty) {
                    MockBackend.updateWorkEntry(entryKey: entryKey, attitude: value);
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
                          MockBackend.updateWorkEntry(entryKey: entryKey, approved: true);
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
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5F5),
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

  Future<void> _generateAttendanceQr(BuildContext context, Map<String, dynamic> site) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 연결이 필요합니다.')),
      );
      return;
    }
    setState(() {
      _attendanceQr = AttendanceQrPayload.create(
        siteName: site['name']?.toString() ?? '-',
        siteId: site['id']?.toString(),
      );
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
