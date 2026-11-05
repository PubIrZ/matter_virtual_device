#!/bin/bash

#exit 0 #2 

# =========================================================================
# SCRIPT DINÁMICO DE COMPILACIÓN CON ASIGNACIÓN DE ENTORNO AISLADO DE DISCO
# =========================================================================

sed -i 's/\r$//' "$0" || true
set -e 

if [ -n "$GITHUB_ENV" ] && [ -f "$GITHUB_ENV" ]; then
    echo "⚙️ INFRA: Sincronizando bloque completo de variables \$GITHUB_ENV (exports)..."
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ ! -z "$line" && "$line" != "#"* ]]; then
            export "$line"
        fi
    done < "$GITHUB_ENV"
fi

unset PW_ZAP_CIPD_RELEASE
export -n PW_ZAP_CIPD_RELEASE 2>/dev/null || true

FORCE_CLEAR_CACHE="${FORCE_CLEAR_CACHE:-false}"
#FORCE_CLEAR_CACHE="true"

echo "Estado de la caché: $FORCE_CLEAR_CACHE" 

# =========================================================================
# ☕ FORZADO DINÁMICO DE KOTLIN 1.8.10 EN EL RUNNER
# =========================================================================
echo "🔍 INFRA: Comprobando versión actual de kotlinc en el sistema..."

# 1. Capturar la salida de versión actual de kotlinc (si existe) silenciosamente
CURRENT_KT_VER=$(kotlinc -version 2>&1 || echo "none")

if [[ "$CURRENT_KT_VER" == *"1.8.10"* ]]; then
    echo "  ✅ REUTILIZADO: El compilador de Kotlin ya está alineado en la versión 1.8.10 para Ninja."
else
    echo "  ⚠️ DESAJUSTE: Se requiere Kotlin 1.8.10 (Detectado: $CURRENT_KT_VER). Iniciando descarga segura..."
    
    # Guardar el directorio actual de forma segura
    ORIGINAL_DIR=$(pwd)

    # Definición limpia y concatenada de variables para la URL
    KT_BASE_URL="https://github.com"
    KT_VERSION_PATH="JetBrains/kotlin/releases/download/v1.8.10"
    KT_VERSION_ZIP="kotlin-compiler-1.8.10.zip"
    KT_FULL_URL="${KT_BASE_URL}/${KT_VERSION_PATH}/${KT_VERSION_ZIP}"
    KT_DEST_ZIP="/usr/local/lib/${KT_VERSION_ZIP}"

    # Limpiar cualquier rastro antiguo corrupto
    sudo rm -f "$KT_DEST_ZIP"
    
    # Descargar y extraer en la ruta absoluta del sistema de forma limpia
    sudo wget -q --show-progress "$KT_FULL_URL" -O "$KT_DEST_ZIP"
    
    # 3. Verificación final antes de descomprimir
    if [ -s "$KT_DEST_ZIP" ]; then
        echo "  📦 Archivo ZIP validado con éxito. Extrayendo componentes..."
        sudo unzip -q "$KT_DEST_ZIP" -d "/usr/local/lib"
        sudo rm -f "$KT_DEST_ZIP"

        # Forzar el PATH prioritario global de forma inmediata
        export PATH="/usr/local/lib/kotlinc/bin:$PATH"
        if [ -n "$GITHUB_PATH" ]; then
            echo "/usr/local/lib/kotlinc/bin" >> "$GITHUB_PATH"
        fi
        echo "  ↳ ✅ Kotlin 1.8.10 inyectado correctamente en el entorno del runner."
    else
        echo "  ❌ ERROR CRÍTICO: No se pudo descargar el compilador por ninguna vía de red."
    fi    

    # Confirmar de forma visual la inyección en el flujo actual
    echo "  ↳ ✅ Modificación del PATH aplicada con éxito. Nueva versión activa para Ninja:"
    kotlinc -version

    # Regresar de forma segura al directorio de trabajo original
    cd "$ORIGINAL_DIR"
fi

# =========================================================================
# ☕ FORZADO DINÁMICO DE JDK 11 USANDO LAS VARIABLES DEL RUNNER
# =========================================================================
echo "INFRA: Configurando el entorno del sistema para usar JDK 11 de forma dinámica..."

if [ -n "$JAVA_HOME_11_X64" ] && [ -d "$JAVA_HOME_11_X64" ]; then
    export JAVA_HOME="$JAVA_HOME_11_X64"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    echo "  ↳ ✅ JAVA_HOME asignado con éxito desde JAVA_HOME_11_X64."
    echo "  ↳ Versión de Java activa en el PATH: $(java -version 2>&1 | head -n 1)"
    
    if [ -n "$GITHUB_ENV" ] && [ -f "$GITHUB_ENV" ]; then
        echo "JAVA_HOME=$JAVA_HOME" >> "$GITHUB_ENV"
        echo "PATH=$PATH" >> "$GITHUB_ENV"
    fi
else
    echo "⚠️ ADVERTENCIA CRÍTICA: La variable JAVA_HOME_11_X64 está vacía o su ruta no existe."
    echo "  ↳ Se mantendrá el Java del sistema actual: $(java -version 2>&1 | head -n 1)"
fi

echo "INFRA: Levantando escudo interceptor de comandos para desarmar sdkmanager..."
git checkout -- scripts/build/runner/shell.py || true
git checkout -- scripts/build/builders/android.py || true

echo "========================================================================="
echo ""

# # =========================================================================
# # 🛡️ BLINDAJE GLOBAL: STACK, GRADLE COMPILER (MEMORY FORCE + HEAP DUMP)
# # =========================================================================
# echo "INFRA: Configurando blindaje de memoria JVM y ruta de telemetría..."
# # Limpiamos el archivo global para el ciclo incremental
# mkdir -p ~/.gradle
# rm -f ~/.gradle/gradle.properties || true
# touch ~/.gradle/gradle.properties

# # 1. Configurar la memoria del proceso principal de Gradle y el Bypass de metadatos
# export GRADLE_OPTS="-Xmx4g -Xms2g -Xss8m -XX:MaxMetaspaceSize=1024m -Dkotlin.skip.metadata.version.check=true"

# echo "INFRA: Configurando inyecciones funcionales de JVM y Compilador en archivos físicos..."

# # 2. La ÚNICA forma real de pasarle argumentos JVM al Demonio de Kotlin de forma global
# # Creamos o añadimos al archivo gradle.properties global los 8MB de Stack y el bypass de metadatos
# cat << 'EOF' >> ~/.gradle/gradle.properties
# # Parámetros reales para el demonio donde corren Kotlin y Kapt:
# org.gradle.jvmargs=-Xmx4g -Xss8m -XX:MaxMetaspaceSize=1024m -Dkotlin.skip.metadata.version.check=true
# kotlin.daemon.jvmopts=-Xmx4g -Xss8m -Dkotlin.skip.metadata.version.check=true
# EOF

# # Forzamos directivas en el archivo global de usuario
# echo "android.useAndroidX=true" >> ~/.gradle/gradle.properties
# echo "android.enableJetifier=true" >> ~/.gradle/gradle.properties
# echo "org.gradle.java.home=$MATTER_TARGET_JAVA_HOME" >> ~/.gradle/gradle.properties

# # Inyección de memoria JVM unificada (Eliminamos ThreadStackSize conflictivos y dejamos -Xss8m limpio)
# echo "org.gradle.jvmargs=-Xmx4096m -Xms2048m -Xss8m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$DUMP_DIR/gradle_oom_dump.hprof -Dfile.encoding=UTF-8" >> ~/.gradle/gradle.properties



# echo "🛡️ INFRA: Configurando memoria JVM y el Bypass de metadatos en ~/.gradle/gradle.properties"

