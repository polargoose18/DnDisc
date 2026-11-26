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
// Plugins that pin an older compileSdk (file_picker 8 uses 34) fail the AAR
// metadata check against androidx libraries that need 36. Raise it for every
// plugin module; the app module takes the Flutter default.
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            val android = extensions.findByName("android")
            android?.javaClass?.methods
                ?.firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
                ?.invoke(android, 36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
