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
    FileInputStream(keyPropsFile).use { keystoreProperties.load(it) }
}

val signingKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasReleaseSigning = keyPropsFile != null && signingKeys.all {
    !keystoreProperties.getProperty(it).isNullOrBlank()
}
val releaseRequested = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (releaseRequested && !hasReleaseSigning) {
    throw GradleException("Release signing requires an ignored key.properties file with storeFile, storePassword, keyAlias, and keyPassword.")
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
        if (hasReleaseSigning) {
            create("release") {
                val storePath = keystoreProperties.getProperty("storeFile")
                val configuredStore = project.file(storePath).takeIf { it.exists() }
                    ?: rootProject.file(storePath).takeIf { it.exists() }
                if (configuredStore == null) {
                    throw GradleException("The configured release keystore does not exist.")
                }
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = configuredStore
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.15.0")
        force("androidx.core:core-ktx:1.15.0")
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
