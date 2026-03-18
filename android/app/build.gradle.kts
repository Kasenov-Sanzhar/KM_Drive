plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin — обязательно последним
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase / Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.km_drive"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ Обязательно для flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.km_drive"
        minSdk = flutter.minSdkVersion                          // Firebase Messaging требует minSdk 23+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lint {
        disable += "ObsoleteSdkInt"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Desugaring — обязательно для flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Multidex (если minSdk < 21, но лучше оставить)
    implementation("androidx.multidex:multidex:2.0.1")
}
