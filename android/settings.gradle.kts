pluginManagement {
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

setBinding(groovy.lang.Binding(mapOf("gradle" to this)))
evaluate(File(
  settingsDir,
  "../.flutter-plugins-dependencies/managed/flutter_gradle_plugin/extract.gradle"
))
