class ApiConstants {
  // 로컬 테스트용 (안드로이드 에뮬레이터: 10.0.2.2, iOS: localhost)
  // 실제 서버 배포 시 이 주소를 수정합니다.
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  static const String decks = '/vocabulary/decks';
  static const String due = '/vocabulary/due';
  static const String review = '/vocabulary/review';
  static const String game = '/vocabulary/game';
}