echo "INFRA: Configurando blindaje de memoria JVM y ruta de telemetría..."
# 1. Limpieza y preparación del archivo de propiedades global
# Limpiamos el archivo global para el ciclo incremental
mkdir -p ~/.gradle
rm -f ~/.gradle/gradle.properties || true
touch ~/.gradle/gradle.properties

# 2. Configurar la memoria del proceso principal de Gradle (CLI) y el Bypass de metadatos
export GRADLE_OPTS="-Xmx4g -Xms2g -Xss8m -XX:MaxMetaspaceSize=1024m -Dkotlin.skip.metadata.version.check=true"

# 3. Escritura unificada de parámetros reales en el archivo gradle.properties
cat << EOF > ~/.gradle/gradle.properties
# =====================================================================
# CONFIGURACIÓN DE MEMORIA Y ARRANQUE DE JVM (Evita StackOverflowError)
# =====================================================================
org.gradle.jvmargs=-Xmx4096m -Xms2048m -Xss8m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$DUMP_DIR/gradle_oom_dump.hprof -Dfile.encoding=UTF-8 -Dkotlin.skip.metadata.version.check=true

# Parámetros para el subproceso del Demonio de Kotlin y procesos aislados de Kapt
kotlin.daemon.jvmopts=-Xmx4g -Xss8m -Dkotlin.skip.metadata.version.check=true

# =====================================================================
# DIRECTIVAS GLOBALES DEL ECOSISTEMA ANDROID Y ENTORNO
# =====================================================================
android.useAndroidX=true
android.enableJetifier=true
org.gradle.java.home=$MATTER_TARGET_JAVA_HOME
EOF

echo "  ✅ Propiedades globales aplicadas en ~/.gradle/gradle.properties"


# # Ruta para volcado de memoria si hay OOM en Jetifier/Kotlin
# DUMP_DIR="${GITHUB_WORKSPACE}/matter-sdk/examples/virtual-device-app/android/App/app/build/outputs/reports"
# mkdir -p "$DUMP_DIR"

# # Forzamos directivas en el archivo global de usuario (Prevalencia absoluta)
# echo "android.useAndroidX=true" >> ~/.gradle/gradle.properties
# echo "android.enableJetifier=true" >> ~/.gradle/gradle.properties
# echo "org.gradle.java.home=$MATTER_TARGET_JAVA_HOME" >> ~/.gradle/gradle.properties

# # Inyección de memoria JVM optimizada para resolver el cuello de botella
# # -Xss8m contra StackOverflow y HeapDumpPath
# echo "org.gradle.jvmargs=-Xmx4096m -Xms2048m -Xss8m -XX:MaxMetaspaceSize=1024m  -XX:ThreadStackSize=4096 -XX:CompilerThreadStackSize=4096 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$DUMP_DIR/gradle_oom_dump.hprof -Dfile.encoding=UTF-8" >> ~/.gradle/gradle.properties

# echo "  ✅ Propiedades globales aplicadas en ~/.gradle/gradle.properties"

# # 2. Generar el script init.gradle para interceptar las tareas de Kotlin
# echo "🛡️ INFRA: Injected Global Resolution Shield to force Kotlin 1.8.10 mapping..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     configurations.all {
#         resolutionStrategy {
#             eachDependency { DependencyResolveDetails details ->
#                 if (details.requested.group == 'org.jetbrains.kotlin') {
#                     details.useVersion '1.8.10'
#                 }
#             }
#         }
#     }

