import 'dart:math';

enum SiteStatus { pending, approved, rejected }

enum JobRequestStatus { pending, approved, rejected }

class MockBackend {
  static final Random _random = Random();
  static const List<String> _knownRegions = ['서울', '경기', '인천', '부산', '대구', '광주', '대전', '울산'];

  static final List<Map<String, dynamic>> priorityCandidates = [
    {'name': '김근로', 'role': '조공', 'noShowCount': 0},
    {'name': '박기공', 'role': '기공', 'noShowCount': 0},
    {'name': '이인부', 'role': '보통인부', 'noShowCount': 1},
  ];

  static final List<Map<String, dynamic>> sequenceCandidates = [
    {'name': '최인력', 'role': '보통인부', 'noShowCount': 0},
    {'name': '정지원', 'role': '조공', 'noShowCount': 2},
    {'name': '한현장', 'role': '기공', 'noShowCount': 0},
    {'name': '신대기', 'role': '보통인부', 'noShowCount': 1},
  ];

  static final List<Map<String, dynamic>> sites = [
    {
      'id': 'site-1',
      'name': '서초 아파트 재건축',
      'address': '서울 서초구 반포동',
      'region': '서울',
      'jobType': '조공',
      'status': SiteStatus.approved,
      'createdAt': '2024-07-25 10:00',
      'lat': 37.5036,
      'lng': 127.0056,
      'phoneVerified': true,
      'bizName': '서초건설',
      'bizNumber': '123-45-67890',
      'representative': '김대표',
      'bizPhone': '02-123-4567',
      'agentName': '박현장',
      'agentPhone': '010-2222-3333',
      'rejectReason': null,
    },
    {
      'id': 'site-2',
      'name': '판교 IT센터',
      'address': '경기 성남시 분당구',
      'region': '경기',
      'jobType': '보통인부',
      'status': SiteStatus.pending,
      'createdAt': '2024-08-01 09:20',
      'lat': 37.3946,
      'lng': 127.1112,
      'phoneVerified': false,
      'bizName': '판교건설',
      'bizNumber': '555-66-77777',
      'representative': '최대표',
      'bizPhone': '031-555-7777',
      'agentName': '강현장',
      'agentPhone': '010-3333-4444',
      'rejectReason': null,
    },
    {
      'id': 'site-3',
      'name': '홍대 리모델링',
      'address': '서울 마포구',
      'region': '서울',
      'jobType': '기공',
      'status': SiteStatus.rejected,
      'createdAt': '2024-08-03 14:10',
      'lat': 37.5563,
      'lng': 126.9227,
      'phoneVerified': true,
      'bizName': '홍대인테리어',
      'bizNumber': '222-33-44444',
      'representative': '이대표',
      'bizPhone': '02-987-6543',
      'agentName': '정대리',
      'agentPhone': '010-7777-8888',
      'rejectReason': '사업자 정보 확인 필요',
    },
  ];

  static final List<Map<String, dynamic>> jobRequests = [
    {
      'id': 'job-1',
      'siteId': 'site-1',
      'siteName': '서초 아파트 재건축',
      'date': '2024-08-06',
      'time': '07:30 ~ 17:00',
      'jobType': '조공',
      'count': 3,
      'rate': '150,000',
      'meetingPoint': '현장 정문',
      'notes': '안전모/안전화 지참',
      'memo': '성실한 인력 우선 요청',
      'status': JobRequestStatus.pending,
      'createdAt': '2024-08-05 15:10',
      'adminNote': null,
      'rejectReason': null,
      'assignedPriority': <String>[],
      'assignedSequence': <String>[],
      'applicants': <Map<String, String>>[
        {'name': '정지원', 'phone': '010-2222-0001'},
        {'name': '윤대기', 'phone': '010-2222-0002'},
      ],
    },
    {
      'id': 'job-2',
      'siteId': 'site-1',
      'siteName': '서초 아파트 재건축',
      'date': '2024-08-07',
      'time': '08:00 ~ 18:00',
      'jobType': '보통인부',
      'count': 5,
      'rate': '160,000',
      'meetingPoint': '정문 앞 컨테이너',
      'notes': '안전교육 10분 후 시작',
      'memo': '우천 시 일정 변경 가능',
      'status': JobRequestStatus.approved,
      'createdAt': '2024-08-05 16:00',
      'adminNote': '인원 5명으로 조정',
      'rejectReason': null,
      'assignedPriority': <String>['김근로'],
      'assignedSequence': <String>['최인력', '정지원'],
      'applicants': <Map<String, String>>[
        {'name': '김근로', 'phone': '010-1234-5678'},
        {'name': '최인력', 'phone': '010-3333-0003'},
        {'name': '정지원', 'phone': '010-2222-0001'},
      ],
    },
  ];

