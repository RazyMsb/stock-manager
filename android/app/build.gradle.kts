plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("com.google.gms.google-services") // Add this line for Firebase
}

android {
    namespace = "com.exemple.stockmanager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.exemple.stockmanager"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("com.google.firebase:firebase-database-ktx") // Firebase Realtime Database dependency
    implementation("com.google.firebase:firebase-auth-ktx") // Firebase Auth if you are using authentication

    // Firebase BoM (Bill of Materials) - This allows you to manage Firebase SDK versions
    implementation(platform("com.google.firebase:firebase-bom:30.0.1")) // Update to the latest Firebase BOM version
}

flutter {
    source = "../.."
}
