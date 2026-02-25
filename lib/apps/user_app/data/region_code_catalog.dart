class PreferredRegionOption {
  const PreferredRegionOption({required this.code, required this.name});

  final String code;
  final String name;

  String get displayLabel => '$name ($code)';

  bool matches(String query) {
    final q = query.trim();
    if (q.isEmpty) return true;
    final normalizedQuery = _preferredRegionSearchKey(q);
    return code.contains(q) ||
        name.contains(q) ||
        _preferredRegionSearchKey(name).contains(normalizedQuery);
  }
}

const List<PreferredRegionOption> preferredRegionCatalog = [
  PreferredRegionOption(code: '11110', name: '서울특별시 종로구'),
  PreferredRegionOption(code: '11140', name: '서울특별시 중구'),
  PreferredRegionOption(code: '11170', name: '서울특별시 용산구'),
  PreferredRegionOption(code: '11200', name: '서울특별시 성동구'),
  PreferredRegionOption(code: '11215', name: '서울특별시 광진구'),
  PreferredRegionOption(code: '11230', name: '서울특별시 동대문구'),
  PreferredRegionOption(code: '11260', name: '서울특별시 중랑구'),
  PreferredRegionOption(code: '11290', name: '서울특별시 성북구'),
  PreferredRegionOption(code: '11305', name: '서울특별시 강북구'),
  PreferredRegionOption(code: '11320', name: '서울특별시 도봉구'),
  PreferredRegionOption(code: '11350', name: '서울특별시 노원구'),
  PreferredRegionOption(code: '11380', name: '서울특별시 은평구'),
  PreferredRegionOption(code: '11410', name: '서울특별시 서대문구'),
  PreferredRegionOption(code: '11440', name: '서울특별시 마포구'),
  PreferredRegionOption(code: '11470', name: '서울특별시 양천구'),
  PreferredRegionOption(code: '11500', name: '서울특별시 강서구'),
  PreferredRegionOption(code: '11530', name: '서울특별시 구로구'),
  PreferredRegionOption(code: '11545', name: '서울특별시 금천구'),
  PreferredRegionOption(code: '11560', name: '서울특별시 영등포구'),
  PreferredRegionOption(code: '11590', name: '서울특별시 동작구'),
  PreferredRegionOption(code: '11620', name: '서울특별시 관악구'),
  PreferredRegionOption(code: '11650', name: '서울특별시 서초구'),
  PreferredRegionOption(code: '11680', name: '서울특별시 강남구'),
  PreferredRegionOption(code: '11710', name: '서울특별시 송파구'),
  PreferredRegionOption(code: '11740', name: '서울특별시 강동구'),
  PreferredRegionOption(code: '26110', name: '부산광역시 중구'),
  PreferredRegionOption(code: '26140', name: '부산광역시 서구'),
  PreferredRegionOption(code: '26170', name: '부산광역시 동구'),
  PreferredRegionOption(code: '26200', name: '부산광역시 영도구'),
  PreferredRegionOption(code: '26230', name: '부산광역시 부산진구'),
  PreferredRegionOption(code: '26260', name: '부산광역시 동래구'),
  PreferredRegionOption(code: '26290', name: '부산광역시 남구'),
  PreferredRegionOption(code: '26320', name: '부산광역시 북구'),
  PreferredRegionOption(code: '26350', name: '부산광역시 해운대구'),
  PreferredRegionOption(code: '26380', name: '부산광역시 사하구'),
  PreferredRegionOption(code: '26410', name: '부산광역시 금정구'),
  PreferredRegionOption(code: '26440', name: '부산광역시 강서구'),
  PreferredRegionOption(code: '26470', name: '부산광역시 연제구'),
  PreferredRegionOption(code: '26500', name: '부산광역시 수영구'),
  PreferredRegionOption(code: '26530', name: '부산광역시 사상구'),
  PreferredRegionOption(code: '26710', name: '부산광역시 기장군'),
  PreferredRegionOption(code: '27110', name: '대구광역시 중구'),
  PreferredRegionOption(code: '27140', name: '대구광역시 동구'),
  PreferredRegionOption(code: '27170', name: '대구광역시 서구'),
  PreferredRegionOption(code: '27200', name: '대구광역시 남구'),
  PreferredRegionOption(code: '27230', name: '대구광역시 북구'),
  PreferredRegionOption(code: '27260', name: '대구광역시 수성구'),
  PreferredRegionOption(code: '27290', name: '대구광역시 달서구'),
  PreferredRegionOption(code: '27710', name: '대구광역시 달성군'),
  PreferredRegionOption(code: '27720', name: '대구광역시 군위군'),
  PreferredRegionOption(code: '28110', name: '인천광역시 중구'),
  PreferredRegionOption(code: '28140', name: '인천광역시 동구'),
  PreferredRegionOption(code: '28177', name: '인천광역시 미추홀구'),
  PreferredRegionOption(code: '28185', name: '인천광역시 연수구'),
  PreferredRegionOption(code: '28200', name: '인천광역시 남동구'),
  PreferredRegionOption(code: '28237', name: '인천광역시 부평구'),
  PreferredRegionOption(code: '28245', name: '인천광역시 계양구'),
  PreferredRegionOption(code: '28260', name: '인천광역시 서구'),
  PreferredRegionOption(code: '28710', name: '인천광역시 강화군'),
  PreferredRegionOption(code: '28720', name: '인천광역시 옹진군'),
  PreferredRegionOption(code: '29110', name: '광주광역시 동구'),
  PreferredRegionOption(code: '29140', name: '광주광역시 서구'),
  PreferredRegionOption(code: '29155', name: '광주광역시 남구'),
  PreferredRegionOption(code: '29170', name: '광주광역시 북구'),
  PreferredRegionOption(code: '29200', name: '광주광역시 광산구'),
  PreferredRegionOption(code: '30110', name: '대전광역시 동구'),
  PreferredRegionOption(code: '30140', name: '대전광역시 중구'),
  PreferredRegionOption(code: '30170', name: '대전광역시 서구'),
  PreferredRegionOption(code: '30200', name: '대전광역시 유성구'),
  PreferredRegionOption(code: '30230', name: '대전광역시 대덕구'),
  PreferredRegionOption(code: '31110', name: '울산광역시 중구'),
  PreferredRegionOption(code: '31140', name: '울산광역시 남구'),
  PreferredRegionOption(code: '31170', name: '울산광역시 동구'),
  PreferredRegionOption(code: '31200', name: '울산광역시 북구'),
  PreferredRegionOption(code: '31710', name: '울산광역시 울주군'),
  PreferredRegionOption(code: '36110', name: '세종특별자치시'),
  PreferredRegionOption(code: '41110', name: '경기도 수원시'),
  PreferredRegionOption(code: '41111', name: '경기도 수원시 장안구'),
  PreferredRegionOption(code: '41113', name: '경기도 수원시 권선구'),
  PreferredRegionOption(code: '41115', name: '경기도 수원시 팔달구'),
  PreferredRegionOption(code: '41117', name: '경기도 수원시 영통구'),
  PreferredRegionOption(code: '41130', name: '경기도 성남시'),
  PreferredRegionOption(code: '41131', name: '경기도 성남시 수정구'),
  PreferredRegionOption(code: '41133', name: '경기도 성남시 중원구'),
  PreferredRegionOption(code: '41135', name: '경기도 성남시 분당구'),
  PreferredRegionOption(code: '41150', name: '경기도 의정부시'),
  PreferredRegionOption(code: '41170', name: '경기도 안양시'),
  PreferredRegionOption(code: '41171', name: '경기도 안양시 만안구'),
  PreferredRegionOption(code: '41173', name: '경기도 안양시 동안구'),
  PreferredRegionOption(code: '41190', name: '경기도 부천시'),
  PreferredRegionOption(code: '41210', name: '경기도 광명시'),
  PreferredRegionOption(code: '41220', name: '경기도 평택시'),
  PreferredRegionOption(code: '41250', name: '경기도 동두천시'),
  PreferredRegionOption(code: '41270', name: '경기도 안산시'),
  PreferredRegionOption(code: '41271', name: '경기도 안산시 상록구'),
  PreferredRegionOption(code: '41273', name: '경기도 안산시 단원구'),
  PreferredRegionOption(code: '41280', name: '경기도 고양시'),
  PreferredRegionOption(code: '41281', name: '경기도 고양시 덕양구'),
  PreferredRegionOption(code: '41285', name: '경기도 고양시 일산동구'),
  PreferredRegionOption(code: '41287', name: '경기도 고양시 일산서구'),
  PreferredRegionOption(code: '41290', name: '경기도 과천시'),
  PreferredRegionOption(code: '41310', name: '경기도 구리시'),
  PreferredRegionOption(code: '41360', name: '경기도 남양주시'),
  PreferredRegionOption(code: '41370', name: '경기도 오산시'),
  PreferredRegionOption(code: '41390', name: '경기도 시흥시'),
  PreferredRegionOption(code: '41410', name: '경기도 군포시'),
  PreferredRegionOption(code: '41430', name: '경기도 의왕시'),
  PreferredRegionOption(code: '41450', name: '경기도 하남시'),
  PreferredRegionOption(code: '41460', name: '경기도 용인시'),
  PreferredRegionOption(code: '41461', name: '경기도 용인시 처인구'),
  PreferredRegionOption(code: '41463', name: '경기도 용인시 기흥구'),
  PreferredRegionOption(code: '41465', name: '경기도 용인시 수지구'),
  PreferredRegionOption(code: '41480', name: '경기도 파주시'),
  PreferredRegionOption(code: '41500', name: '경기도 이천시'),
  PreferredRegionOption(code: '41550', name: '경기도 안성시'),
  PreferredRegionOption(code: '41570', name: '경기도 김포시'),
  PreferredRegionOption(code: '41590', name: '경기도 화성시'),
  PreferredRegionOption(code: '41610', name: '경기도 광주시'),
  PreferredRegionOption(code: '41630', name: '경기도 양주시'),
  PreferredRegionOption(code: '41650', name: '경기도 포천시'),
  PreferredRegionOption(code: '41670', name: '경기도 여주시'),
  PreferredRegionOption(code: '41800', name: '경기도 연천군'),
  PreferredRegionOption(code: '41820', name: '경기도 가평군'),
  PreferredRegionOption(code: '41830', name: '경기도 양평군'),
  PreferredRegionOption(code: '43110', name: '충청북도 청주시'),
  PreferredRegionOption(code: '43111', name: '충청북도 청주시 상당구'),
  PreferredRegionOption(code: '43112', name: '충청북도 청주시 서원구'),
  PreferredRegionOption(code: '43113', name: '충청북도 청주시 흥덕구'),
  PreferredRegionOption(code: '43114', name: '충청북도 청주시 청원구'),
  PreferredRegionOption(code: '43130', name: '충청북도 충주시'),
  PreferredRegionOption(code: '43150', name: '충청북도 제천시'),
  PreferredRegionOption(code: '43720', name: '충청북도 보은군'),
  PreferredRegionOption(code: '43730', name: '충청북도 옥천군'),
  PreferredRegionOption(code: '43740', name: '충청북도 영동군'),
  PreferredRegionOption(code: '43745', name: '충청북도 증평군'),
  PreferredRegionOption(code: '43750', name: '충청북도 진천군'),
  PreferredRegionOption(code: '43760', name: '충청북도 괴산군'),
  PreferredRegionOption(code: '43770', name: '충청북도 음성군'),
  PreferredRegionOption(code: '43800', name: '충청북도 단양군'),
  PreferredRegionOption(code: '44130', name: '충청남도 천안시'),
  PreferredRegionOption(code: '44131', name: '충청남도 천안시 동남구'),
  PreferredRegionOption(code: '44133', name: '충청남도 천안시 서북구'),
  PreferredRegionOption(code: '44150', name: '충청남도 공주시'),
  PreferredRegionOption(code: '44180', name: '충청남도 보령시'),
  PreferredRegionOption(code: '44200', name: '충청남도 아산시'),
  PreferredRegionOption(code: '44210', name: '충청남도 서산시'),
  PreferredRegionOption(code: '44230', name: '충청남도 논산시'),
  PreferredRegionOption(code: '44250', name: '충청남도 계룡시'),
  PreferredRegionOption(code: '44270', name: '충청남도 당진시'),
  PreferredRegionOption(code: '44710', name: '충청남도 금산군'),
  PreferredRegionOption(code: '44760', name: '충청남도 부여군'),
  PreferredRegionOption(code: '44770', name: '충청남도 서천군'),
  PreferredRegionOption(code: '44790', name: '충청남도 청양군'),
  PreferredRegionOption(code: '44800', name: '충청남도 홍성군'),
  PreferredRegionOption(code: '44810', name: '충청남도 예산군'),
  PreferredRegionOption(code: '44825', name: '충청남도 태안군'),
  PreferredRegionOption(code: '45110', name: '전라북도 전주시'),
  PreferredRegionOption(code: '45111', name: '전라북도 전주시 완산구'),
  PreferredRegionOption(code: '45113', name: '전라북도 전주시 덕진구'),
  PreferredRegionOption(code: '45130', name: '전라북도 군산시'),
  PreferredRegionOption(code: '45140', name: '전라북도 익산시'),
  PreferredRegionOption(code: '45180', name: '전라북도 정읍시'),
  PreferredRegionOption(code: '45190', name: '전라북도 남원시'),
  PreferredRegionOption(code: '45210', name: '전라북도 김제시'),
  PreferredRegionOption(code: '45710', name: '전라북도 완주군'),
  PreferredRegionOption(code: '45720', name: '전라북도 진안군'),
  PreferredRegionOption(code: '45730', name: '전라북도 무주군'),
  PreferredRegionOption(code: '45740', name: '전라북도 장수군'),
  PreferredRegionOption(code: '45750', name: '전라북도 임실군'),
  PreferredRegionOption(code: '45770', name: '전라북도 순창군'),
  PreferredRegionOption(code: '45790', name: '전라북도 고창군'),
  PreferredRegionOption(code: '45800', name: '전라북도 부안군'),
  PreferredRegionOption(code: '46110', name: '전라남도 목포시'),
  PreferredRegionOption(code: '46130', name: '전라남도 여수시'),
  PreferredRegionOption(code: '46150', name: '전라남도 순천시'),
  PreferredRegionOption(code: '46170', name: '전라남도 나주시'),
  PreferredRegionOption(code: '46230', name: '전라남도 광양시'),
  PreferredRegionOption(code: '46710', name: '전라남도 담양군'),
  PreferredRegionOption(code: '46720', name: '전라남도 곡성군'),
  PreferredRegionOption(code: '46730', name: '전라남도 구례군'),
  PreferredRegionOption(code: '46770', name: '전라남도 고흥군'),
  PreferredRegionOption(code: '46780', name: '전라남도 보성군'),
  PreferredRegionOption(code: '46790', name: '전라남도 화순군'),
  PreferredRegionOption(code: '46800', name: '전라남도 장흥군'),
  PreferredRegionOption(code: '46810', name: '전라남도 강진군'),
  PreferredRegionOption(code: '46820', name: '전라남도 해남군'),
  PreferredRegionOption(code: '46830', name: '전라남도 영암군'),
  PreferredRegionOption(code: '46840', name: '전라남도 무안군'),
  PreferredRegionOption(code: '46860', name: '전라남도 함평군'),
  PreferredRegionOption(code: '46870', name: '전라남도 영광군'),
  PreferredRegionOption(code: '46880', name: '전라남도 장성군'),
  PreferredRegionOption(code: '46890', name: '전라남도 완도군'),
  PreferredRegionOption(code: '46900', name: '전라남도 진도군'),
  PreferredRegionOption(code: '46910', name: '전라남도 신안군'),
  PreferredRegionOption(code: '47110', name: '경상북도 포항시'),
  PreferredRegionOption(code: '47111', name: '경상북도 포항시 남구'),
  PreferredRegionOption(code: '47113', name: '경상북도 포항시 북구'),
  PreferredRegionOption(code: '47130', name: '경상북도 경주시'),
  PreferredRegionOption(code: '47150', name: '경상북도 김천시'),
  PreferredRegionOption(code: '47170', name: '경상북도 안동시'),
  PreferredRegionOption(code: '47190', name: '경상북도 구미시'),
  PreferredRegionOption(code: '47210', name: '경상북도 영주시'),
  PreferredRegionOption(code: '47230', name: '경상북도 영천시'),
  PreferredRegionOption(code: '47250', name: '경상북도 상주시'),
  PreferredRegionOption(code: '47280', name: '경상북도 문경시'),
  PreferredRegionOption(code: '47290', name: '경상북도 경산시'),
  PreferredRegionOption(code: '47720', name: '경상북도 군위군'),
  PreferredRegionOption(code: '47730', name: '경상북도 의성군'),
  PreferredRegionOption(code: '47750', name: '경상북도 청송군'),
  PreferredRegionOption(code: '47760', name: '경상북도 영양군'),
  PreferredRegionOption(code: '47770', name: '경상북도 영덕군'),
  PreferredRegionOption(code: '47820', name: '경상북도 청도군'),
  PreferredRegionOption(code: '47830', name: '경상북도 고령군'),
  PreferredRegionOption(code: '47840', name: '경상북도 성주군'),
  PreferredRegionOption(code: '47850', name: '경상북도 칠곡군'),
  PreferredRegionOption(code: '47900', name: '경상북도 예천군'),
  PreferredRegionOption(code: '47920', name: '경상북도 봉화군'),
  PreferredRegionOption(code: '47930', name: '경상북도 울진군'),
  PreferredRegionOption(code: '47940', name: '경상북도 울릉군'),
  PreferredRegionOption(code: '48120', name: '경상남도 창원시'),
  PreferredRegionOption(code: '48121', name: '경상남도 창원시 의창구'),
  PreferredRegionOption(code: '48123', name: '경상남도 창원시 성산구'),
  PreferredRegionOption(code: '48125', name: '경상남도 창원시 마산합포구'),
  PreferredRegionOption(code: '48127', name: '경상남도 창원시 마산회원구'),
  PreferredRegionOption(code: '48129', name: '경상남도 창원시 진해구'),
  PreferredRegionOption(code: '48170', name: '경상남도 진주시'),
  PreferredRegionOption(code: '48220', name: '경상남도 통영시'),
  PreferredRegionOption(code: '48240', name: '경상남도 사천시'),
  PreferredRegionOption(code: '48250', name: '경상남도 김해시'),
  PreferredRegionOption(code: '48270', name: '경상남도 밀양시'),
  PreferredRegionOption(code: '48310', name: '경상남도 거제시'),
  PreferredRegionOption(code: '48330', name: '경상남도 양산시'),
  PreferredRegionOption(code: '48720', name: '경상남도 의령군'),
  PreferredRegionOption(code: '48730', name: '경상남도 함안군'),
  PreferredRegionOption(code: '48740', name: '경상남도 창녕군'),
  PreferredRegionOption(code: '48820', name: '경상남도 고성군'),
  PreferredRegionOption(code: '48840', name: '경상남도 남해군'),
  PreferredRegionOption(code: '48850', name: '경상남도 하동군'),
  PreferredRegionOption(code: '48860', name: '경상남도 산청군'),
  PreferredRegionOption(code: '48870', name: '경상남도 함양군'),
  PreferredRegionOption(code: '48880', name: '경상남도 거창군'),
  PreferredRegionOption(code: '48890', name: '경상남도 합천군'),
  PreferredRegionOption(code: '50110', name: '제주특별자치도 제주시'),
  PreferredRegionOption(code: '50130', name: '제주특별자치도 서귀포시'),
  PreferredRegionOption(code: '51110', name: '강원특별자치도 춘천시'),
  PreferredRegionOption(code: '51130', name: '강원특별자치도 원주시'),
  PreferredRegionOption(code: '51150', name: '강원특별자치도 강릉시'),
  PreferredRegionOption(code: '51170', name: '강원특별자치도 동해시'),
  PreferredRegionOption(code: '51190', name: '강원특별자치도 태백시'),
  PreferredRegionOption(code: '51210', name: '강원특별자치도 속초시'),
  PreferredRegionOption(code: '51230', name: '강원특별자치도 삼척시'),
  PreferredRegionOption(code: '51720', name: '강원특별자치도 홍천군'),
  PreferredRegionOption(code: '51730', name: '강원특별자치도 횡성군'),
  PreferredRegionOption(code: '51750', name: '강원특별자치도 영월군'),
  PreferredRegionOption(code: '51760', name: '강원특별자치도 평창군'),
  PreferredRegionOption(code: '51770', name: '강원특별자치도 정선군'),
  PreferredRegionOption(code: '51780', name: '강원특별자치도 철원군'),
  PreferredRegionOption(code: '51790', name: '강원특별자치도 화천군'),
  PreferredRegionOption(code: '51800', name: '강원특별자치도 양구군'),
  PreferredRegionOption(code: '51810', name: '강원특별자치도 인제군'),
  PreferredRegionOption(code: '51820', name: '강원특별자치도 고성군'),
  PreferredRegionOption(code: '51830', name: '강원특별자치도 양양군'),
];

