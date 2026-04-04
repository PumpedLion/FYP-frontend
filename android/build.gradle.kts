allprojects {
    repositories {
        google()
        mavenCentral()
    }
}


// The new layout.buildDirectory logic causes "this and base files have different roots"
// exceptions with older plugins like flutter_plugin_android_lifecycle and inappwebview on Windows.
// Commenting this out allows Gradle to use default project roots.
/*
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
*/

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
