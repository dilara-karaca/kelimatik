import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.kelimatik.kelimatik"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kelimatik.kelimatik"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // google_mobile_ads requires minSdk 23+.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Native debug symbols for Play Console crash symbolication.
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// AGP leaves extractReleaseNativeSymbolTables empty for Flutter's already-stripped
// engine .so files, so package merged native libs for Play Console upload.
val zipReleaseNativeDebugSymbols by tasks.registering(Zip::class) {
    description = "Zips merged native libraries for Google Play debug-symbol upload."
    group = "build"
    dependsOn("mergeReleaseNativeLibs")
    from(
        layout.buildDirectory.dir(
            "intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib",
        ),
    )
    archiveFileName.set("native-debug-symbols.zip")
    destinationDirectory.set(
        layout.buildDirectory.dir("outputs/native-debug-symbols/release"),
    )
}

tasks.configureEach {
    if (name == "bundleRelease") {
        finalizedBy(zipReleaseNativeDebugSymbols)
    }
}
