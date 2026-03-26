import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 1. CROSS-DRIVE FIX: Move build folder to F:/.../build
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 2. CIRCULAR REFERENCE FIX: Ensure subprojects depend on :app evaluation safely
subprojects {
    afterEvaluate {
        // Only apply this to plugins/modules, NOT the app itself
        if (project.hasProperty("android") && project.name != "app") {
            project.evaluationDependsOn(":app")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// 3. KOTLIN COMPILER FIX: Modern DSL for JvmTarget and Cross-Drive stability
subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
        // Disable incremental compilation to prevent C: to F: drive root errors
        compilerOptions.freeCompilerArgs.add("-Xno-incremental-compilation")
    }
}