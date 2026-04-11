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
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "homework_helper"
include(":app")