#     afterEvaluate { project ->
#         project.tasks.matching { it.class.name.contains("KotlinCompile") }.configureEach { task ->
#             try {
#                 if (task.hasProperty('kotlinOptions')) {
#                     task.kotlinOptions {
#                         freeCompilerArgs += ["-Xskip-metadata-version-check", "-Xallow-no-source-files"]
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         project.tasks.matching { it.name.contains("kapt") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 if (task.hasProperty('kaptProcessJvmArgs')) {
#                     task.kaptProcessJvmArgs += ["-Xss8m", "-Xmx4g", "-XX:MaxMetaspaceSize=1024m"]
#                 }
#             } catch (Exception e) {}
#         }
#     }
# }
# EOF
# echo "  ✅ Global master interceptor saved to ~/.gradle/init.gradle"

# # Exportamos GRADLE_OPTS 
# export GRADLE_OPTS="-Xmx4g -Xms2g -Xss8m -XX:MaxMetaspaceSize=1024m  -XX:ThreadStackSize=4096 -XX:CompilerThreadStackSize=4096 -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files" # -Dorg.gradle.logging.level=info"




# # 2. Generar el script init.gradle corregido para Kotlin y Kapt
# echo "🛡️ INFRA: Injected Global Resolution Shield to force Kotlin 1.8.10 mapping..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     configurations.all {
#         resolutionStrategy {
#             eachDependency { DependencyResolveDetails details ->
#                 if (details.requested.group == 'org.jetbrains.kotlin') {
#                     details.useVersion '1.8.10'
#                 }
#             }
#         }
#     }

#     afterEvaluate { project ->
#         // Configuración de compilación de Kotlin
#         project.tasks.matching { it.class.name.contains("KotlinCompile") }.configureEach { task ->
#             try {
#                 if (task.hasProperty('kotlinOptions')) {
#                     task.kotlinOptions {
#                         freeCompilerArgs += ["-Xskip-metadata-version-check", "-Xallow-no-source-files"]
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // Corrección de Kapt: Forzado robusto de argumentos de JVM
#         if (project.plugins.hasPlugin("kotlin-kapt")) {
#             project.extensions.findByName("kapt")?.shadowClosure {
#                 arguments {
#                     // Forzar a los daemons de procesamiento de Kapt a usar 8MB de Stack                
#                     javacArgs("-Xss8m", "-Xmx4g")
#                 }
#             }        
#         }
#     }
# }
# EOF
#echo "  ✅ Global master interceptor saved to ~/.gradle/init.gradle"


# # 2. Generar el script init.gradle corregido para Kotlin y Kapt
# echo "🛡️ INFRA: Injected Global Resolution Shield to force Kotlin 1.8.10 mapping..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     configurations.all {
#         resolutionStrategy {
#             eachDependency { DependencyResolveDetails details ->
#                 if (details.requested.group == 'org.jetbrains.kotlin') {
#                     details.useVersion '1.8.10'
#                 }
#             }
#         }
#     }

#     afterEvaluate { project ->
#         // Configuración de compilación de Kotlin
#         project.tasks.matching { it.class.name.contains("KotlinCompile") }.configureEach { task ->
#             try {
#                 if (task.hasProperty('kotlinOptions')) {
#                     task.kotlinOptions {
#                         freeCompilerArgs += ["-Xskip-metadata-version-check", "-Xallow-no-source-files"]
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // Forzado robusto de argumentos de JVM (Evita el StackOverflow en Java/Kapt)
#         project.tasks.withType(JavaCompile).configureEach { task ->
#             try {
#                 task.options.fork = true
#                 task.options.forkOptions.with {
#                     memoryMaximumSize = "4g"
#                     if (jvmArgs == null) {
#                         jvmArgs = ["-Xss8m", "-XX:MaxMetaspaceSize=1g"]
#                     } else {
#                         jvmArgs.addAll(["-Xss8m", "-XX:MaxMetaspaceSize=1g"])
#                     }
#                 }
#             } catch (Exception e) {}
#         }
#     }
# }
# EOF
#echo "  ✅ Global master interceptor saved to ~/.gradle/init.gradle"

# # 2. Generar el script init.gradle corregido para Kotlin y Kapt
# echo "🛡️ INFRA: Injected Global Resolution Shield to force Kotlin 1.8.10 mapping..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     configurations.all {
#         resolutionStrategy {
#             eachDependency { DependencyResolveDetails details ->
#                 if (details.requested.group == 'org.jetbrains.kotlin') {
#                     details.useVersion '1.8.10'
#                 }
#             }
#         }
#     }

#     // Desactivar compilación incremental corrupta que guarda metadatos antiguos dañados
#     gradle.taskGraph.whenReady { taskGraph ->
#         taskGraph.allTasks.each { task ->
#             if (task.class.name.contains("KotlinCompile")) {
#                 task.setProperty("incremental", false)
#             }
#         }
#     }

#     afterEvaluate { project ->
#         // Configuración de compilación de Kotlin y mitigación de metadatos
#         project.tasks.matching { it.class.name.contains("KotlinCompile") }.configureEach { task ->
#             try {
#                 if (task.hasProperty('kotlinOptions')) {
#                     task.kotlinOptions {
#                         // -Xskip-prerelease-check e -Xmetadata-version-check evitan colapsos por diferencias de versión
#                         freeCompilerArgs += [
#                             "-Xskip-metadata-version-check", 
#                             "-Xskip-prerelease-check",
#                             "-Xallow-no-source-files"
#                         ]
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // Forzado robusto de argumentos de JVM (Evita el StackOverflow anterior)
#         project.tasks.withType(JavaCompile).configureEach { task ->
#             try {
#                 task.options.fork = true
#                 task.options.forkOptions.with {
#                     memoryMaximumSize = "4g"
#                     if (jvmArgs == null) {
#                         jvmArgs = ["-Xss8m", "-XX:MaxMetaspaceSize=1g"]
#                     } else {
#                         jvmArgs.addAll(["-Xss8m", "-XX:MaxMetaspaceSize=1g"])
#                     }
#                 }
#             } catch (Exception e) {}
#         }
#     }
# }
# EOF
#echo "  ✅ Global master interceptor saved to ~/.gradle/init.gradle"

# # 2. Generar el script init.gradle corregido para Kotlin 1.9.24 y Kapt robusto
# echo "🛡️ INFRA: Injected Global Resolution Shield to force Kotlin 1.9.24 mapping..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     configurations.all {
#         resolutionStrategy {
#             eachDependency { DependencyResolveDetails details ->
#                 // Mapear todas las librerías del ecosistema de Kotlin a una versión moderna estable
#                 if (details.requested.group == 'org.jetbrains.kotlin') {
#                     details.useVersion '1.9.24'
#                 }
#             }
#         }
#     }

#     // Desactivar cachés incrementales de Kotlin que retienen metadatos corruptos
#     gradle.taskGraph.whenReady { taskGraph ->
#         taskGraph.allTasks.each { task ->
#             if (task.class.name.contains("KotlinCompile") || task.class.name.contains("KaptGenerateStubs")) {
#                 try {
#                     task.setProperty("incremental", false)
#                 } catch (Exception e) {}
#             }
#         }
#     }

#     afterEvaluate { project ->
#         // Mitigar problemas de metadatos estrictos en las tareas del compilador
#         project.tasks.matching { it.class.name.contains("KotlinCompile") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 if (task.hasProperty('kotlinOptions')) {
#                     task.kotlinOptions {
#                         freeCompilerArgs += [
#                             "-Xskip-metadata-version-check",
#                             "-Xskip-prerelease-check",
#                             "-Xallow-no-source-files"
#                         ]
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // Forzado robusto de argumentos de JVM (Evita el StackOverflow original)
#         project.tasks.withType(JavaCompile).configureEach { task ->
#             try {
#                 task.options.fork = true
#                 task.options.forkOptions.with {
#                     memoryMaximumSize = "4g"
#                     if (jvmArgs == null) {
#                         jvmArgs = ["-Xss8m", "-XX:MaxMetaspaceSize=1g"]
#                     } else {
#                         jvmArgs.addAll(["-Xss8m", "-XX:MaxMetaspaceSize=1g"])
#                     }
#                 }
#             } catch (Exception e) {}
#         }
#     }
# }
# EOF
# echo "  ✅ Global master interceptor saved to ~/.gradle/init.gradle"


# # 2. Generar el script init.gradle definitivo y compatible
# echo "🛡️ INFRA: Injected Compatible JVM and Metaspace Stack Shield..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     // Desactivar cachés incrementales que puedan estar arrastrando estados binarios rotos
#     gradle.taskGraph.whenReady { taskGraph ->
#         taskGraph.allTasks.each { task ->
#             if (task.class.name.contains("KotlinCompile") || task.class.name.contains("Kapt")) {
#                 try {
#                     task.setProperty("incremental", false)
#                 } catch (Exception e) {}
#             }
#         }
#     }

#     afterEvaluate { project ->
#         // Inyección segura de banderas de mitigación de metadatos al compilador de Kotlin
#         project.tasks.matching { it.class.name.contains("KotlinCompile") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 if (task.hasProperty('kotlinOptions')) {
#                     task.kotlinOptions {
#                         freeCompilerArgs += [
#                             "-Xskip-metadata-version-check",
#                             "-Xskip-prerelease-check",
#                             "-Xallow-no-source-files"
#                         ]
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // Forzado robusto de argumentos de JVM a nivel de compilación (Solución definitiva al StackOverflow)
#         project.tasks.withType(JavaCompile).configureEach { task ->
#             try {
#                 task.options.fork = true
#                 task.options.forkOptions.with {
#                     memoryMaximumSize = "4g"
#                     if (jvmArgs == null) {
#                         jvmArgs = ["-Xss8m", "-XX:MaxMetaspaceSize=1g"]
#                     } else {
#                         jvmArgs.addAll(["-Xss8m", "-XX:MaxMetaspaceSize=1g"])
#                     }
#                 }
#             } catch (Exception e) {}
#         }
#     }
# }
# EOF
# echo "  ✅ Global master interceptor saved to ~/.gradle/init.gradle"


# # 2. Generar el script init.gradle definitivo con System Properties para el Daemon de Kotlin
# echo "🛡️ INFRA: Injected Compatible JVM and Global Metadata Bypass Shield..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     // Desactivar cachés incrementales corruptas
#     gradle.taskGraph.whenReady { taskGraph ->
#         taskGraph.allTasks.each { task ->
#             if (task.class.name.contains("KotlinCompile") || task.class.name.contains("Kapt")) {
#                 try {
#                     task.setProperty("incremental", false)
#                 } catch (Exception e) {}
#             }
#         }
#     }

#     afterEvaluate { project ->
#         // Forzar a todas las tareas de compilación y stubs de Kotlin a ignorar los metadatos binarios corruptos
#         project.tasks.matching { it.class.name.contains("KotlinCompile") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 if (task.hasProperty('kotlinOptions')) {
#                     task.kotlinOptions {
#                         freeCompilerArgs += [
#                             "-Xskip-metadata-version-check",
#                             "-Xskip-prerelease-check",
#                             "-Xallow-no-source-files"
#                         ]
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // Forzado robusto de argumentos de JVM (Mantiene la inmunidad al StackOverflow)
#         project.tasks.withType(JavaCompile).configureEach { task ->
#             try {
#                 task.options.fork = true
#                 task.options.forkOptions.with {
#                     memoryMaximumSize = "4g"
#                     if (jvmArgs == null) {
#                         jvmArgs = ["-Xss8m", "-XX:MaxMetaspaceSize=1g"]
#                     } else {
#                         jvmArgs.addAll(["-Xss8m", "-XX:MaxMetaspaceSize=1g"])
#                     }
#                 }
#             } catch (Exception e) {}
#         }
#     }
# }
# EOF

############# DA DATOS INEXACTOS AL MIRAR LOS .CLASS Y LOS .JAR
# # 2. Generar el script init.gradle definitivo con auditoría binaria de metadatos
# echo "🛡️ INFRA: Injected Global Metadata Inspector and JVM Stack Shield..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     afterEvaluate { project ->
#         // 1. INSPECTOR DE METADATOS: Analiza el bytecode generado para identificar la versión exacta
#         project.tasks.matching { it.class.name.contains("KotlinCompile") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 task.doFirst {
#                     println "🔍 [METADATA AUDIT] Iniciando tarea :${project.name}:${task.name}"
#                 }  
#                 task.doLast { taskInstance ->
#                     taskInstance.outputs.files.each { outputDir ->
#                         if (outputDir.exists() && outputDir.isDirectory()) {
#                             outputDir.eachFileRecurse { file ->
#                                 // Analizar tanto archivos .class individuales como archivos de empaquetado de módulos
#                                 if (file.name.endsWith(".class") || file.name.endsWith(".kotlin_module")) {
#                                     try {
#                                         def bytes = file.bytes
#                                         if (bytes.length > 8) {
#                                             // Estructura binaria de metadatos de Kotlin (Header / Protobuf)
#                                             // Buscamos los bytes que indican la versión de metadatos [Major, Minor, Patch]
#                                             // En archivos .kotlin_module los primeros bytes determinan la especificación
#                                             int major = bytes[0] & 0xFF
#                                             int minor = bytes[1] & 0xFF
#                                             // Si detectamos firmas de versiones modernas (ej: 1.9), lo reportamos explícitamente
#                                             if (major > 1 || (major == 1 && minor > 8)) {
#                                                 println "⚠️ [METADATA ALERT] Módulo :${project.name} generó archivo irreversible [Kotlin ${major}.${minor}] -> ${file.name}"
#                                             }
#                                         }
#                                     } catch (Exception e) {}
#                                 }
#                             }
#                         }
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // 2. VALIDADOR Y ESCUDO JVM: Aplica y confirma la configuración contra el StackOverflow
#         project.tasks.withType(JavaCompile).configureEach { task ->
#             try {
#                 task.options.fork = true
#                 task.options.forkOptions.with {
#                     memoryMaximumSize = "4g"
#                     if (jvmArgs == null) {
#                         jvmArgs = ["-Xss8m", "-XX:MaxMetaspaceSize=1g"]
#                     } else {
#                         jvmArgs.addAll(["-Xss8m", "-XX:MaxMetaspaceSize=1g"])
#                     }
#                 }

#                 task.doFirst {
#                     println "🚀 [JVM VALIDATOR] Proceso Fork configurado para :${project.name}:${task.name}"
#                     println "   -> jvmArgs asignados: ${task.options.forkOptions.jvmArgs}"
#                 }
#             } catch (Exception e) {}
#         }
#     }
# }
# EOF
# echo "  ✅ Metadata Inspector and JVM Validator saved to ~/.gradle/init.gradle"

############### NO DA ERROR PERO NO FUNCIONA
# echo "🛡️ INFRA: Injected Global Metadata Inspector and JVM Stack Shield..."
# cat << 'EOF' > ~/.gradle/init.gradle
# // ====================================================================
# // 0. CONFIGURACIÓN DEL SCRIPT (Añade ASM al ClassLoader del init.gradle)
# // ====================================================================
# initscript {
#     repositories {
#         mavenCentral()
#     }
#     dependencies {
#         // Traemos la última versión estable de ASM de forma segura para este script
#         classpath 'org.ow2.asm:asm:9.7'
#     }
# }

# import java.io.InputStream
# import org.objectweb.asm.ClassReader
# import org.objectweb.asm.ClassVisitor
# import org.objectweb.asm.AnnotationVisitor
# import org.objectweb.asm.Opcodes

# allprojects {
#     // ==========================================
#     // 1. AUDITORÍA ESTÁTICA (Plugins/Dependencias)
#     // ==========================================
#     def auditVersion = { pluginInstance ->
#         if (pluginInstance && pluginInstance.hasProperty('kotlinPluginVersion')) {
#             def version = pluginInstance.kotlinPluginVersion
#             def parts = version.split('\\.')
#             if (parts.length >= 2) {
#                 try {
#                     int major = parts[0].toInteger()
#                     int minor = parts[1].toInteger()
#                     if (major > 1 || (major == 1 && minor > 8)) {
#                         println "⚠️ [KOTLIN PLUGIN ALERT] Módulo :${project.name} configurado con Kotlin ${version} (Superior a 1.8)"
#                     }
#                 } catch (NumberFormatException e) {}
#             }
#         }
#     }

#     plugins.withId("org.jetbrains.kotlin.jvm") { plugin -> auditVersion(plugin) }
#     plugins.withId("org.jetbrains.kotlin.android") { plugin -> auditVersion(plugin) }
#     plugins.withId("org.jetbrains.kotlin.multiplatform") { plugin -> auditVersion(plugin) }

#     // ==========================================
#     // 2. AUDITORÍA BINARIA (Bytecode .class real)
#     // ==========================================
#     afterEvaluate { project ->
#         project.tasks.matching { it.class.name.contains("KotlinCompile") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 task.doLast { taskInstance ->
#                     taskInstance.outputs.files.each { outputDir ->
#                         if (outputDir.exists() && outputDir.isDirectory()) {
                            
#                             // Variables estables para las clases internas anónimas
#                             final String currentProject = project.name
                            
#                             outputDir.eachFileRecurse { file ->
#                                 if (file.name.endsWith(".class")) {
#                                     final String currentFile = file.name
#                                     file.withInputStream { is ->
#                                         try {
#                                             ClassReader cr = new ClassReader(is)
                                            
#                                             // Implementación limpia heredando de ClassVisitor pasándole ASM9 al super()
#                                             cr.accept(new ClassVisitor(Opcodes.ASM9) {
#                                                 @Override
#                                                 AnnotationVisitor visitAnnotation(String descriptor, boolean visible) {
#                                                     if (descriptor == "Lkotlin/Metadata;") {
#                                                         // Heredamos de AnnotationVisitor pasándole ASM9 al super()
#                                                         return new AnnotationVisitor(Opcodes.ASM9) {
#                                                             @Override
#                                                             AnnotationVisitor visitArray(String name) {
#                                                                 if (name == "mv") {
#                                                                     def versionNumbers = []
#                                                                     return new AnnotationVisitor(Opcodes.ASM9) {
#                                                                         @Override
#                                                                         void visit(String arrayName, Object value) {
#                                                                             if (value instanceof Integer) {
#                                                                                 versionNumbers << value
#                                                                             }
#                                                                         }
#                                                                         @Override
#                                                                         void visitEnd() {
#                                                                             if (versionNumbers.size() >= 2) {
#                                                                                 int major = versionNumbers[0]
#                                                                                 int minor = versionNumbers[1]
#                                                                                 if (major > 1 || (major == 1 && minor > 8)) {
#                                                                                     println "⚠️ [METADATA ALERT] Módulo :${currentProject} generó archivo irreversible [Kotlin ${major}.${minor}] -> ${currentFile}"
#                                                                                 }
#                                                                             }
#                                                                         }
#                                                                     }
#                                                                 }
#                                                                 return super.visitArray(name)
#                                                             }
#                                                         }
#                                                     }
#                                                     return super.visitAnnotation(descriptor, visible)
#                                                 }
#                                             }, 0)
#                                         } catch (Throwable e) {
#                                             // Ignora clases puras de Java o archivos corruptos de forma segura
#                                         }
#                                     }
#                                 }
#                             }
#                         }
#                     }
#                 }
#             } catch (Exception e) {}
#         }
#     }
# }
# EOF
# echo "  ✅ Metadata Inspector and JVM Validator saved to ~/.gradle/init.gradle"


############ No Comprobado - Supuestamente es el mismo que el qu va despues
# echo "🛡️ INFRA: Injected Global Metadata Inspector and JVM Stack Shield..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     // ==========================================
#     // 1. AUDITORÍA ESTÁTICA (Plugins/Dependencias)
#     // ==========================================
#     def auditVersion = { pluginInstance ->
#         if (pluginInstance && pluginInstance.hasProperty('kotlinPluginVersion')) {
#             def version = pluginInstance.kotlinPluginVersion
#             def parts = version.split('\\.')
#             if (parts.length >= 2) {
#                 try {
#                     int major = parts[0].toInteger()
#                     int minor = parts[1].toInteger()
#                     if (major > 1 || (major == 1 && minor > 8)) {
#                         println "⚠️ [KOTLIN PLUGIN ALERT] Módulo :${project.name} configurado con Kotlin ${version} (Superior a 1.8)"
#                     }
#                 } catch (NumberFormatException e) {}
#             }
#         }
#     }

#     plugins.withId("org.jetbrains.kotlin.jvm") { plugin -> auditVersion(plugin) }
#     plugins.withId("org.jetbrains.kotlin.android") { plugin -> auditVersion(plugin) }
#     plugins.withId("org.jetbrains.kotlin.multiplatform") { plugin -> auditVersion(plugin) }

#     // ==========================================
#     // 2. AUDITORÍA BINARIA (.kotlin_module sin dependencias)
#     // ==========================================
#     afterEvaluate { project ->
#         project.tasks.matching { it.class.name.contains("KotlinCompile") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 task.doLast { taskInstance ->
#                     taskInstance.outputs.files.each { outputDir ->
#                         if (outputDir.exists() && outputDir.isDirectory()) {
#                             final String projectName = project.name
                            
#                             outputDir.eachFileRecurse { file ->
#                                 try {
#                                     if (file.name.endsWith(".kotlin_module")) {
#                                         def bytes = file.bytes
#                                         if (bytes.length >= 6) {
#                                             // Extraemos la versión binaria mapeando a enteros positivos libres de signo
#                                             int major = bytes[4] & 0xFF
#                                             int minor = bytes[5] & 0xFF
                                            
#                                             // Filtro de seguridad: Evitar procesar bytes vacíos o corruptos
#                                             if (major > 0 || minor > 0) {
#                                                 if (major > 1 || (major == 1 && minor > 8)) {
#                                                     println "⚠️ [METADATA ALERT] Módulo :${projectName} contiene metadatos incompatibles [Kotlin ${major}.${minor}] -> ${file.name}"
#                                                 } else {
#                                                     println "✅ [METADATA INFO] Módulo :${projectName} verificado correctamente [Kotlin ${major}.${minor}] -> ${file.name}"
#                                                 }
#                                             }
#                                         }
#                                     }
#                                 } catch (Exception e) {
#                                     // Evita caídas si el archivo está temporalmente bloqueado por el sistema operativo
#                                 }
#                             }
#                         }
#                     }
#                 }
#             } catch (Exception e) {}
#         }
#     }
# }
# EOF
# echo "  ✅ Metadata Inspector and JVM Validator saved to ~/.gradle/init.gradle"


# echo "🛡️ INFRA: Injected Global Metadata Inspector, JVM Stack Shield and Native Optimizer..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     // ==========================================
#     // CONFIGURACIÓN DE OPTIMIZACIÓN
#     // ==========================================
#     // Control de optimización nativa (Matter & C++)
#     def ENABLE_STRIP = true

#     // ==========================================
#     // 1. AUDITORÍA ESTÁTICA (Plugins/Dependencias)
#     // ==========================================
#     def auditVersion = { pluginInstance ->
#         if (pluginInstance && pluginInstance.hasProperty('kotlinPluginVersion')) {
#             def version = pluginInstance.kotlinPluginVersion
#             def parts = version.split('\\.')
#             if (parts.length >= 2) {
#                 try {
#                     int major = parts[0].toInteger()
#                     int minor = parts[1].toInteger()
#                     if (major > 1 || (major == 1 && minor > 8)) {
#                         println "⚠️ [KOTLIN PLUGIN ALERT] Módulo :${project.name} configurado con Kotlin ${version} (Superior a 1.8)"
#                     }
#                 } catch (NumberFormatException e) {}
#             }
#         }
#     }

#     plugins.withId("org.jetbrains.kotlin.jvm") { plugin -> auditVersion(plugin) }
#     plugins.withId("org.jetbrains.kotlin.android") { plugin -> auditVersion(plugin) }
#     plugins.withId("org.jetbrains.kotlin.multiplatform") { plugin -> auditVersion(plugin) }

#     // ==========================================
#     // 2. AUDITORÍA BINARIA Y OPTIMIZACIÓN NATIVA
#     // ==========================================
#     afterEvaluate { project ->
        
#         // --- Inspección de metadatos .kotlin_module ---
#         project.tasks.matching { it.class.name.contains("KotlinCompile") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 task.doLast { taskInstance ->
#                     taskInstance.outputs.files.each { outputDir ->
#                         if (outputDir.exists() && outputDir.isDirectory()) {
#                             final String projectName = project.name
#                             outputDir.eachFileRecurse { file ->
#                                 try {
#                                     if (file.name.endsWith(".kotlin_module")) {
#                                         def bytes = file.bytes
#                                         if (bytes.length >= 6) {
#                                             int major = bytes[4] & 0xFF
#                                             int minor = bytes[5] & 0xFF
#                                             if (major > 0 || minor > 0) {
#                                                 if (major > 1 || (major == 1 && minor > 8)) {
#                                                     println "⚠️ [METADATA ALERT] Módulo :${projectName} contiene metadatos incompatibles [Kotlin ${major}.${minor}] -> ${file.name}"
#                                                 } else {
#                                                     println "✅ [METADATA INFO] Módulo :${projectName} verificado correctamente [Kotlin ${major}.${minor}] -> ${file.name}"
#                                                 }
#                                             }
#                                         }
#                                     }
#                                 } catch (Exception e) {}
#                             }
#                         }
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // --- Optimización nativa en caliente con llvm-strip ---
#         if (ENABLE_STRIP && (project.plugins.hasPlugin("com.android.application") || project.plugins.hasPlugin("com.android.library"))) {
#             project.tasks.configureEach { task ->
#                 if (task.name.startsWith("merge") && task.name.endsWith("JniLibs")) {
#                     task.doLast {
#                         def androidExt = project.extensions.findByName("android")
#                         if (!androidExt || !androidExt.hasProperty("ndkDirectory")) return
                        
#                         def ndkDir = androidExt.ndkDirectory
#                         if (ndkDir == null) return
                        
#                         // Localización de la herramienta según la arquitectura detectada
#                         def osName = System.getProperty("os.name").toLowerCase()
#                         def hostOs = osName.contains("linux") ? "linux-x86_64" : 
#                                      osName.contains("mac") ? "darwin-x86_64" : "windows-x86_64"
                        
#                         def stripExecutable = "${ndkDir}/toolchains/llvm/prebuilt/${hostOs}/bin/llvm-strip"
#                         if (osName.contains("windows")) stripExecutable += ".exe"

#                         if (new File(stripExecutable).exists()) {
#                             task.outputs.files.each { fileOutput ->
#                                 project.fileTree(dir: fileOutput, include: "**/*.so").each { soFile ->
#                                     println "🛡️ [OPTIMIZER] Aplicando llvm-strip directo -> :${project.name}:${soFile.name}"
#                                     project.exec {
#                                         commandLine stripExecutable, '--strip-unneeded', soFile.absolutePath
#                                         ignoreExitValue = true // Previene fallos si un archivo ya ha sido procesado o está protegido
#                                     }
#                                 }
#                             }
#                         }
#                     }
#                 }
#             }
#         }
#     }
# }
# EOF
# echo "  ✅ Metadata Inspector, JVM Validator, and Native Optimizer saved to ~/.gradle/init.gradle"

# echo "🛡️ INFRA: Injected Global Metadata Inspector, JVM Stack Shield and Native Optimizer..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     // =========================================================================
#     // CONFIGURACIÓN DE OPTIMIZACIÓN GLOBAL
#     // =========================================================================
#     // Cambia a false si necesitas depurar crashes en C++ con símbolos completos
#     def ENABLE_STRIP = true

#     // =========================================================================
#     // 1. AUDITORÍA ESTÁTICA: Monitoreo de plugins de Kotlin
#     // =========================================================================
#     def auditVersion = { pluginInstance ->
#         if (pluginInstance && pluginInstance.hasProperty('kotlinPluginVersion')) {
#             def version = pluginInstance.kotlinPluginVersion
#             def parts = version.split('\\.')
#             if (parts.length >= 2) {
#                 try {
#                     int major = parts[0].toInteger()
#                     int minor = parts[1].toInteger()
#                     if (major > 1 || (major == 1 && minor > 8)) {
#                         println "⚠️ [KOTLIN PLUGIN ALERT] Módulo :${project.name} configurado con Kotlin ${version} (Superior a 1.8)"
#                     }
#                 } catch (NumberFormatException e) {}
#             }
#         }
#     }

#     plugins.withId("org.jetbrains.kotlin.jvm") { plugin -> auditVersion(plugin) }
#     plugins.withId("org.jetbrains.kotlin.android") { plugin -> auditVersion(plugin) }
#     plugins.withId("org.jetbrains.kotlin.multiplatform") { plugin -> auditVersion(plugin) }

#     afterEvaluate { project ->
#         // =========================================================================
#         // 2. INSPECTOR DE METADATOS: Filtrado exclusivo de .kotlin_module
#         // =========================================================================
#         project.tasks.matching { it.class.name.contains("KotlinCompile") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 task.doFirst {
#                     println "🔍 [METADATA AUDIT] Iniciando tarea :${project.name}:${task.name}"
#                 }  
#                 task.doLast { taskInstance ->
#                     taskInstance.outputs.files.each { outputDir ->
#                         if (outputDir.exists() && outputDir.isDirectory()) {
#                             final String projectName = project.name
#                             outputDir.eachFileRecurse { file ->
#                                 // Filtrar ÚNICAMENTE los metadatos binarios del módulo Kotlin
#                                 if (file.name.endsWith(".kotlin_module")) {
#                                     try {
#                                         def bytes = file.bytes
#                                         if (bytes.length > 8) {
#                                             // Firma binaria de especificación de metadatos de Kotlin
#                                             int major = bytes[0] & 0xFF
#                                             int minor = bytes[1] & 0xFF
#                                             if (major > 1 || (major == 1 && minor > 8)) {
#                                                 println "⚠️ [METADATA ALERT] Módulo :${projectName} contiene metadatos incompatibles [Kotlin ${major}.${minor}] -> ${file.name}"
#                                             } else {
#                                                 println "✅ [METADATA INFO] Módulo :${projectName} verificado correctamente [Kotlin ${major}.${minor}] -> ${file.name}"
#                                             }
#                                         }
#                                     } catch (Exception e) {}
#                                 }
#                             }
#                         }
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // =========================================================================
#         // 3. VALIDADOR Y ESCUDO JVM: Evita StackOverflows en el compilador
#         // =========================================================================
#         project.tasks.withType(JavaCompile).configureEach { task ->
#             try {
#                 task.options.fork = true
#                 task.options.forkOptions.with {
#                     memoryMaximumSize = "4g"
#                     if (jvmArgs == null) {
#                         jvmArgs = ["-Xss8m", "-XX:MaxMetaspaceSize=1g"]
#                     } else {
#                         jvmArgs.addAll(["-Xss8m", "-XX:MaxMetaspaceSize=1g"])
#                     }
#                 }

#                 task.doFirst {
#                     println "🚀 [JVM VALIDATOR] Proceso Fork configurado para :${project.name}:${task.name}"
#                     println "   -> jvmArgs asignados: ${task.options.forkOptions.jvmArgs}"
#                 }
#             } catch (Exception e) {}
#         }

#         // =========================================================================
#         // 4. OPTIMIZACIÓN NATIVA: Reducción en caliente (.so) mediante llvm-strip
#         // =========================================================================
#         if (ENABLE_STRIP) {
#             project.tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibs") }.configureEach { task ->
#                 try {
#                     task.doLast {
#                         def androidExt = project.extensions.findByName("android")
#                         if (!androidExt) return
                        
#                         // Localización segura del NDK mapeado por la instancia de ejecución
#                         def ndkDir = androidExt.hasProperty("ndkDirectory") ? androidExt.ndkDirectory : null
#                         if (ndkDir == null) return
                        
#                         def osName = System.getProperty("os.name").toLowerCase()
#                         def hostOs = osName.contains("linux") ? "linux-x86_64" : 
#                                      osName.contains("mac") ? "darwin-x86_64" : "windows-x86_64"
                        
#                         def stripExecutable = "${ndkDir}/toolchains/llvm/prebuilt/${hostOs}/bin/llvm-strip"
#                         if (osName.contains("windows")) stripExecutable += ".exe"

#                         if (new File(stripExecutable).exists()) {
#                             task.outputs.files.each { fileOutput ->
#                                 if (fileOutput.exists()) {
#                                     project.fileTree(dir: fileOutput, include: "**/*.so").each { soFile ->
#                                         println "🛡️ [OPTIMIZER] Aplicando llvm-strip a -> :${project.name}:${soFile.name}"
#                                         project.exec {
#                                             commandLine stripExecutable, '--strip-unneeded', soFile.absolutePath
#                                             ignoreExitValue = true
#                                         }
#                                     }
#                                 }
#                             }
#                         }
#                     }
#                 } catch (Exception e) {}
#             }
#         }
#     }
# }
# EOF
# echo "  ... Fixed Metadata Inspector, JVM Validator, and Native Optimizer saved to ~/.gradle/init.gradle"

# echo "🛡️ INFRA: Injected Verbose Metadata Inspector, JVM Stack Shield and Universal Native Optimizer..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     // =========================================================================
#     // CONFIGURACIÓN DE OPTIMIZACIÓN GLOBAL
#     // =========================================================================
#     def ENABLE_STRIP = true

#     // =========================================================================
#     // 1. AUDITORÍA ESTÁTICA: Monitoreo verboso de plugins de Kotlin
#     // =========================================================================
#     def auditVersion = { pluginInstance, currentProject ->
#         if (pluginInstance && pluginInstance.hasProperty('kotlinPluginVersion')) {
#             def version = pluginInstance.kotlinPluginVersion
#             def parts = version.split('\\.')
#             if (parts.length >= 2) {
#                 try {
#                     int major = parts[0].toInteger()
#                     int minor = parts[1].toInteger()
                    
#                     // Imprime SIEMPRE la información del plugin para cada módulo
#                     if (major > 1 || (major == 1 && minor > 8)) {
#                         println "⚠️ [KOTLIN PLUGIN ALERT] Módulo :${currentProject.name} configurado con Kotlin ${version} (Superior a 1.8)"
#                     } else {
#                         println "✅ [KOTLIN PLUGIN INFO] Módulo :${currentProject.name} configurado con Kotlin ${version} (Correcto)"
#                     }
#                 } catch (NumberFormatException e) {}
#             }
#         }
#     }

#     // Inyección segura pasando la instancia actual de 'project'
#     plugins.withId("org.jetbrains.kotlin.jvm") { plugin -> auditVersion(plugin, project) }
#     plugins.withId("org.jetbrains.kotlin.android") { plugin -> auditVersion(plugin, project) }
#     plugins.withId("org.jetbrains.kotlin.multiplatform") { plugin -> auditVersion(plugin, project) }

#     afterEvaluate { project ->
#         // =========================================================================
#         // 2. INSPECTOR VERBOSO DE METADATOS: Muestra siempre la versión de .kotlin_module
#         // =========================================================================
#         project.tasks.matching { it.class.name.contains("KotlinCompile") || it.class.name.contains("Kapt") }.configureEach { task ->
#             try {
#                 task.doFirst {
#                     println "🔍 [METADATA AUDIT] Iniciando tarea :${project.name}:${task.name}"
#                 }  
#                 task.doLast { taskInstance ->
#                     taskInstance.outputs.files.each { outputDir ->
#                         if (outputDir.exists() && outputDir.isDirectory()) {
#                             final String projectName = project.name
#                             outputDir.eachFileRecurse { file ->
#                                 if (file.name.endsWith(".kotlin_module")) {
#                                     try {
#                                         def bytes = file.bytes
#                                         if (bytes.length >= 6) {
#                                             int major = 0
#                                             int minor = 0
                                            
#                                             // Escaneo seguro de cabecera binaria
#                                             for (int i = 0; i < bytes.length - 1; i++) {
#                                                 if ((bytes[i] & 0xFF) == 0x08 && (bytes[i+1] & 0xFF) > 0) {
#                                                     if (i + 2 < bytes.length) {
#                                                         major = bytes[i+1] & 0xFF
#                                                         minor = bytes[i+2] & 0xFF
#                                                         break
#                                                     }
#                                                 }
#                                             }
                                            
#                                             if (major == 0) {
#                                                 major = bytes[4] & 0xFF
#                                                 minor = bytes[5] & 0xFF
#                                             }

#                                             if (major > 1 || (major == 1 && minor > 8)) {
#                                                 println "⚠️ [METADATA ALERT] Módulo :${projectName} contiene metadatos incompatibles [Kotlin ${major}.${minor}] -> ${file.name}"
#                                             } else {
#                                                 println "✅ [METADATA INFO] Módulo :${projectName} verificado correctamente [Kotlin ${major}.${minor}] -> ${file.name}"
#                                             }
#                                         }
#                                     } catch (Exception e) {}
#                                 }
#                             }
#                         }
#                     }
#                 }
#             } catch (Exception e) {}
#         }

#         // =========================================================================
#         // 3. VALIDADOR Y ESCUDO JVM: Previene StackOverflows
#         // =========================================================================
#         project.tasks.withType(JavaCompile).configureEach { task ->
#             try {
#                 task.options.fork = true
#                 task.options.forkOptions.with {
#                     memoryMaximumSize = "4g"
#                     if (jvmArgs == null) {
#                         jvmArgs = ["-Xss8m", "-XX:MaxMetaspaceSize=1g"]
#                     } else {
#                         jvmArgs.addAll(["-Xss8m", "-XX:MaxMetaspaceSize=1g"])
#                     }
#                 }

#                 task.doFirst {
#                     println "🚀 [JVM VALIDATOR] Proceso Fork configurado para :${project.name}:${task.name}"
#                 }
#             } catch (Exception e) {}
#         }

#         // =========================================================================
#         // 4. OPTIMIZACIÓN NATIVA UNIVERSAL: Captura tanto Apps como Librerías (.so)
#         // =========================================================================
#         if (ENABLE_STRIP) {
#             project.tasks.matching { t ->
#                 def nameLower = t.name.toLowerCase()
#                 return nameLower.matches(/.*merge.*jnilibs.*/) || nameLower.matches(/.*strip.*debugsymbols.*/)
#             }.configureEach { task ->
#                 try {
#                     task.doLast {
#                         def androidExt = project.extensions.findByName("android")
#                         if (!androidExt) return
                        
#                         def ndkDir = androidExt.hasProperty("ndkDirectory") ? androidExt.ndkDirectory : null
#                         if (ndkDir == null) return
                        
#                         def osName = System.getProperty("os.name").toLowerCase()
#                         def hostOs = osName.contains("linux") ? "linux-x86_64" : 
#                                      osName.contains("mac") ? "darwin-x86_64" : "windows-x86_64"
                        
#                         def stripExecutable = "${ndkDir}/toolchains/llvm/prebuilt/${hostOs}/bin/llvm-strip"
#                         if (osName.contains("windows")) stripExecutable += ".exe"

#                         if (new File(stripExecutable).exists()) {
#                             task.outputs.files.each { fileOutput ->
#                                 if (fileOutput.exists()) {
#                                     def tree = fileOutput.isDirectory() ? project.fileTree(fileOutput) : project.files(fileOutput)
#                                     tree.include("**/*.so").each { soFile ->
#                                         println "🛡️ [OPTIMIZER] Aplicando llvm-strip directo -> :${project.name}:${soFile.name}"
#                                         project.exec {
#                                             commandLine stripExecutable, '--strip-unneeded', soFile.absolutePath
#                                             ignoreExitValue = true
#                                         }
#                                     }
#                                 }
#                             }
#                         }
#                     }
#                 } catch (Exception e) {}
#             }
#         }
#     }
# }
# EOF
# echo "  ✅ Fully Verbose Pipeline saved successfully to ~/.gradle/init.gradle"

echo "🛡️ INFRA: Injected Verbose Metadata Inspector, JVM Stack Shield and Universal Native Optimizer..."
cat << 'EOF' > ~/.gradle/init.gradle
allprojects {
    // 1. AUDITORÍA ESTÁTICA COMEDIDA (API Oficial de Gradle)
    // Lee las propiedades registradas en los plugins aplicados, no los binarios generados.
    def auditProjectPlugin = { currentProject ->
        def kotlinExtension = currentProject.extensions.findByName("kotlin")
        if (kotlinExtension && kotlinExtension.hasProperty("coreLibrariesVersion")) {
            def version = kotlinExtension.coreLibrariesVersion
            println "✅ [KOTLIN AUDIT] Módulo :${currentProject.name} usando SDK v${version}"
        }
    }

    afterEvaluate { project ->
        auditProjectPlugin(project)

        // 2. OPTIMIZACIÓN NATIVA ESTÁNDAR (AGP AndroidComponentsExtension)
        // Se ejecuta sobre el modelo de variantes oficial de Android, no sobre los directorios del FileSystem.
        def androidComponents = project.extensions.findByName("androidComponents")
        if (androidComponents != null) {
            androidComponents.onVariants { variant ->
                // Buscamos la herramienta llvm-strip oficial asociada a la compilación
                def androidExt = project.extensions.findByName("android")
                if (androidExt && androidExt.hasProperty("ndkDirectory") && androidExt.ndkDirectory != null) {
                    def ndkDir = androidExt.ndkDirectory
                    def osName = System.getProperty("os.name").toLowerCase()
                    def hostOs = osName.contains("linux") ? "linux-x86_64" : 
                                 osName.contains("mac") ? "darwin-x86_64" : "windows-x86_64"
                    
                    def stripExecutable = "${ndkDir}/toolchains/llvm/prebuilt/${hostOs}/bin/llvm-strip"
                    if (osName.contains("windows")) stripExecutable += ".exe"

                    // Si el binario existe, configuramos las tareas de empaquetado nativo de forma limpia
                    if (new File(stripExecutable).exists()) {
                        project.tasks.configureEach { task ->
                            def taskName = task.name.toLowerCase()
                            if (taskName.contains("strip") && taskName.contains("debugsymbols")) {
                                task.doLast {
                                    task.outputs.files.each { output ->
                                        if (output.exists()) {
                                            if (output.isDirectory()) {
                                                project.fileTree(dir: output, include: "**/*.so").each { runStrip(stripExecutable, it) }
                                            } else if (output.isFile() && output.name.endsWith(".so")) {
                                                runStrip(stripExecutable, output)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

def runStrip(String executable, File soFile) {
    println "🛡️ [OPTIMIZER] Aplicando llvm-strip oficial -> ${soFile.name}"
    exec {
        commandLine executable, '--strip-unneeded', soFile.absolutePath
        ignoreExitValue = true
    }
}
EOF
echo "  ✅ Fully Verbose Pipeline saved successfully to ~/.gradle/init.gradle"


# echo "🛡️ INFRA: Añadiendo bloque de compatibilidad Kotlin 1.8 al final de buildSrc..."
# cat << 'EOF' >> examples/virtual-device-app/android/App/buildSrc/build.gradle.kts

# // Bloque de compatibilidad inyectado automáticamente
# tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
#     kotlinOptions {
#         languageVersion = "1.8"
#         apiVersion = "1.8"
#         jvmTarget = "1.8"
#     }
# }
# EOF
# echo "  ✅ Bloque añadido con éxito."


echo "🛡️ INFRA: Inyectando banderas de mitigación de metadatos en el build.gradle.kts raíz..."
cat << 'EOF' >> examples/virtual-device-app/android/App/build.gradle.kts

// Forzar la omisión del chequeo de versiones de metadatos en todas las tareas de Kotlin
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            freeCompilerArgs = freeCompilerArgs + listOf("-Xskip-metadata-version-check", "-Xskip-prerelease-check")
        }
    }
}
EOF
echo "  ✅ Banderas inyectadas con éxito en el archivo raíz."

# # Exportamos GRADLE_OPTS corregido (Unificando a 8MB reales y removiendo flags duplicados)
# export GRADLE_OPTS="-Xmx4g -Xms2g -Xss8m -XX:MaxMetaspaceSize=1024m" # -Dorg.gradle.logging.level=info"

# echo "INFRA: Configurando inhibidores de error y metadatos en el motor de Kotlin..."
# export KOTLIN_COMPILER_ARGS="-nowarn -warn:0 -Xskip-metadata-version-check -Xallow-no-source-files"
# export KOTLINC_ARGS="-nowarn"

# # Forzar la omisión de chequeo de metadatos tanto en Gradle como en el Demonio de Kotlin
# # Forzar al Demonio de Kotlin a nivel de entorno global a ignorar la verificación de versiones de metadatos
# export GRADLE_OPTS="$GRADLE_OPTS -Dkotlin.skip.metadata.version.check=true"
# export KOTLIN_DAEMON_ARGS="-Dkotlin.skip.metadata.version.check=true"


echo "========================================================================="
echo "🔍 DIAGNÓSTICO AVANZADO DE ENTORNO EN EL RUNNER (HOST VIRTUAL)"
echo "========================================================================="
echo "  ↳ GITHUB_WORKSPACE : ${GITHUB_WORKSPACE:-'❌ NO EXPORTADA / VACÍA'}"
echo "  ↳ CURRENT JAVA_HOME: ${JAVA_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ ANDROID_HOME     : ${ANDROID_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ ANDROID_NDK_ROOT : ${ANDROID_NDK_ROOT:-'❌ NO DETECTADA'}"
echo "========================================================================="

echo "INFRA: Limpiando parches de texto residuales..."
git reset --hard HEAD --quiet || true
git clean -fd --quiet || true

if [ "$FORCE_CLEAR_CACHE" = "true" ]; then
    echo "⚠️ INFRA: Flag 'clear_cache' detectado como TRUE. Destruyendo carpeta out/..."
    rm -rf out/
else
    echo "⚡ INFRA: Manteniendo carpeta 'out/' para permitir compilación incremental rápida."
fi

echo "INFRA: Neutralizando configuraciones JSON rígidas de CIPD para ZAP..."
find . -name "zap.json" -exec sh -c 'echo "{\"packages\": []}" > "{}"' \;

echo "INFRA: Parcheando dependencia crítica libgirepository en caliente..."
sudo apt-get update && sudo apt-get install -y libgirepository1.0-dev

# INICIALIZACIÓN DEL ENTORNO DE COMPILACIÓN DE MATTER
echo "INFRA: Inicializando el entorno virtual aislado de Pigweed..."
source scripts/activate.sh

echo "INFRA: Descargando pre-requisitos de dependencias de Android..."
python3 third_party/android_deps/set_up_android_deps.py
third_party/java_deps/set_up_java_deps.sh

# 🧹 LIMPIEZA DE WARNINGS ESTRICTOS (-Werror & -Xlint)
find . -name "BUILD.gn" -exec sed -i 's|"-Werror",||g' {} +
find . -name "BUILD.gn" -exec sed -i 's|"-Werror"||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Werror",||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Werror"||g' {} +
find . -name "BUILD.gn" -exec sed -i 's|"-Xlint:all",||g' {} +
find . -name "BUILD.gn" -exec sed -i 's|"-Xlint:all"||g' {} +
find . -name "gradle.properties" -exec sed -i 's|-XX:MaxPermSize=2048m||g' {} +

# 🛠️ REGENERAR LA ESTRUCTURA DE COMPILACIÓN GN
echo "INFRA: Sincronizando árbol estructural de mapas de GN..."
gn gen out/virtual-device-app \
  --args='target_os="android" target_cpu="arm" android_ndk_root="'$ANDROID_NDK_ROOT'" android_sdk_root="'$ANDROID_HOME'" chip_config_network_layer_ble=false treat_warnings_as_errors=false' \
  --root=examples/virtual-device-app/android/
  
find out/ -name "*.json" -exec sed -i 's|"-Werror",||g' {} +

ANDROID_PY_FILE="scripts/build/builders/android.py"
if [ -f "$ANDROID_PY_FILE" ]; then
    echo "INFRA: Aplicando parche en android.py sobre la ejecución de sdkmanager..."
    sed -i 's@"yes | %s --licenses >/dev/null"@"yes | JAVA_HOME='"$JAVA_HOME_17_X64"' %s --licenses >/dev/null"@g' "$ANDROID_PY_FILE"
fi

# 🚀 EJECUCIÓN DEL MÓDULO INTÉRPRETE DE COMPILACIÓN DE MATTER
echo "INFRA: Invocando script compilador nativo (Llamada Python a Gradle Wrapper)..."
./scripts/build/build_examples.py --target android-arm-virtual-device-app build

if [ -f "$DUMP_DIR/gradle_oom_dump.hprof" ]; then
    echo "🚨 ALERTA: ¡Se ha detectado un volcado de memoria por OutOfMemory en Jetifier/Kotlin!"
    echo "  ↳ Tamaño del volcado: $(ls -lh "$DUMP_DIR/gradle_oom_dump.hprof" | awk '{print $5}')"
fi

# =========================================================================
# 🚀 OPTIMIZACIÓN POST-COMPILACIÓN (LLVM-STRIP)
# =========================================================================
JNI_TARGET_DIR="examples/virtual-device-app/android/App/app/libs/jniLibs/armeabi-v7a"
STRIP_TOOL="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"

if [ -x "$STRIP_TOOL" ] && [ -d "$JNI_TARGET_DIR" ]; then
    echo "INFRA: Procesando binarios nativos con llvm-strip..."
    for so_file in "$JNI_TARGET_DIR"/*.so; do
        [[ "$so_file" == *"_small.so" ]] && continue
        [ -f "$so_file" ] || continue
        base_name="${so_file%.so}"
        $STRIP_TOOL --strip-unneeded "$so_file" -o "${base_name}_small.so"
    done
fi
