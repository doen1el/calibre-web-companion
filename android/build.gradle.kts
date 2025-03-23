allprojects {
    repositories {
        google()
        mavenCentral()
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

ext.abiCodes = ["x86_64": 1, "armeabi-v7a": 2, "arm64-v8a": 3]
import com.android.build.OutputFile
android.applicationVariants.all { variant ->
  variant.outputs.each { output ->
    def abiVersionCode = project.ext.abiCodes.get(output.getFilter(OutputFile.ABI))
    if (abiVersionCode != null) {
      output.versionCodeOverride = variant.versionCode * 10 + abiVersionCode
    }
  }
}
