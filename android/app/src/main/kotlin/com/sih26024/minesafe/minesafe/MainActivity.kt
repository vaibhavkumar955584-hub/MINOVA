package com.sih26024.minesafe.minesafe

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sih26024.minesafe/launcher_shortcuts"
    private var methodChannel: MethodChannel? = null
    private var initialShortcut: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent, isInitial = true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "getInitialShortcut" -> {
                    val shortcut = initialShortcut
                    initialShortcut = null
                    result.success(shortcut)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent, isInitial = false)
    }

    private fun handleIntent(intent: Intent?, isInitial: Boolean) {
        if (intent == null) return
        val data = intent.data ?: return
        if (data.scheme == "minova" && data.host == "shortcut") {
            val action = data.lastPathSegment ?: data.path?.removePrefix("/")
            if (action != null) {
                if (isInitial && methodChannel == null) {
                    initialShortcut = action
                } else {
                    methodChannel?.invokeMethod("onShortcutTriggered", action)
                }
            }
        }
    }
}
