import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/prefs_service.dart';
import '../senior/senior_main_screen.dart';

class MedicineAlarmScreen extends StatefulWidget {
  final String time; // "08:00"
  const MedicineAlarmScreen({super.key, required this.time});

  @override
  State<MedicineAlarmScreen> createState() => _MedicineAlarmScreenState();
}

class _MedicineAlarmScreenState extends State<MedicineAlarmScreen> {
  List<Map<String, String>> _medicines = [];
  Timer? _autoCloseTimer;
  final _ringtonePlayer = FlutterRingtonePlayer();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 화면 켜진 상태 유지
    await WakelockPlus.enable();

    // 캐시에서 해당 시간대 약 목록 로드
    final schedule = await PrefsService.loadMedicineSchedule();
    setState(() {
      _medicines = schedule[widget.time] ?? [];
    });

    // 알람음 루프 시작 — 방해금지 모드면 소리 스킵 (진동·화면은 그대로)
    final dnd = await NotificationService.isDndActive();
    if (!dnd) {
      _ringtonePlayer.playAlarm(looping: true);
    }

    // 1분 후 자동 종료 — 사용자 무반응이므로 앱 닫고 잠금화면 복귀
    _autoCloseTimer = Timer(const Duration(minutes: 1), () => _dismiss(closeApp: true));
  }

  /// [closeApp] true = 앱 종료(잠금화면 복귀), false = 홈 화면으로 이동
  void _dismiss({bool closeApp = false}) {
    _ringtonePlayer.stop();                              // Flutter 벨소리 정지
    NotificationService.cancelSlotAlarm(widget.time);    // 알림 INSISTENT 진동/소리 정지
    WakelockPlus.disable();
    _autoCloseTimer?.cancel();
    if (!mounted) return;

    if (closeApp) {
      // 스누즈·자동종료 → 앱 들어가지 않고 잠금화면으로 복귀
      SystemNavigator.pop();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // root로 실행된 경우 (화면 OFF 알람) → 홈 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SeniorMainScreen()),
      );
    }
  }

  Future<void> _onDone() async {
    // 실제 복용 처리 (오늘 이 시간대 로그 taken:true) + 자동 리마인더 취소 후 홈으로
    await FirestoreService.markDoseTakenAt(widget.time);
    await NotificationService.cancelSlotReminder(widget.time);
    _dismiss();
  }

  Future<void> _onSnooze() async {
    _ringtonePlayer.stop();
    WakelockPlus.disable();
    _autoCloseTimer?.cancel();

    // 자동 리마인더 취소 후 수동 스누즈 등록 (중복 방지)
    await NotificationService.cancelSlotReminder(widget.time);
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    await NotificationService.scheduleSnoozeAlarm(
      time: widget.time,
      medicineNames: _medicines.map((m) => m['name'] ?? '').toList(),
      scheduledAt: snoozeTime,
    );

    if (mounted) _dismiss(closeApp: true);
  }

  String _slotLabel() {
    final parts = widget.time.split(':');
    final hour = int.parse(parts[0]);
    if (hour < 7) return '새벽';
    if (hour < 10) return '아침';
    if (hour < 17) return '점심';
    if (hour < 20 || (hour == 20 && int.parse(parts[1]) < 30)) return '저녁';
    return '취침';
  }

  IconData _slotIcon() {
    switch (_slotLabel()) {
      case '새벽': return Icons.dark_mode_outlined;
      case '아침': return Icons.wb_sunny_outlined;
      case '점심': return Icons.light_mode_outlined;
      case '저녁': return Icons.wb_twilight_outlined;
      case '취침': return Icons.bedtime_outlined;
      default: return Icons.access_time;
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _ringtonePlayer.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 뒤로가기 비활성 (알람은 버튼으로만 종료)
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              // 상단 슬롯 정보
              Container(
                width: double.infinity,
                color: const Color(0xFFE8896A),
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(_slotIcon(), color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      '${_slotLabel()} 복약 시간이에요',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.time,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // 약 목록
              Expanded(
                child: _medicines.isEmpty
                    ? const Center(
                        child: Text('약 정보를 불러오는 중...', style: TextStyle(fontSize: 18)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _medicines.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final name = _medicines[i]['name'] ?? '';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE8896A), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.medication_rounded,
                                    color: Color(0xFFE8896A), size: 28),
                                const SizedBox(width: 14),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // 버튼 영역
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _onDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8896A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          '복용 완료',
                          style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _onSnooze,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFE8896A), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          '10분 후 다시 알림',
                          style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFFE8896A),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
