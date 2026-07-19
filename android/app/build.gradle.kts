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
            // No fallback — the build FAILS if these are not set. This forces
            // the release engineer to configure them explicitly and prevents
            // the old default "android123" from being used accidentally.
            storePassword = providers.systemProperty("NEON_FLAP_STORE_PASSWORD")
                .orElse(providers.environmentVariable("NEON_FLAP_STORE_PASSWORD"))
                .get()
            keyAlias = providers.systemProperty("NEON_FLAP_KEY_ALIAS")
                .orElse(providers.environmentVariable("NEON_FLAP_KEY_ALIAS"))
                .orElse("neon_flap_release")
                .get()
            keyPassword = providers.systemProperty("NEON_FLAP_KEY_PASSWORD")
                .orElse(providers.environmentVariable("NEON_FLAP_KEY_PASSWORD"))
                .get()
        }
    }

    buildTypes {
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
