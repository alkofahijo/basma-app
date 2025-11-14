import org.gradle.api.JavaVersion
import org.gradle.api.tasks.compile.JavaCompile

plugins {
    // يطابق الإعداد الموجود في settings.gradle.kts
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.basma_app"
    // قيم flutter تأتي من Flutter Gradle Plugin
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // إعدادات Java للـ Android module
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // إعدادات Kotlin
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // عدّل الـ applicationId لو حابب اسم مختلف
        applicationId = "com.example.basma_app"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // مؤقتاً: نستخدم debug key عشان flutter run --release يشتغل
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// إعداد Flutter (لا تلمسه عادة)
flutter {
    source = "../.."
}

// نضمن أن كل مهام JavaCompile تستخدم Java 17
tasks.withType<JavaCompile>().configureEach {
    sourceCompatibility = JavaVersion.VERSION_17.toString()
    targetCompatibility = JavaVersion.VERSION_17.toString()

    // لو حابب تكتم تحذيرات الـ options القديمة بالكامل، فكّ التعليق:
    // options.compilerArgs.add("-Xlint:-options")
}
