// File: android/build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
// File: android/app/build.gradle.kts
plugins {
    id("com.google.gms.google-services") // tanpa version karena sudah auto injected
}


// Optional: custom build dir
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
