import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    plugins.withId("com.android.library") {
        if (name == "jni") {
            extensions.configure<LibraryExtension>("android") {
                defaultConfig {
                    externalNativeBuild {
                        cmake {
                            arguments += "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,--build-id=none"
                        }
                    }
                }
            }
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

gradle.projectsEvaluated {
    subprojects {
        tasks.configureEach {
            if (name.contains("lintVitalAnalyzeRelease") || name.contains("lintVitalRelease") || name.contains("lintVitalReportRelease")) {
                enabled = false
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
