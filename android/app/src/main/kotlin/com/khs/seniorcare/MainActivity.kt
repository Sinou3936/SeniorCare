package com.khs.seniorcare

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "yakbom/battery"

    // 앱이 깨어나는 순간(앱 시작/백그라운드 복귀) 화면이 켜져 있었는지.
    // 매니페스트 turnScreenOn 제거 → 시스템이 화면을 먼저 안 켜므로 여기서 읽으면 진짜 상태.
    // 읽은 뒤 우리가 직접 화면을 켠다(setTurnScreenOn) → "읽기→켜기" 순서를 앱이 통제.
    private var screenOnAtLaunch = true

    private fun captureScreenState() {
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        screenOnAtLaunch = pm.isInteractive
    }

    private fun showOverLockAndTurnScreenOn() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        captureScreenState()          // ① 화면 상태 먼저 읽기 (아직 안 켜진 상태)
        super.onCreate(savedInstanceState)
        showOverLockAndTurnScreenOn() // ② 그 다음 우리가 직접 화면 켜기
    }

    override fun onNewIntent(intent: Intent) {
        captureScreenState()          // ① 백그라운드 복귀 시에도 먼저 읽기
        super.onNewIntent(intent)
        showOverLockAndTurnScreenOn() // ② 직접 화면 켜기
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                        }
                    }
                    result.success(null)
                }
                "wasScreenOnAtLaunch" -> {
                    // 알람으로 앱이 깨어난 순간 화면이 켜져 있었는지 (true=사용자 탭, false=화면OFF 자동실행)
                    result.success(screenOnAtLaunch)
                }
                "isDndActive" -> {
                    // 방해금지 모드가 켜져 있는지 (전체 허용이 아니면 켜진 것으로 간주)
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    val filter = nm.currentInterruptionFilter
                    val dndOn = filter != NotificationManager.INTERRUPTION_FILTER_ALL &&
                        filter != NotificationManager.INTERRUPTION_FILTER_UNKNOWN
                    result.success(dndOn)
                }
                else -> result.notImplemented()
            }
        }
    }
}
