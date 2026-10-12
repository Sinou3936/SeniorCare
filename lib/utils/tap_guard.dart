import 'dart:async';

/// 버튼 연타 방지.
/// [run] 안의 동작이 끝나기 전, 그리고 끝난 뒤 [cooldown] 동안 들어오는 탭은 무시한다.
/// 연결 확인(`ensureOnline`) 같은 await 구간에서 두 번 눌려 저장·화면 이동이 중복되는 것을 막는다.
class TapGuard {
  TapGuard({this.cooldown = const Duration(milliseconds: 800)});

  final Duration cooldown;
  bool _locked = false;

  Future<void> run(Future<void> Function() action) async {
    if (_locked) return;
    _locked = true;
    try {
      await action();
    } finally {
      Timer(cooldown, () => _locked = false);
    }
  }
}
