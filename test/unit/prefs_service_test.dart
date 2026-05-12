import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seniorcare/services/prefs_service.dart';

void main() {
  group('PrefsService — 세션 유지', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveMode → loadMode: family 유지', () async {
      await PrefsService.saveMode('family');
      expect(await PrefsService.loadMode(), 'family');
    });

    test('saveMode → loadMode: senior 유지', () async {
      await PrefsService.saveMode('senior');
      expect(await PrefsService.loadMode(), 'senior');
    });

    test('초기 상태: loadMode는 null', () async {
      expect(await PrefsService.loadMode(), isNull);
    });

    test('clearMode 후: loadMode는 null', () async {
      await PrefsService.saveMode('family');
      await PrefsService.clearMode();
      expect(await PrefsService.loadMode(), isNull);
    });

    test('family 저장 후 재실행 시뮬레이션: FamilyMainScreen으로 라우팅', () async {
      await PrefsService.saveMode('family');
      // 재실행 시뮬레이션 — 같은 prefs 인스턴스에서 다시 읽기
      final mode = await PrefsService.loadMode();
      expect(mode, 'family'); // FamilyMainScreen 진입 조건
    });

    test('알림 설정 저장/로드', () async {
      await PrefsService.saveNotificationEnabled(false);
      expect(await PrefsService.loadNotificationEnabled(), false);
    });

    test('알림 설정 기본값: true', () async {
      expect(await PrefsService.loadNotificationEnabled(), true);
    });
  });
}
