import java.io.File
import java.io.FileInputStream
import java.util.*

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties().apply {
    // load your *.properties file
    load(FileInputStream(File("key.properties")))
}

// Get all properties from key.properties file
val detKeyAlias = keyProperties.getProperty("keyAlias")
val detKeyPassword = keyProperties.getProperty("keyPassword")
val detStoreFile = keyProperties.getProperty("storeFile")
val detStorePassword = keyProperties.getProperty("storePassword")

// Validate that required properties exist
require(detKeyAlias != null) { "keyAlias not found in key.properties file." }
require(detKeyPassword != null) { "keyPassword not found in key.properties file." }
require(detStoreFile != null) { "storeFile not found in key.properties file." }
require(detStorePassword != null) { "storePassword not found in key.properties file." }

android {
    namespace = "de.doen1el.calibreWebCompanion"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "de.doen1el.calibreWebCompanion"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode * 10 + 3
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = detKeyAlias
            keyPassword = detKeyPassword
            storeFile = file(detStoreFile)
            storePassword = detStorePassword
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}