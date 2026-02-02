allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

<<<<<<< HEAD
=======
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
