// Some Flutter plugins pin their own Kotlin compiler. Align those buildscript
// dependencies too, so they can read Firebase's Kotlin 2.4 metadata.
subprojects {
    buildscript.configurations.configureEach {
        resolutionStrategy.force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.21")
    }
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
