plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

repositories {
    google()
    mavenCentral()
}

android {
    namespace = "com.neonflap1.game"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.neonflap1.game"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("../neon_flap_release.jks")
            // Lazy evaluation: getOrNull() returns null when the env var /
            // system property is absent so the config block never throws at
            // configuration time (which would also break debug builds).
            storePassword = providers.systemProperty("NEON_FLAP_STORE_PASSWORD")
                .orElse(providers.environmentVariable("NEON_FLAP_STORE_PASSWORD"))
                .getOrNull()
            keyAlias = providers.systemProperty("NEON_FLAP_KEY_ALIAS")
                .orElse(providers.environmentVariable("NEON_FLAP_KEY_ALIAS"))
                .getOrElse("neon_flap_release")
            keyPassword = providers.systemProperty("NEON_FLAP_KEY_PASSWORD")
                .orElse(providers.environmentVariable("NEON_FLAP_KEY_PASSWORD"))
                .getOrNull()
        }
    }

    buildTypes {
        debug {
            // Default debug signing (no keystore required).
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM manages all Firebase SDK versions. Individual SDKs
    // (auth, firestore, crashlytics) are pulled in by their Flutter plugins.
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))
}
