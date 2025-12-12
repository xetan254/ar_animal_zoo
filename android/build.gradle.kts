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

    // --- CRITICAL FIX: SKIP THE APP MODULE ---
    // Prevents "Project.afterEvaluate(Action) when the project is already evaluated" error
    if (subProject.name == "app") {
        return@subprojects
    }

    subProject.afterEvaluate {
        // Fix 1: Force Java 17 for older plugins
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
        
        // Fix 2: Namespace fixes for specific plugins
        if (subProject.name == "ar_flutter_plugin") {
            doFixLogic(subProject, "io.carius.lars.ar_flutter_plugin", "io.carmine.ar_flutter_plugin")
        }
        if (subProject.name == "flutter_vision") {
            doFixLogic(subProject, "com.vladih.computer_vision.flutter_vision", "com.vladih.computer_vision.flutter_vision")
        }
    }
}

fun doFixLogic(project: Project, oldPackageName: String, newNamespace: String) {
    try {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension != null) {
            val setNamespaceMethod = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
            setNamespaceMethod.invoke(androidExtension, newNamespace)
        }
    } catch (e: Exception) {}
}