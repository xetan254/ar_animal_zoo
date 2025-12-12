import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// --- FIX QUAN TRỌNG: LOẠI BỎ FLATBUFFERS TRÙNG LẶP ---
// Đoạn này bảo Gradle: "Đừng tải file flatbuffers riêng lẻ nữa, hãy dùng cái có sẵn trong AR"
configurations.all {
    exclude(group = "com.google.flatbuffers", module = "flatbuffers-java")
}
// ------------------------------------------------------

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
val flutterVersionName = localProperties.getProperty("flutter.versionName")

android {
    namespace = "com.example.ar_animal_zoo"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.example.ar_animal_zoo"
        minSdk = 24
        targetSdk = 36
        versionCode = flutterVersionCode?.toIntOrNull() ?: 1
        versionName = flutterVersionName ?: "1.0"
        
        // Bắt buộc bật Multidex cho các app AR/AI nặng
        multiDexEnabled = true 
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    aaptOptions {
        noCompress.add("tflite")
        noCompress.add("glb")
    }

    // Vẫn giữ cấu hình packaging để xử lý các file trùng khác (nếu có)
    packaging {
        resources {
            pickFirst("**/libflatbuffers.so")
            pickFirst("META-INF/**") 
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}