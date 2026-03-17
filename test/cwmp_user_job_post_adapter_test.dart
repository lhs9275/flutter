// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_test/flutter_test.dart';

import '../lib/data/cwmp_api_models.dart';
import '../lib/data/cwmp_user_app_adapter.dart';

void main() {
  group('CwmpJobPostResponse', () {
    test('parses snake_case fields and nested construction site data', () {
      final post = CwmpJobPostResponse.fromJson({
        'id': 19,
        'title': '강남 전기공 모집',
        'work_date': '2026-03-18',
        'start_time': '06:30:00',
        'head_count': 4,
        'daily_rate': 190000,
        'requirements': '안전화 필수',
        'region_code': '11680',
        'status': 'PUBLISHED',
        'construction_site': {
          'id': 81,
          'name': '강남 A현장',
          'address': '서울특별시 강남구 테헤란로 123',
          'latitude': 37.498095,
          'lng': 127.02761,
        },
      });

      expect(post.id, 19);
      expect(post.siteId, 81);
      expect(post.siteName, '강남 A현장');
      expect(post.siteAddress, '서울특별시 강남구 테헤란로 123');
      expect(post.workDate, '2026-03-18');
      expect(post.startTime, '06:30:00');
      expect(post.headcount, 4);
      expect(post.dailyRate, 190000);
      expect(post.regionCode, '11680');
      expect(post.siteLatitude, 37.498095);
      expect(post.siteLongitude, 127.02761);
    });
  });

  group('CwmpUserAppAdapter', () {
    test('infers preferred-region code from address when region code is absent', () {
      final post = CwmpJobPostResponse.fromJson({
        'id': 25,
        'title': '강남 철근공 모집',
        'workDate': '2026-03-19',
        'status': 'PUBLISHED',
        'site': {
          'id': 91,
          'name': '강남 B현장',
          'address': '서울특별시 강남구 역삼동 123-45',
        },
      });

      final site = CwmpUserAppAdapter.toSiteMap(post);

      expect(site['name'], '강남 B현장');
      expect(site['address'], '서울특별시 강남구 역삼동 123-45');
      expect(site['region'], '11680');
    });
  });
}
