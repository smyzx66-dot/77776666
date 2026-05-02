plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hmed.edson"
    compileSdk = 36 // 🔥 تم التعديل إلى 36 لحل مشكلة محرك الفيديو

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.hmed.edson"
        minSdk = 21 // 🔥 تم التعديل إلى 21 لأن المشغل الجديد يحتاجه
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            // تفعيل التصغير لتقليل الحجم
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // استخدام مفتاح الديباج مؤقتاً للتوقيع حتى يشتغل البناء
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // حل مشكلة Desugaring للأجهزة القديمة
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}