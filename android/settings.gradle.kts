pluginManagement {
    val flutterSdkPath = System.getProperty("flutter.sdk") ?: System.getenv("FLUTTER_ROOT")
    if (flutterSdkPath == null) {
        throw GradleException("Flutter SDK not found. Define flutter.sdk in local.properties or FLUTTER_ROOT environment variable.")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "homework_helper"
include(":app")
