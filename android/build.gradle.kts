// 🔧 Ce bloc buildscript doit venir AVANT tout le reste
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Firebase services plugin (version actuelle à jour)
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()         // Pour Firebase
        mavenCentral()   // Pour d'autres dépendances
    }
}

// 🔁 Optionnel : changer le dossier de build
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// 🧹 Tâche clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
