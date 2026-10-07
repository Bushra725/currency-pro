package com.theoccess.currencypro

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HAPTICS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "tick") {
                tick()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LINKS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "openUrl") {
                val url = call.arguments as? String
                result.success(openUrl(url))
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openUrl(url: String?): Boolean {
        if (url.isNullOrBlank()) return false
        val uri = Uri.parse(url)
        // mailto: needs ACTION_SENDTO. ACTION_VIEW is handled by browsers on
        // some devices and by nothing at all on others.
        val action =
            if (uri.scheme.equals("mailto", ignoreCase = true)) Intent.ACTION_SENDTO
            else Intent.ACTION_VIEW
        return try {
            val intent = Intent(action, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) == null) return false
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun tick() {
        val vibrator = vibrator() ?: return
        val ms = 70L
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val amplitude =
                    if (vibrator.hasAmplitudeControl()) 255
                    else VibrationEffect.DEFAULT_AMPLITUDE
                // No AudioAttributes / USAGE_ALARM: Samsung and DND often
                // swallow those, which is why the plugin buzz never fired.
                vibrator.vibrate(
                    VibrationEffect.createOneShot(ms, amplitude),
                );
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(ms)
            }
        } catch (_: Exception) {
            try {
                @Suppress("DEPRECATION")
                vibrator.vibrate(ms)
            } catch (_: Exception) {
            }
        }
    }

    private fun vibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager =
                getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    companion object {
        private const val HAPTICS_CHANNEL = "com.theoccess.currencypro/haptics"
        private const val LINKS_CHANNEL = "com.theoccess.currencypro/links"
    }
}
