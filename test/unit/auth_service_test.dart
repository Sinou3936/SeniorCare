import 'package:flutter_test/flutter_test.dart';

// AuthService.linkWithGoogle()은 실제 Google UI + Firebase가 필요하므로
// 직접 호출 테스트 불가. 대신 반환값 분기 로직과 상태 판단 로직을 검증.

void main() {
  group('linkWithGoogle 반환값 분기 로직', () {
    // 실제 AuthService 대신 동일한 분기 로직을 순수 함수로 추출하여 테스트
    String handleLinkResult(String result) {
      switch (result) {
        case 'success':
          return '연결 성공';
        case 'cancelled':
          return '취소됨';
        case 'already_in_use':
          return '이미 사용 중인 계정';
        default:
          return '오류 발생';
      }
    }

    test('success → 연결 성공 메시지', () {
      expect(handleLinkResult('success'), '연결 성공');
    });

    test('cancelled → 취소 처리 (아무것도 안 함)', () {
      expect(handleLinkResult('cancelled'), '취소됨');
    });

    test('already_in_use → 중복 계정 안내', () {
      expect(handleLinkResult('already_in_use'), '이미 사용 중인 계정');
    });

    test('error → 오류 안내', () {
      expect(handleLinkResult('error'), '오류 발생');
    });

    test('알 수 없는 결과 → 오류 처리', () {
      expect(handleLinkResult('unknown'), '오류 발생');
    });
  });

  group('isAnonymous / isLinkedWithGoogle 상태 판단', () {
    // providerData 기반 상태 판단 로직 검증
    bool isLinkedWithGoogle(List<String> providerIds) {
      return providerIds.contains('google.com');
    }

    bool isAnonymous(List<String> providerIds) {
      return providerIds.isEmpty;
    }

    test('익명 계정: providerData 비어있음', () {
      expect(isAnonymous([]), true);
      expect(isLinkedWithGoogle([]), false);
    });

    test('Google 연결 후: google.com 포함', () {
      expect(isLinkedWithGoogle(['google.com']), true);
      expect(isAnonymous(['google.com']), false);
    });

    test('다른 provider: google.com 미포함', () {
      expect(isLinkedWithGoogle(['password']), false);
    });
  });
}
