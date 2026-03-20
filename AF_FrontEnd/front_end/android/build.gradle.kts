plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val relocatedBuildDir = project.layout.buildDirectory.dir("../../build").get()
project.layout.buildDirectory.value(relocatedBuildDir)

subprojects {
    val newSubprojectBuildDir = relocatedBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(project.layout.buildDirectory)
}
