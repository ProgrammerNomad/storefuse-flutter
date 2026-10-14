import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.storefuse.storefuse_app"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = providers.gradleProperty("storefuseApplicationId").orElse("com.storefuse.storefuse_app").get()
        manifestPlaceholders["storefuseScheme"] = providers.gradleProperty("storefuseScheme").orElse("storefuse").get()
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

flutter {
    source = "../.."
}

// Never silently ship an APK signed with the debug identity.
gradle.taskGraph.whenReady {
    val isRelease = allTasks.any { it.name.contains("Release", ignoreCase = true) }
    if (!isRelease) {
        return@whenReady
    }
    if (!keystorePropertiesFile.exists()) {
        throw GradleException("Release signing requires android/key.properties and your production keystore. See docs/release.md.")
    }
    val storeFilePath = keystoreProperties["storeFile"]?.toString()?.trim().orEmpty()
    if (storeFilePath.isEmpty() || !file(storeFilePath).exists()) {
        throw GradleException("Release signing: key.properties storeFile is missing or not found ($storeFilePath). See docs/release.md.")
    }
}
