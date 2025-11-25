import org.gradle.api.JavaVersion
import org.gradle.api.tasks.compile.JavaCompile
import java.util.Properties
import java.io.FileInputStream

plugins {
    // يطابق الإعداد الموجود في settings.gradle.kts
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.basma.volunteering"
    // قيم flutter تأتي من Flutter Gradle Plugin
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Load signing properties if present (key.properties at project root)
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

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
        applicationId = "com.basma.volunteering"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Release signing will be configured from key.properties when available and complete.
        val storeFileProp = keystoreProperties.getProperty("storeFile")
        val storePasswordProp = keystoreProperties.getProperty("storePassword")
        val keyAliasProp = keystoreProperties.getProperty("keyAlias")
        val keyPasswordProp = keystoreProperties.getProperty("keyPassword")

        if (keystorePropertiesFile.exists()
            && !storeFileProp.isNullOrBlank()
            && !storePasswordProp.isNullOrBlank()
            && !keyAliasProp.isNullOrBlank()
            && !keyPasswordProp.isNullOrBlank()) {
            create("release") {
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                storeFile = file(storeFileProp)
                storePassword = storePasswordProp
            }
        }
    }

    buildTypes {
        release {
            // Use release signing if configured, otherwise fall back to debug for local testing.
            if (signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
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
