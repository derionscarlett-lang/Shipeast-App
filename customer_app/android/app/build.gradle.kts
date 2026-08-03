import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load the release signing config from android/key.properties if it exists.
// The file (and the keystore it points to) are git-ignored — see android/.gitignore.
// When absent (e.g. a fresh clone or CI without the secret), we fall back to debug
// signing so the project still builds.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// A release build without the real keystore used to fall through to the debug key
// and say nothing. That produces an APK which looks fine here and then fails to
// install on anyone who already has a properly-signed ShipEast: Android refuses an
// update whose signature does not match, and several OEM installers word that
// refusal as a security error rather than a signature one. Play Protect is also
// far harder on anything carrying the well-known `CN=Android Debug` certificate.
// A build that cannot be signed for real should stop, not ship.
if (!hasReleaseSigning &&
    gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
) {
    throw GradleException(
        "Release build requested, but customer_app/android/key.properties is missing, " +
            "so this APK would be signed with the debug key and would not install as an " +
            "update over any released ShipEast build. Restore key.properties and the " +
            "keystore it points at (both git-ignored, kept in .secret/), or build --debug."
    )
}

android {
    namespace = "com.shipeast.customerapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.shipeast.customerapp"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String

                // Sign with every scheme the platform understands, not just the one
                // AGP picks by default. At minSdk 24 AGP turns v1 OFF and leaves v3
                // OFF, which shipped a v2-only APK — and v2/v3 sign the archive as a
                // whole, so any transfer that re-zips the file (a few file-share and
                // cloud apps do) invalidates the signature with nothing to fall back
                // on, and the phone reports the package as unverifiable. v1 is
                // per-entry and survives that. Several OEM package installers also
                // still read the v1 JAR manifest first. The cost is a handful of
                // extra kilobytes; the failure it removes is unexplainable to a user.
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
                // v4 is for `adb install --incremental` only, and emits a separate
                // .idsig file that would just confuse the download we hand out.
                enableV4Signing = false
            }
        }
    }

    buildTypes {
        release {
            // Sign with the ShipEast release keystore (android/key.properties) when present,
            // so installed builds are self-consistent and update cleanly. Falls back to the
            // debug key only if key.properties is missing (fresh clone / CI without the secret).
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Disable R8 minification to prevent stripping of plugin classes
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
