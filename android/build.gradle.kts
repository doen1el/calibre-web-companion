allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy.dependencySubstitution {
            // NanoHttpd commit hash is no longer resolvable on JitPack; use Maven Central release.
            substitute(module("com.github.NanoHttpd.nanohttpd:nanohttpd"))
                .using(module("org.nanohttpd:nanohttpd:2.3.1"))
            substitute(module("com.github.NanoHttpd.nanohttpd:nanohttpd-nanolets"))
                .using(module("org.nanohttpd:nanohttpd-nanolets:2.3.1"))
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
