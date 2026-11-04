import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/utils/user_profile_fields.dart';

void main() {
  // 실제 FieldValue.serverTimestamp() 대신 식별 가능한 대역을 주입하여
  // Firebase 초기화 없이 순수 로직만 검증
  const stamp = '<serverTimestamp>';

  group('UserProfileFields.loginUpdate', () {
    test('lastLoginAt 에 서버 타임스탬프를 담는다', () {
      final fields = UserProfileFields.loginUpdate(
        isAnonymous: true,
        serverTimestamp: stamp,
      );
      expect(fields['lastLoginAt'], stamp);
    });

    test('익명 계정이면 isAnonymous = true', () {
      final fields = UserProfileFields.loginUpdate(
        isAnonymous: true,
        serverTimestamp: stamp,
      );
      expect(fields['isAnonymous'], true);
    });

    test('구글 연동 계정이면 isAnonymous = false', () {
      final fields = UserProfileFields.loginUpdate(
        isAnonymous: false,
        serverTimestamp: stamp,
      );
      expect(fields['isAnonymous'], false);
    });

    test('createdAt 은 포함하지 않는다 — 가입일을 매 로그인마다 덮어쓰면 안 됨', () {
      final fields = UserProfileFields.loginUpdate(
        isAnonymous: true,
        serverTimestamp: stamp,
      );
      expect(fields.containsKey('createdAt'), false);
    });

    test('의도한 두 필드만 쓴다 — 다른 필드를 건드리지 않음', () {
      final fields = UserProfileFields.loginUpdate(
        isAnonymous: true,
        serverTimestamp: stamp,
      );
      expect(fields.keys.toSet(), {'lastLoginAt', 'isAnonymous'});
    });
  });
}
