package com.example.inviscan

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "inviscan/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                // Diretório executável onde as ferramentas empacotadas como
                // lib<tool>.so são extraídas (única área com exec no Android 10+).
                "nativeLibDir" -> result.success(applicationInfo.nativeLibraryDir)
                else -> result.notImplemented()
            }
        }
    }
}
