import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase — google-services.json 을 빌드 타임에 읽어 리소스로 주입.
    // settings.gradle.kts 에서 버전 선언한 플러그인을 여기서 실제 적용.
    id("com.google.gms.google-services")
}

// Kakao 네이티브 앱 키는 AndroidManifest 의 redirect scheme(kakao{KEY}://oauth) 에
// 빌드타임에 주입돼야 하므로 local.properties 에서 읽어 manifestPlaceholders 로 전달.
// 키가 없으면 빈 문자열이 들어가고, Kakao 로그인 시도 시 SDK 레벨에서 에러가 난다.
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    FileInputStream(localPropertiesFile).use { localProperties.load(it) }
}
val kakaoNativeAppKey: String =
    localProperties.getProperty("KAKAO_NATIVE_APP_KEY") ?: ""

android {
    namespace = "com.d107.doitdo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.d107.doitdo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["kakaoNativeAppKey"] = kakaoNativeAppKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
