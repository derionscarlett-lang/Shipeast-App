package com.shipeast.shipeast_customer

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

// Flutter regenerates GeneratedPluginRegistrant.java with `catch (Exception e)` only,
// which silently swallows UnsatisfiedLinkError (a java.lang.Error) from JNI native
// library loading failures, crashing the app. We register each plugin individually
// here so a failure in one (e.g. jni) cannot prevent the rest from loading.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        registerPlugin(flutterEngine, "flutter_plugin_android_lifecycle") {
            flutterEngine.plugins.add(io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin())
        }
        registerPlugin(flutterEngine, "image_picker_android") {
            flutterEngine.plugins.add(io.flutter.plugins.imagepicker.ImagePickerPlugin())
        }
        registerPlugin(flutterEngine, "jni") {
            flutterEngine.plugins.add(com.github.dart_lang.jni.JniPlugin())
        }
        registerPlugin(flutterEngine, "jni_flutter") {
            flutterEngine.plugins.add(com.github.dart_lang.jni_flutter.JniFlutterPlugin())
        }
        registerPlugin(flutterEngine, "shared_preferences_android") {
            flutterEngine.plugins.add(io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin())
        }
        registerPlugin(flutterEngine, "sqflite_android") {
            flutterEngine.plugins.add(com.tekartik.sqflite.SqflitePlugin())
        }
        registerPlugin(flutterEngine, "url_launcher_android") {
            flutterEngine.plugins.add(io.flutter.plugins.urllauncher.UrlLauncherPlugin())
        }
        registerPlugin(flutterEngine, "webview_flutter_android") {
            flutterEngine.plugins.add(io.flutter.plugins.webviewflutter.WebViewFlutterPlugin())
        }
    }

    private fun registerPlugin(flutterEngine: FlutterEngine, name: String, block: () -> Unit) {
        try {
            block()
        } catch (t: Throwable) {
            Log.e("ShipEast", "Plugin $name failed to register: ${t.javaClass.simpleName}: ${t.message}", t)
        }
    }
}