String _normalizePreferredRegionName(String input) {
  var value = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (value.isEmpty) return value;

  const prefixAliases = <String, String>{
    '서울 ': '서울특별시 ',
    '부산 ': '부산광역시 ',
    '대구 ': '대구광역시 ',
    '인천 ': '인천광역시 ',
    '광주 ': '광주광역시 ',
    '대전 ': '대전광역시 ',
    '울산 ': '울산광역시 ',
    '세종 ': '세종특별자치시 ',
    '세종시 ': '세종특별자치시 ',
    '경기 ': '경기도 ',
    '강원 ': '강원특별자치도 ',
    '강원도 ': '강원특별자치도 ',
    '충북 ': '충청북도 ',
    '충청북도 ': '충청북도 ',
    '충남 ': '충청남도 ',
    '충청남도 ': '충청남도 ',
    '전북 ': '전북특별자치도 ',
    '전라북도 ': '전북특별자치도 ',
    '전북특별자치도 ': '전북특별자치도 ',
    '전남 ': '전라남도 ',
    '전라남도 ': '전라남도 ',
    '경북 ': '경상북도 ',
    '경상북도 ': '경상북도 ',
    '경남 ': '경상남도 ',
    '경상남도 ': '경상남도 ',
    '제주 ': '제주특별자치도 ',
    '제주도 ': '제주특별자치도 ',
    '제주특별자치도 ': '제주특별자치도 ',
  };

  for (final entry in prefixAliases.entries) {
    if (value.startsWith(entry.key)) {
      value = '${entry.value}${value.substring(entry.key.length)}';
      return value.trim();
    }
  }

  if (value == '세종' || value == '세종시') {
    return '세종특별자치시';
  }

  return value;
}

