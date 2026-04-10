plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.hello"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            keyAlias = "kitchencraft"
            keyPassword = "kitchencraft123"
            storeFile = file("./kitchencraft-release.keystore")
            storePassword = "kitchencraft123"
        }
    }

    defaultConfig {
        applicationId = "com.kitchencraft2"
        minSdk = 24
        targetSdk = 35
        versionCode = 2
        versionName = "1.1"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.10.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}

tasks.matching { it.name == "assembleDebug" }.configureEach {
    doLast {
        val sourceApk = layout.buildDirectory.file("outputs/flutter-apk/app-debug.apk").get().asFile
        val targetDir = rootDir.resolve("../build/app/outputs/flutter-apk")
        val targetApk = targetDir.resolve("app-debug.apk")

        if (sourceApk.exists()) {
            targetDir.mkdirs()
            sourceApk.copyTo(targetApk, overwrite = true)
        }
    }
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    doLast {
        val sourceApk = layout.buildDirectory.file("outputs/apk/release/app-release.apk").get().asFile
        val targetDir = rootDir.resolve("../build/app/outputs/flutter-apk")
        val targetApk = targetDir.resolve("app-release.apk")

        if (sourceApk.exists()) {
            targetDir.mkdirs()
            sourceApk.copyTo(targetApk, overwrite = true)
            println("✓ Release APK copied to: ${targetApk.absolutePath}")
        } else {
            println("✗ Release APK not found at: ${sourceApk.absolutePath}")
        }
    }
}
