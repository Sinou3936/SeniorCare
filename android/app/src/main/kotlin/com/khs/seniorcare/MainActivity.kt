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
    // turnScreenOn으로 화면이 켜지기 전에 캡처해야 정확하므로 onCreate/onNewIntent에서 즉시 저장.
    private var screenOnAtLaunch = true

    private fun captureScreenState() {
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        screenOnAtLaunch = pm.isInteractive
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        captureScreenState() // 앱 종료 상태에서 알람으로 시작된 경우
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        captureScreenState() // 백그라운드 앱이 알람으로 복귀된 경우 (super가 플러그인에 전달하기 전에 캡처)
        super.onNewIntent(intent)
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
