package com.example.ar_animal_zoo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.ar.core.ArCoreApk

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.ar_animal_zoo/ar_check"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isARCoreInstalled") {
                // Kiểm tra xem ARCore đã cài đặt và sẵn sàng chưa
                val availability = ArCoreApk.getInstance().checkAvailability(context)
                
                if (availability.isTransient) {
                    // Nếu đang kiểm tra (chưa có kết quả ngay), thử lại sau một chút
                    // Ở đây trả về false để an toàn
                    result.success(false)
                } else {
                    // Trả về true nếu đã cài đặt (SUPPORTED_INSTALLED)
                    result.success(availability == ArCoreApk.Availability.SUPPORTED_INSTALLED)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}