String _preferredRegionSearchKey(String input) {
  return _normalizePreferredRegionName(input).replaceAll(' ', '');
}

String? extractPreferredRegionCode(String input) {
  final raw = input.trim();
  if (raw.isEmpty) return null;
  final exact = RegExp(r'^\d{5}$').firstMatch(raw);
  if (exact != null) return exact.group(0);

  final startsWithCode = RegExp(r'^(\d{5})(?:\s+.*)?$').firstMatch(raw);
  if (startsWithCode != null) return startsWithCode.group(1);

  final embedded = RegExp(r'(\d{5})').firstMatch(raw);
  if (embedded != null) return embedded.group(1);

  final normalizedRaw = _preferredRegionSearchKey(raw);
  for (final option in preferredRegionCatalog) {
    if (option.name == raw || option.displayLabel == raw) {
      return option.code;
    }
    if (_preferredRegionSearchKey(option.name) == normalizedRaw) {
      return option.code;
    }
  }
  return null;
}

PreferredRegionOption? preferredRegionOptionByCode(String code) {
  final normalized = extractPreferredRegionCode(code) ?? code.trim();
  if (normalized.isEmpty) return null;
  for (final option in preferredRegionCatalog) {
    if (option.code == normalized) return option;
  }
  return null;
}

String preferredRegionDisplayLabel(String value) {
  final code = extractPreferredRegionCode(value);
  if (code == null) return _normalizePreferredRegionName(value.trim());
  final option = preferredRegionOptionByCode(code);
  if (option == null) return code;
  return option.name;
}

String? preferredRegionNameByCode(String code) {
  return preferredRegionOptionByCode(code)?.name;
}
