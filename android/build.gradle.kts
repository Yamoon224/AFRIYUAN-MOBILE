allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

gradle.afterProject {
    extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
        compileSdk = 36
    }
    if (project.name == "stripe_android") {
        configurations.all {
            exclude(group = "com.stripe", module = "stripe-android-issuing-push-provisioning")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
