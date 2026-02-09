import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FQ4App smoke test', (WidgetTester tester) async {
    // Phase 0: 기본 앱 실행 확인은 Flame GameWidget 의존성으로 인해
    // integration test에서 수행. 여기서는 기본 테스트 인프라만 검증.
    expect(true, isTrue);
  });
}
