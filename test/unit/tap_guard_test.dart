import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/utils/tap_guard.dart';

void main() {
  const cooldown = Duration(milliseconds: 50);

  test('동작이 진행 중일 때 들어오는 연타는 무시된다', () async {
    final guard = TapGuard(cooldown: cooldown);
    var count = 0;
    Future<void> action() async {
      count++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    await Future.wait([guard.run(action), guard.run(action), guard.run(action)]);
    expect(count, 1);
  });

  test('동작이 끝나도 쿨다운 동안은 무시된다', () async {
    final guard = TapGuard(cooldown: cooldown);
    var count = 0;
    Future<void> action() async => count++;

    await guard.run(action);
    await guard.run(action); // 쿨다운 안 → 무시
    expect(count, 1);
  });

  test('쿨다운이 지나면 다시 실행된다', () async {
    final guard = TapGuard(cooldown: cooldown);
    var count = 0;
    Future<void> action() async => count++;

    await guard.run(action);
    await Future<void>.delayed(cooldown * 2);
    await guard.run(action);
    expect(count, 2);
  });

  test('동작이 예외를 던져도 쿨다운 뒤에는 다시 실행된다', () async {
    final guard = TapGuard(cooldown: cooldown);
    var count = 0;

    await expectLater(
        guard.run(() async => throw StateError('fail')), throwsStateError);
    await Future<void>.delayed(cooldown * 2);
    await guard.run(() async => count++);
    expect(count, 1);
  });
}
