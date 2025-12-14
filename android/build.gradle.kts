// --- 1. KHỐI PLUGINS (THÊM MỚI VÀO ĐẦU FILE) ---
plugins {
    // Phiên bản Gradle cho Android (bạn có thể chỉnh version nếu project yêu cầu khác)
    id("com.android.application") version "8.11.1" apply false
    // Phiên bản Kotlin
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // Plugin Google Services (Firebase) - ĐÂY LÀ CÁI BẠN CẦN
    id("com.google.gms.google-services") version "4.4.0" apply false
}

import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val clean by tasks.registering(Delete::class) {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val subProject = this

    afterEvaluate {
        // --- FIX 1: ÉP ĐỒNG BỘ JAVA 17 CHO CẢ JAVA VÀ KOTLIN ---
        val android = subProject.extensions.findByName("android")
        if (android != null) {
            try {
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
                compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
            } catch (e: Exception) {
                 subProject.tasks.withType(JavaCompile::class.java).configureEach {
                    sourceCompatibility = JavaVersion.VERSION_17.toString()
                    targetCompatibility = JavaVersion.VERSION_17.toString()
                }
            }
        }

        subProject.tasks.withType(KotlinCompile::class.java).configureEach {
            compilerOptions {
                jvmTarget.set(JvmTarget.JVM_17)
            }
        }
    }

    // --- FIX 2: VÁ LỖI NAMESPACE CHO CÁC PLUGIN CŨ ---
    
    // CASE A: AR Flutter Plugin
    if (subProject.name == "ar_flutter_plugin") {
        applyFix(subProject, "io.carius.lars.ar_flutter_plugin", "io.carmine.ar_flutter_plugin")
    }

    // CASE B: Flutter Vision
    if (subProject.name == "flutter_vision") {
        applyFix(subProject, "com.vladih.computer_vision.flutter_vision", "com.vladih.computer_vision.flutter_vision")
    }
}

// Hàm xử lý chung: Xóa package trong Manifest và Set Namespace trong Gradle
fun applyFix(project: Project, oldPackageName: String, newNamespace: String) {
    if (project.state.executed) {
        doFixLogic(project, oldPackageName, newNamespace)
    } else {
        project.afterEvaluate {
            doFixLogic(project, oldPackageName, newNamespace)
        }
    }
}

fun doFixLogic(project: Project, oldPackageName: String, newNamespace: String) {
    println("🔧 Đang vá lỗi cho thư viện: ${project.name}...")

    // Bước A: Tìm và xóa dòng 'package="..."' trong AndroidManifest.xml
    try {
        val manifestFile = project.file("src/main/AndroidManifest.xml")
        if (manifestFile.exists()) {
            var content = manifestFile.readText(Charsets.UTF_8)
            val offendingString = "package=\"$oldPackageName\""
            
            if (content.contains(offendingString)) {
                content = content.replace(offendingString, "")
                manifestFile.writeText(content, Charsets.UTF_8)
                println("   ✅ Đã xóa 'package' attribute cũ trong Manifest")
            }
        }
    } catch (e: Exception) {
        println("   ⚠️ Lỗi nhẹ khi sửa Manifest: $e")
    }

    // Bước B: Inject Namespace mới vào cấu hình build
    try {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension != null) {
            val setNamespaceMethod = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
            setNamespaceMethod.invoke(androidExtension, newNamespace)
            println("   ✅ Đã set namespace mới: $newNamespace")
        }
    } catch (e: Exception) {
        println("   ⚠️ Lỗi khi set namespace: $e")
    }
}