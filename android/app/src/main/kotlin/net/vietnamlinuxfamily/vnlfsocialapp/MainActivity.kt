package net.vietnamlinuxfamily.vnlfsocialapp

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "net.vietnamlinuxfamily.vnlfsocialapp/background_sync"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    try {
                        val intent = Intent(this, VnlfBackgroundSyncService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_FAILED", e.message, null)
                    }
                }
                "stopService" -> {
                    // Stops a running service and does nothing otherwise.
                    result.success(stopBackgroundService())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        // The Flutter engine, and with it the realtime connection, goes away
        // with this activity, so the service would keep nothing alive.
        if (!isChangingConfigurations) stopBackgroundService()
        super.onDestroy()
    }

    private fun stopBackgroundService(): Boolean =
        stopService(Intent(this, VnlfBackgroundSyncService::class.java))
}
