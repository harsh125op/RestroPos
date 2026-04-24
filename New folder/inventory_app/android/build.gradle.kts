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

subprojects {
    val configureNamespace = Action<Project> {
        if (hasProperty("android")) {
            val android = extensions.getByName("android")
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    setNamespace.invoke(android, "com.inventory_app.${name.replace("-", "_")}")
                }
            } catch (e: Exception) {
                // Ignore errors
            }
        }
    }

    if (state.executed) {
        configureNamespace.execute(this)
    } else {
        afterEvaluate { configureNamespace.execute(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
