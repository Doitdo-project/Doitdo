import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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

// Release keystore 정보. android/key.properties (gitignored) 에서 읽는다.
// 파일이 없으면 release signingConfig 를 만들지 않고, release 빌드가 debug keystore
// 로 폴백 + 빌드 로그에 경고가 찍힌다. 마켓 업로드용 AAB 는 반드시 key.properties 가
// 채워진 상태에서 빌드해야 한다 (Play Store / OneStore 모두 debug 서명 거부).
// 템플릿은 android/key.properties.example 참고.
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keyPropertiesFile.exists().also {
    if (it) FileInputStream(keyPropertiesFile).use { stream -> keyProperties.load(stream) }
}

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

    // ─────────────────────────────────────────────────────────────
    // 공용 debug keystore.
    // 개인 `~/.android/debug.keystore` 가 아니라 프로젝트 내부의 파일을 쓰도록
    // 강제해 팀 누구 PC 에서 빌드해도 동일한 SHA-1 이 나오게 한다.
    // SHA-1 은 Firebase / Google Cloud Console / Kakao Developers 에 한 번만 등록.
    // storepass/keypass/alias 는 Android 디버그 keystore 의 관례적 고정값.
    // ─────────────────────────────────────────────────────────────
    signingConfigs {
        getByName("debug") {
            storeFile = rootProject.file("keystore/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        if (hasReleaseKeystore) {
            create("release") {
                // android/key.properties 에서 RELEASE_* 4개 항목을 읽는다.
                // RELEASE_STORE_FILE 은 android/ 기준 상대경로 (보통 keystore/doitdo-release.jks).
                storeFile = rootProject.file(keyProperties.getProperty("RELEASE_STORE_FILE"))
                storePassword = keyProperties.getProperty("RELEASE_STORE_PASSWORD")
                keyAlias = keyProperties.getProperty("RELEASE_KEY_ALIAS")
                keyPassword = keyProperties.getProperty("RELEASE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // android/key.properties 가 있으면 release 키, 없으면 debug 키로 폴백.
            // 폴백 빌드는 로컬 release-mode 동작 확인용 — 마켓 업로드 시엔 반드시 release 키가 필요.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("[doitdo] android/key.properties 없음 — release 빌드가 debug 키로 서명됩니다. 마켓 업로드용이라면 키 발급 후 재빌드하세요.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // 위젯의 BroadcastReceiver 컨텍스트에서 BE 로 진짜 PATCH 요청을 보내야 한다.
    // HttpURLConnection 의 PATCH reflection 우회는 Android 12+ 의 SDK 제한으로 silent
    // 무시되는 경우가 있어 신뢰할 수 없음 — OkHttp 의 정식 PATCH 사용으로 교체.
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
}
