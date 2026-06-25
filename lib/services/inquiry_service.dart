import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 문의 발송 — Cloud Function(`sendInquiry`, nodemailer + Gmail)으로 이메일 전송.
/// 휴대폰 정보(기기 모델/OS/앱 버전)를 함께 보내 메일 본문 템플릿에 포함.
class InquiryService {
  static Future<void> send({
    required String category,
    required String content,
  }) async {
    final deviceInfo = await _deviceInfoString();
    final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast3')
        .httpsCallable('sendInquiry');
    await callable.call<dynamic>({
      'category': category,
      'content': content,
      'deviceInfo': deviceInfo,
    });
  }

  /// 예: "SM-A315N / Android 12 / 앱 v1.0.0"
  static Future<String> _deviceInfoString() async {
    final parts = <String>[];
    try {
      if (Platform.isAndroid) {
        final a = await DeviceInfoPlugin().androidInfo;
        parts.add(a.model);
        parts.add('Android ${a.version.release}');
      } else if (Platform.isIOS) {
        final i = await DeviceInfoPlugin().iosInfo;
        parts.add(i.utsname.machine);
        parts.add('iOS ${i.systemVersion}');
      }
      final pkg = await PackageInfo.fromPlatform();
      parts.add('앱 v${pkg.version}');
    } catch (_) {
      // 정보 수집 실패해도 문의는 보내짐
    }
    return parts.isEmpty ? '알 수 없음' : parts.join(' / ');
  }
}
