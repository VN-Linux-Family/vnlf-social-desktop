import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val appKeystorePropertiesFile = project.file("key.properties")
val keyPropsFile = when {
    appKeystorePropertiesFile.exists() -> appKeystorePropertiesFile
    keystorePropertiesFile.exists() -> keystorePropertiesFile
    else -> null
}
if (keyPropsFile != null) {
    keystoreProperties.load(FileInputStream(keyPropsFile))
}

android {
    namespace = "net.vietnamlinuxfamily.vnlfsocialapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "net.vietnamlinuxfamily.vnlfsocialapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storePath = keystoreProperties.getProperty("storeFile") ?: "release.keystore"
            val resolvedStore = project.file(storePath).takeIf { it.exists() }
                ?: rootProject.file(storePath).takeIf { it.exists() }
                ?: project.file("release.keystore").takeIf { it.exists() }

            if (resolvedStore != null && resolvedStore.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: "vnlf"
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: "vnlfsocialapp"
                storeFile = resolvedStore
                storePassword = keystoreProperties.getProperty("storePassword") ?: "vnlfsocialapp"
            }
        }
    }

    buildTypes {
        release {
            val relConfig = signingConfigs.getByName("release")
            signingConfig = if (relConfig.storeFile?.exists() == true) {
                relConfig
            } else {
                signingConfigs.getByName("debug")
            }
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