  static String _formatDateTime(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  static String _randomId(String prefix) {
    final value = _random.nextInt(900000) + 100000;
    return '$prefix-$value';
  }

  static String _extractRegion(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '기타';
    for (final region in _knownRegions) {
      if (address.contains(region)) return region;
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static List<Map<String, dynamic>> sitesByStatus(SiteStatus? status) {
    if (status == null) return List<Map<String, dynamic>>.from(sites);
    return sites.where((site) => site['status'] == status).toList();
  }

  static List<Map<String, dynamic>> jobRequestsForSite(String siteId) {
    return jobRequests.where((job) => job['siteId'] == siteId).toList();
  }

  static Map<String, dynamic> addSiteRequest({
    required String name,
    required String address,
    required String jobType,
    required String bizName,
    required String bizNumber,
    required String representative,
    required String bizPhone,
    required String agentName,
    required String agentPhone,
    double? lat,
    double? lng,
  }) {
    final site = {
      'id': _randomId('site'),
      'name': name,
      'address': address,
      'region': _extractRegion(address),
      'jobType': jobType,
      'status': SiteStatus.pending,
      'createdAt': _formatDateTime(DateTime.now()),
      'lat': lat ?? 37.5665,
      'lng': lng ?? 126.9780,
      'phoneVerified': false,
      'bizName': bizName,
      'bizNumber': bizNumber,
      'representative': representative,
      'bizPhone': bizPhone,
      'agentName': agentName,
      'agentPhone': agentPhone,
      'rejectReason': null,
    };
    sites.insert(0, site);
    return site;
  }

  static void updateSiteStatus(String siteId, SiteStatus status, {String? reason, bool? phoneVerified}) {
    final index = sites.indexWhere((site) => site['id'] == siteId);
    if (index == -1) return;
    final current = Map<String, dynamic>.from(sites[index]);
    current['status'] = status;
    if (reason != null) {
      current['rejectReason'] = reason;
    } else if (status == SiteStatus.approved) {
      current['rejectReason'] = null;
    }
    if (phoneVerified != null) {
      current['phoneVerified'] = phoneVerified;
    }
    sites[index] = current;
  }

  static void verifySitePhone(String siteId) {
    final index = sites.indexWhere((site) => site['id'] == siteId);
    if (index == -1) return;
    final status = sites[index]['status'] as SiteStatus? ?? SiteStatus.pending;
    updateSiteStatus(siteId, status, phoneVerified: true);
  }

  static Map<String, dynamic> addJobRequest({
    required String siteId,
    required String siteName,
    required String date,
    required String time,
    required String jobType,
    required int count,
    required String rate,
    required String meetingPoint,
    required String notes,
    required String memo,
  }) {
    final request = {
      'id': _randomId('job'),
      'siteId': siteId,
      'siteName': siteName,
      'date': date,
      'time': time,
      'jobType': jobType,
      'count': count,
      'rate': rate,
      'meetingPoint': meetingPoint,
      'notes': notes,
      'memo': memo,
      'status': JobRequestStatus.pending,
      'createdAt': _formatDateTime(DateTime.now()),
      'adminNote': null,
      'rejectReason': null,
      'assignedPriority': <String>[],
      'assignedSequence': <String>[],
    };
    jobRequests.insert(0, request);
    return request;
  }

  static void updateJobRequest(String jobId, Map<String, dynamic> updates) {
    final index = jobRequests.indexWhere((job) => job['id'] == jobId);
    if (index == -1) return;
    final current = Map<String, dynamic>.from(jobRequests[index]);
    current.addAll(updates);
    jobRequests[index] = current;
  }

  static void updateJobRequestStatus(String jobId, JobRequestStatus status, {String? reason, String? adminNote}) {
    final index = jobRequests.indexWhere((job) => job['id'] == jobId);
    if (index == -1) return;
    final current = Map<String, dynamic>.from(jobRequests[index]);
    current['status'] = status;
    if (adminNote != null) {
      current['adminNote'] = adminNote;
    }
    if (reason != null) {
      current['rejectReason'] = reason;
    } else if (status == JobRequestStatus.approved) {
      current['rejectReason'] = null;
    }
    jobRequests[index] = current;
  }

  static List<Map<String, String>> applicantsForJob(String jobId) {
    final job = jobRequests.firstWhere(
      (item) => item['id'] == jobId,
      orElse: () => {},
    );
    final list = job['applicants'] as List<dynamic>? ?? [];
    return list.map((entry) => Map<String, String>.from(entry as Map)).toList();
  }

  static bool addApplication({
    required String jobId,
    required String name,
    required String phone,
  }) {
    final index = jobRequests.indexWhere((job) => job['id'] == jobId);
    if (index == -1) return false;
    final job = Map<String, dynamic>.from(jobRequests[index]);
    final applicants = List<Map<String, String>>.from(job['applicants'] as List? ?? []);
    final exists = applicants.any((item) => item['phone'] == phone);
    if (exists) return false;
    applicants.add({'name': name, 'phone': phone});
    job['applicants'] = applicants;
    jobRequests[index] = job;
    return true;
  }

  static void cancelApplication({required String jobId, required String phone}) {
    final index = jobRequests.indexWhere((job) => job['id'] == jobId);
    if (index == -1) return;
    final job = Map<String, dynamic>.from(jobRequests[index]);
    final applicants = List<Map<String, String>>.from(job['applicants'] as List? ?? []);
    applicants.removeWhere((item) => item['phone'] == phone);
    job['applicants'] = applicants;
    jobRequests[index] = job;
  }

  static Map<String, dynamic>? _findSite(String siteId) {
    for (final site in sites) {
      if (site['id'] == siteId) return site;
    }
    return null;
  }

  static List<Map<String, dynamic>> approvedJobPosts() {
    final posts = <Map<String, dynamic>>[];
    for (final job in jobRequests) {
      final status = job['status'] as JobRequestStatus? ?? JobRequestStatus.pending;
      if (status != JobRequestStatus.approved) continue;
      final siteId = job['siteId'] as String? ?? '';
      final site = _findSite(siteId);
      if (site == null) continue;
      final siteStatus = site['status'] as SiteStatus? ?? SiteStatus.pending;
      if (siteStatus != SiteStatus.approved) continue;
      posts.add({
        'id': job['id'],
        'siteId': siteId,
        'name': site['name'],
        'address': site['address'],
        'region': site['region'],
        'type': job['jobType'],
        'date': job['date'],
        'time': job['time'],
        'count': job['count'],
        'pay': job['rate'],
        'meetingPoint': job['meetingPoint'],
        'notes': job['notes'],
        'contact': site['agentPhone'],
        'lat': site['lat'],
        'lng': site['lng'],
        'memo': job['memo'],
      });
    }
    posts.sort((a, b) => (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString()));
    return posts;
  }

  static int assignedCountForJob(Map<String, dynamic> job) {
    final priority = job['assignedPriority'] as List<dynamic>? ?? [];
    final sequence = job['assignedSequence'] as List<dynamic>? ?? [];
    return priority.length + sequence.length;
  }

  static int remainingCountForJob(Map<String, dynamic> job) {
    final total = job['count'] as int? ?? 0;
    final assigned = assignedCountForJob(job);
    final remaining = total - assigned;
    return remaining < 0 ? 0 : remaining;
  }

  static String? assignWorker(String jobId, {required bool priority}) {
    final index = jobRequests.indexWhere((job) => job['id'] == jobId);
    if (index == -1) return null;
    final job = Map<String, dynamic>.from(jobRequests[index]);
    final remaining = remainingCountForJob(job);
    if (remaining <= 0) return null;
    final assignedPriority = List<String>.from(job['assignedPriority'] as List? ?? []);
    final assignedSequence = List<String>.from(job['assignedSequence'] as List? ?? []);
    final assignedAll = {...assignedPriority, ...assignedSequence};
    final pool = priority ? priorityCandidates : sequenceCandidates;
    String? selected;
    for (final candidate in pool) {
      final name = candidate['name']?.toString() ?? '';
      if (name.isEmpty || assignedAll.contains(name)) continue;
      selected = name;
      break;
    }
    if (selected == null) return null;
    if (priority) {
      assignedPriority.add(selected);
    } else {
      assignedSequence.add(selected);
    }
    job['assignedPriority'] = assignedPriority;
    job['assignedSequence'] = assignedSequence;
    jobRequests[index] = job;
    return selected;
  }

  static void resetAssignments(String jobId) {
    final index = jobRequests.indexWhere((job) => job['id'] == jobId);
    if (index == -1) return;
    final job = Map<String, dynamic>.from(jobRequests[index]);
    job['assignedPriority'] = <String>[];
    job['assignedSequence'] = <String>[];
    jobRequests[index] = job;
  }

  static String siteStatusLabel(SiteStatus status) {
    switch (status) {
      case SiteStatus.approved:
        return '승인됨';
      case SiteStatus.rejected:
        return '반려됨';
      case SiteStatus.pending:
        return '전화 확인 대기';
    }
  }

  static String jobStatusLabel(JobRequestStatus status) {
    switch (status) {
      case JobRequestStatus.approved:
        return '승인 완료';
      case JobRequestStatus.rejected:
        return '반려';
      case JobRequestStatus.pending:
        return '승인 대기';
    }
  }
}
