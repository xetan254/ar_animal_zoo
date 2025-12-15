# --- AR Sceneform Rules (Fix lỗi Missing classes) ---
-keep class com.google.ar.sceneform.** { *; }
-dontwarn com.google.ar.sceneform.**

# --- Fix lỗi Animation & Loader ---
-keep class com.google.ar.sceneform.animation.** { *; }
-keep class com.google.ar.sceneform.assets.** { *; }
-keep class com.google.ar.sceneform.rendering.** { *; }

# --- Fix lỗi Desugar (ThrowableExtension) ---
-dontwarn com.google.devtools.build.android.desugar.runtime.**
-keep class com.google.devtools.build.android.desugar.runtime.** { *; }

# --- Các cấu hình an toàn khác cho Flutter ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Bỏ qua cảnh báo để quá trình build không bị dừng đột ngột
-ignorewarnings