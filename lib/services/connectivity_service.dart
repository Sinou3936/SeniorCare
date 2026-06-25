import 'dart:io';
import 'package:flutter/material.dart';

/// 네트워크 연결 확인 (패키지 없이 dart:io 기본 사용).
/// DNS 조회(InternetAddress.lookup)는 OS DNS 캐시에 속아 오프라인인데 true가 나올 수 있어
/// (온라인→오프라인 직후 호스트 주소가 캐시에 남음), **실제 소켓 연결**로 판단한다.
class ConnectivityService {
  static Future<bool> isOnline() async {
    Socket? socket;
    try {
      socket = await Socket.connect('firestore.googleapis.com', 443,
          timeout: const Duration(seconds: 4));
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }
}

/// 온라인 필수 기능(가족 모드·코드 발급)에서 오프라인일 때 보여주는 전체화면 차단 위젯.
/// Scaffold body 안에 넣어 사용. [onRetry]로 연결 재확인.
class OfflineGate extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const OfflineGate({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 72, color: Color(0xFFE8896A)),
              const SizedBox(height: 24),
              const Text('인터넷 연결이 필요해요',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, height: 1.5, color: Color(0xFF888888))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8896A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('다시 시도',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 온라인이면 true. 오프라인이면 안내 다이얼로그를 띄우고 false 반환.
/// 온라인 필수 동작(구글 계정 연결·초기화·약/병원 추가·수정·삭제 등) 시작 전에 호출.
/// [message]로 동작별 안내 문구를 바꿀 수 있음(미지정 시 기본 문구).
Future<bool> ensureOnline(BuildContext context, {String? message}) async {
  if (await ConnectivityService.isOnline()) return true;
  if (!context.mounted) return false;
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('인터넷 연결 필요',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      content: Text(message ?? 'Wi-Fi나 데이터(테더링)를 켜고\n다시 시도해주세요.',
          style: const TextStyle(fontSize: 17, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  return false;
}
