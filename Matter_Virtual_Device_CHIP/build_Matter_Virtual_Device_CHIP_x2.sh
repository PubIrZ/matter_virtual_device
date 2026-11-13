#!/bin/bash

#exit 0 
 

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

# echo "🛡️ INFRA: Injected Verbose Metadata Inspector, JVM Stack Shield and Universal Native Optimizer..."
# cat << 'EOF' > ~/.gradle/init.gradle
# allprojects {
#     // 1. AUDITORÍA ESTÁTICA COMEDIDA (API Oficial de Gradle)
#     // Lee las propiedades registradas en los plugins aplicados, no los binarios generados.
#     def auditProjectPlugin = { currentProject ->
#         def kotlinExtension = currentProject.extensions.findByName("kotlin")
#         if (kotlinExtension && kotlinExtension.hasProperty("coreLibrariesVersion")) {
#             def version = kotlinExtension.coreLibrariesVersion
#             println "✅ [KOTLIN AUDIT] Módulo :${currentProject.name} usando SDK v${version}"
#         }
#     }

#     afterEvaluate { project ->
#         auditProjectPlugin(project)

#         // 2. OPTIMIZACIÓN NATIVA ESTÁNDAR (AGP AndroidComponentsExtension)
#         // Se ejecuta sobre el modelo de variantes oficial de Android, no sobre los directorios del FileSystem.
#         def androidComponents = project.extensions.findByName("androidComponents")
#         if (androidComponents != null) {
#             androidComponents.onVariants { variant ->
#                 // Buscamos la herramienta llvm-strip oficial asociada a la compilación
#                 def androidExt = project.extensions.findByName("android")
#                 if (androidExt && androidExt.hasProperty("ndkDirectory") && androidExt.ndkDirectory != null) {
#                     def ndkDir = androidExt.ndkDirectory
#                     def osName = System.getProperty("os.name").toLowerCase()
#                     def hostOs = osName.contains("linux") ? "linux-x86_64" : 
#                                  osName.contains("mac") ? "darwin-x86_64" : "windows-x86_64"
                    
#                     def stripExecutable = "${ndkDir}/toolchains/llvm/prebuilt/${hostOs}/bin/llvm-strip"
#                     if (osName.contains("windows")) stripExecutable += ".exe"

#                     // Si el binario existe, configuramos las tareas de empaquetado nativo de forma limpia
#                     if (new File(stripExecutable).exists()) {
#                         project.tasks.configureEach { task ->
#                             def taskName = task.name.toLowerCase()
#                             if (taskName.contains("strip") && taskName.contains("debugsymbols")) {
#                                 task.doLast {
#                                     task.outputs.files.each { output ->
#                                         if (output.exists()) {
#                                             if (output.isDirectory()) {
#                                                 project.fileTree(dir: output, include: "**/*.so").each { runStrip(stripExecutable, it) }
#                                             } else if (output.isFile() && output.name.endsWith(".so")) {
#                                                 runStrip(stripExecutable, output)
#                                             }
#                                         }
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

# def runStrip(String executable, File soFile) {
#     println "🛡️ [OPTIMIZER] Aplicando llvm-strip oficial -> ${soFile.name}"
#     exec {
#         commandLine executable, '--strip-unneeded', soFile.absolutePath
#         ignoreExitValue = true
#     }
# }
# EOF
# echo "  ✅ Fully Verbose Pipeline saved successfully to ~/.gradle/init.gradle"


# =========================================================================
# 🛡️ PIPELINE DE INICIALIZACIÓN NATIVA (GRADLE GLOBAL OPTIMIZER)
# =========================================================================
mkdir -p ~/.gradle

cat << 'EOF' > ~/.gradle/init.gradle
allprojects {
    // CONFIGURACIÓN DE OPTIMIZACIÓN GLOBAL
    def ENABLE_STRIP = false

    // 1. AUDITORÍA NATIVA DEL COMPILADOR KOTLIN
    afterEvaluate { project ->
        def kotlinExt = project.extensions.findByName("kotlin")
        if (kotlinExt != null && kotlinExt.hasProperty("coreLibrariesVersion")) {
            println "✅ [KOTLIN AUDIT] Módulo :${project.name} operando bajo SDK v${kotlinExt.coreLibrariesVersion}"
        }
    }

    // 2. OPTIMIZACIÓN NATIVA BLINDADA MEDIANTE VARIABLES DE ENTORNO DEL RUNNER
    if (ENABLE_STRIP) {
      tasks.configureEach { task ->
          def taskName = task.name.toLowerCase()
          if ((taskName.contains("strip") && taskName.contains("debugsymbols")) || 
              (taskName.contains("strip") && taskName.contains("releasesymbols")) ||
              (taskName.startsWith("merge") && taskName.endsWith("jnilibs"))) {
              
              task.doLast {
                  // Leemos directamente el mapa de entorno del Runner inyectado por GitHub Actions
                  def ndkPath = System.getenv("ANDROID_NDK_ROOT") ?: System.getenv("ANDROID_NDK_HOME")
                
                  if (ndkPath != null && !ndkPath.isEmpty()) {
                      def osName = System.getProperty("os.name").toLowerCase()
                      def hostOs = osName.contains("linux") ? "linux-x86_64" : 
                                   osName.contains("mac") ? "darwin-x86_64" : "windows-x86_64"
                    
                      def stripExecutable = "${ndkPath}/toolchains/llvm/prebuilt/${hostOs}/bin/llvm-strip"
                      if (osName.contains("windows")) stripExecutable += ".exe"

                      if (new File(stripExecutable).exists()) {
                          task.outputs.files.each { output ->
                              if (output.exists()) {
                                  if (output.isDirectory()) {
                                      project.fileTree(dir: output, include: "**/*.so").each { soFile ->
                                          println "🛡️ [OPTIMIZER] Aplicando llvm-strip -> :${project.name}:${soFile.name}"
                                          project.exec {
                                              commandLine stripExecutable, '--strip-unneeded', soFile.absolutePath
                                              ignoreExitValue = true
                                          }
                                      }
                                  } else if (output.isFile() && output.name.endsWith(".so")) {
                                      println "🛡️ [OPTIMIZER] Aplicando llvm-strip -> :${project.name}:${output.name}"
                                      project.exec {
                                          commandLine stripExecutable, '--strip-unneeded', output.absolutePath
                                          ignoreExitValue = true
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
EOF

echo "✅ Ecosistema de optimización nativa blindado e inyectado en ~/.gradle/init.gradle"




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


# # =========================================================================
# # 🏗️ VALIDACIÓN ESTÁTICA: REEMPLAZO DE ARCHIVO .ZAP CON PARSER OFICIAL COMPATIBLE
# # =========================================================================
# ZAP_FILE="examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"

# echo "INFRA: Creando copia de seguridad del .zap original del repositorio..."
# cp "$ZAP_FILE" "${ZAP_FILE}.bak"

# # Disparador de seguridad: Si la compilación falla, se restaura el estado original de Git
# trap 'echo "🚨 Revertiendo cambios por fallo en compilación..."; mv "${ZAP_FILE}.bak" "$ZAP_FILE" || true' ERR

# echo "INFRA: Extrayendo plantilla de Luz On/Off nativa homologada del SDK..."
# # Usamos el modelo estructural limpio de 'lighting-app' que ya contiene todos los defines de C++ 
# # requeridos por zap_cluster_list.py, pero mapeando los IDs de los endpoints de la app de Android.
# cat << 'EOF' > "$ZAP_FILE"
# {
#   "fileFormat": 2,
#   "featureLevel": 100,
#   "creator": "zap",
#   "keyValuePairs": [
#     { "key": "commandDiscovery", "value": "1" },
#     { "key": "defaultResponsePolicy", "value": "always" },
#     { "key": "manufacturerCodes", "value": "0x1002" }
#   ],
#   "package": [
#     {
#       "pathRelativity": "relativeToZap",
#       "path": "../../../src/app/zap-templates/zcl/zcl.json",
#       "type": "zcl-properties",
#       "category": "matter",
#       "version": 1
#     },
#     {
#       "pathRelativity": "relativeToZap",
#       "path": "../../../src/app/zap-templates/app-templates.json",
#       "type": "gen-templates-json",
#       "version": "chip-v1"
#     }
#   ],
#   "endpointTypes": [
#     {
#       "id": 1,
#       "name": "MA-rootdevice",
#       "deviceTypeRef": { "code": 22, "profileId": 259, "label": "MA-rootdevice", "name": "MA-rootdevice" },
#       "deviceTypes": [ { "code": 22, "profileId": 259, "label": "MA-rootdevice", "name": "MA-rootdevice" } ],
#       "deviceVersions": [ 1 ], "deviceIdentifiers": [ 22 ], "deviceTypeName": "MA-rootdevice", "deviceTypeCode": 22, "deviceTypeProfileId": 259,
#       "clusters": [
#         { "name": "Descriptor", "code": 29, "define": "DESCRIPTOR_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Basic Information", "code": 40, "define": "BASIC_INFORMATION_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "General Commissioning", "code": 48, "define": "GENERAL_COMMISSIONING_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Network Commissioning", "code": 49, "define": "NETWORK_COMMISSIONING_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Operational Credentials", "code": 62, "define": "OPERATIONAL_CREDENTIALS_CLUSTER", "side": "server", "enabled": 1, "attributes": [] }
#       ]
#     },
#     {
#       "id": 2,
#       "name": "MA-onofflight",
#       "deviceTypeRef": { "code": 256, "profileId": 259, "label": "MA-onofflight", "name": "MA-onofflight" },
#       "deviceTypes": [ { "code": 256, "profileId": 259, "label": "MA-onofflight", "name": "MA-onofflight" } ],
#       "deviceVersions": [ 1 ], "deviceIdentifiers": [ 256 ], "deviceTypeName": "MA-onofflight", "deviceTypeCode": 256, "deviceTypeProfileId": 259,
#       "clusters": [
#         { "name": "Descriptor", "code": 29, "define": "DESCRIPTOR_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Identify", "code": 3, "define": "IDENTIFY_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Groups", "code": 4, "define": "GROUPS_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Scenes Management", "code": 98, "define": "SCENES_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "On/Off", "code": 6, "define": "ON_OFF_CLUSTER", "side": "server", "enabled": 1, "attributes": [] }
#       ]
#     }
#   ],
#   "endpoints": [
#     { "endpointTypeName": "MA-rootdevice", "endpointTypeIndex": 0, "profileId": 259, "endpointId": 0, "networkId": 0, "parentEndpointIdentifier": null },
#     { "endpointTypeName": "MA-onofflight", "endpointTypeIndex": 1, "profileId": 259, "endpointId": 1, "networkId": 0, "parentEndpointIdentifier": null }
#   ]
# }
# EOF

# echo "INFRA: Invocando la CLI de ZAP para regenerar los stubs C++ con la metadata correcta..."
# ./scripts/tools/zap/generate.py "$ZAP_FILE"


########## COMPILO LA APP <<----------------
# # =========================================================================
# # 🏗️ SOLUCIÓN INTEGRAL: .ZAP HOMOLOGADO + RETIRADA DE .CPP e INTERCEPCIÓN JNI CORE
# # =========================================================================
# GN_FILE="examples/virtual-device-app/android/BUILD.gn"
# SRC_JNI="examples/virtual-device-app/android/java/DeviceApp-JNI.cpp"
# ZAP_FILE="examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"

# echo "INFRA: Creando buffers de respaldo temporales para Git..."
# cp "$GN_FILE" "${GN_FILE}.bak"
# cp "$SRC_JNI" "${SRC_JNI}.bak"
# cp "$ZAP_FILE" "${ZAP_FILE}.bak"

# # Registrar el disparador de restauración en caso de error en el pipeline
# trap 'echo "🚨 Revertiendo parches de fuentes nativos..."; mv "${ZAP_FILE}.bak" "$ZAP_FILE" || true; mv "${SRC_JNI}.bak" "$SRC_JNI" || true; mv "${GN_FILE}.bak" "$GN_FILE" || true' ERR


# echo "INFRA: Escribiendo tu plantilla .zap homologada de Luz On/Off limpia de clústeres..."
# cat << 'EOF' > "$ZAP_FILE"
# {
#   "fileFormat": 2,
#   "featureLevel": 100,
#   "creator": "zap",
#   "keyValuePairs": [
#     { "key": "commandDiscovery", "value": "1" },
#     { "key": "defaultResponsePolicy", "value": "always" },
#     { "key": "manufacturerCodes", "value": "0x1002" }
#   ],
#   "package": [
#     {
#       "pathRelativity": "relativeToZap",
#       "path": "../../../src/app/zap-templates/zcl/zcl.json",
#       "type": "zcl-properties",
#       "category": "matter",
#       "version": 1
#     },
#     {
#       "pathRelativity": "relativeToZap",
#       "path": "../../../src/app/zap-templates/app-templates.json",
#       "type": "gen-templates-json",
#       "version": "chip-v1"
#     }
#   ],
#   "endpointTypes": [
#     {
#       "id": 1,
#       "name": "MA-rootdevice",
#       "deviceTypeRef": { "code": 22, "profileId": 259, "label": "MA-rootdevice", "name": "MA-rootdevice" },
#       "deviceTypes": [ { "code": 22, "profileId": 259, "label": "MA-rootdevice", "name": "MA-rootdevice" } ],
#       "deviceVersions": [ 1 ], "deviceIdentifiers": [ 22 ], "deviceTypeName": "MA-rootdevice", "deviceTypeCode": 22, "deviceTypeProfileId": 259,
#       "clusters": [
#         { "name": "Descriptor", "code": 29, "define": "DESCRIPTOR_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Basic Information", "code": 40, "define": "BASIC_INFORMATION_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "General Commissioning", "code": 48, "define": "GENERAL_COMMISSIONING_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Network Commissioning", "code": 49, "define": "NETWORK_COMMISSIONING_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Operational Credentials", "code": 62, "define": "OPERATIONAL_CREDENTIALS_CLUSTER", "side": "server", "enabled": 1, "attributes": [] }
#       ]
#     },
#     {
#       "id": 2,
#       "name": "MA-onofflight",
#       "deviceTypeRef": { "code": 256, "profileId": 259, "label": "MA-onofflight", "name": "MA-onofflight" },
#       "deviceTypes": [ { "code": 256, "profileId": 259, "label": "MA-onofflight", "name": "MA-onofflight" } ],
#       "deviceVersions": [ 1 ], "deviceIdentifiers": [ 256 ], "deviceTypeName": "MA-onofflight", "deviceTypeCode": 256, "deviceTypeProfileId": 259,
#       "clusters": [
#         { "name": "Descriptor", "code": 29, "define": "DESCRIPTOR_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Identify", "code": 3, "define": "IDENTIFY_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Groups", "code": 4, "define": "GROUPS_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "Scenes Management", "code": 98, "define": "SCENES_CLUSTER", "side": "server", "enabled": 1, "attributes": [] },
#         { "name": "On/Off", "code": 6, "define": "ON_OFF_CLUSTER", "side": "server", "enabled": 1, "attributes": [] }
#       ]
#     }
#   ],
#   "endpoints": [
#     { "endpointTypeName": "MA-rootdevice", "endpointTypeIndex": 0, "profileId": 259, "endpointId": 0, "networkId": 0, "parentEndpointIdentifier": null },
#     { "endpointTypeName": "MA-onofflight", "endpointTypeIndex": 1, "profileId": 259, "endpointId": 1, "networkId": 0, "parentEndpointIdentifier": null }
#   ]
# }
# EOF

# echo "INFRA: Purgando UNICAMENTE los archivos que causaban errores de compilación en el BUILD.gn..."
# # Mantenemos AppImpl.cpp activo para que el servidor de red pueda arrancar de forma conforme
# sed -i 's|"java/ColorControlManager.cpp",|# "java/ColorControlManager.cpp",|g' "$GN_FILE"
# sed -i 's|"java/ColorControlManager.h",|# "java/ColorControlManager.h",|g' "$GN_FILE"
# sed -i 's|"java/DoorLockManager.cpp",|# "java/DoorLockManager.cpp",|g' "$GN_FILE"
# sed -i 's|"java/DoorLockManager.h",|# "java/DoorLockManager.h",|g' "$GN_FILE"
# sed -i 's|"java/ClusterChangeAttribute.cpp",|# "java/ClusterChangeAttribute.cpp",|g' "$GN_FILE"
# sed -i 's|"java/PowerSourceManager.cpp",|# "java/PowerSourceManager.cpp",|g' "$GN_FILE"
# sed -i 's|"java/PowerSourceManager.h",|# "java/PowerSourceManager.h",|g' "$GN_FILE"

# echo "INFRA: Reescribiendo el envoltorio JNI core limpio de llamadas obsoletas..."
# cat << 'EOF' > "$SRC_JNI"
# #include "DeviceApp-JNI.h"
# #include "AppImpl.h"
# #include "JNIDACProvider.h"
# #include "OnOffManager.h"
# #include "credentials/DeviceAttestationCredsProvider.h"
# #include <app/server/java/AndroidAppServerWrapper.h>
# #include <credentials/examples/DeviceAttestationCredsExample.h>
# #include <app/util/af-types.h> // 🔑 CRÍTICO: Define EmberAfDeviceType
# #include <jni.h>
# #include <lib/core/CHIPError.h>
# #include <lib/support/CHIPJNIError.h>
# #include <lib/support/JniReferences.h>

# using namespace chip;

# #define JNI_METHOD(RETURN, METHOD_NAME) \
#     extern "C" JNIEXPORT RETURN JNICALL Java_com_matter_virtual_device_app_DeviceApp_##METHOD_NAME

# EmberAfDeviceType gDeviceTypeIds[] = { { 0, 1 } };
# DeviceAppJNI DeviceAppJNI::sInstance;

# void DeviceAppJNI::InitializeWithObjects(jobject app) {
#     JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
#     if (env != nullptr) { mDeviceAppObject.Init(app); }
# }
# void DeviceAppJNI::PostClusterInit(int clusterId, int endpoint) {}
# void DeviceAppJNI::PostEvent(int event) {}

# jint JNI_OnLoad(JavaVM * jvm, void * reserved) { return AndroidAppServerJNI_OnLoad(jvm, reserved); }
# void JNI_OnUnload(JavaVM * jvm, void * reserved) { AndroidAppServerJNI_OnUnload(jvm, reserved); }

# JNI_METHOD(void, nativeInit)(JNIEnv *, jobject app) { DeviceAppJNIMgr().InitializeWithObjects(app); }
# JNI_METHOD(void, preServerInit)(JNIEnv *, jobject app) { PreServerInit(); }
# JNI_METHOD(void, postServerInit)(JNIEnv *, jobject app, jint deviceTypeId) {
#     gDeviceTypeIds[0].deviceId = static_cast<uint16_t>(deviceTypeId);
# }
# JNI_METHOD(void, setDACProvider)(JNIEnv *, jobject, jobject provider) {
#     if (!chip::Credentials::IsDeviceAttestationCredentialsProviderSet()) {
#         chip::Credentials::SetDeviceAttestationCredentialsProvider(chip::Credentials::Examples::GetExampleDACProvider());
#     }
# }
# JNI_METHOD(void, setOnOffManager)(JNIEnv *, jobject, jint endpoint, jobject manager) { OnOffManager::NewManager(endpoint, manager); }
# JNI_METHOD(jboolean, setOnOff)(JNIEnv *, jobject, jint endpoint, jboolean value) { return true; }

# // STUBS DE ENLACE DINÁMICO EN VACÍO
# JNI_METHOD(void, setPowerSourceManager)(JNIEnv *, jobject, jint ep, jobject m) {}
# JNI_METHOD(jboolean, setBatPercentRemaining)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(void, setColorControlManager)(JNIEnv *, jobject, jint ep, jobject m) {}
# JNI_METHOD(void, setDoorLockManager)(JNIEnv *, jobject, jint ep, jobject m) {}
# JNI_METHOD(jboolean, setLockType)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setLockState)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setActuatorEnabled)(JNIEnv *, jobject, jint ep, jboolean v) { return true; }
# JNI_METHOD(jboolean, setAutoRelockTime)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setOperatingMode)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setSupportedOperatingModes)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, sendLockAlarmEvent)(JNIEnv *, jobject, jint ep) { return true; }
# EOF

# echo "INFRA: Invocando la CLI de ZAP para compilar el nuevo Data Model limpio..."
# ./scripts/tools/zap/generate.py "$ZAP_FILE"


# ########## COMPILO LA APP y Funciona el Emparejamiento con Alexa v3 <<----------------
# # =========================================================================
# # 🏗️ PIPELINE INTEGRAL: FILTRADO PYTHON .ZAP + DESACOPLAMIENTO DE FUENTES C++
# # =========================================================================
# GN_FILE="examples/virtual-device-app/android/BUILD.gn"
# SRC_JNI="examples/virtual-device-app/android/java/DeviceApp-JNI.cpp"
# ZAP_FILE="examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"

# echo "INFRA: Creando buffers de respaldo temporales para Git..."
# cp "$GN_FILE" "${GN_FILE}.bak"
# cp "$SRC_JNI" "${SRC_JNI}.bak"
# cp "$ZAP_FILE" "${ZAP_FILE}.bak"

# # Disparador de seguridad: Si la compilación falla, se restaura el estado original de Git
# trap 'echo "🚨 Revertiendo parches de fuentes nativos..."; mv "${ZAP_FILE}.bak" "$ZAP_FILE" || true; mv "${SRC_JNI}.bak" "$SRC_JNI" || true; mv "${GN_FILE}.bak" "$GN_FILE" || true' ERR

# echo "INFRA: Filtrando el .zap original en vuelo para conservar la conformidad de comandos y atributos..."
# python3 - << 'EOF'
# import json

# zap_path = "examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"

# with open(zap_path, 'r') as f:
#     data = json.load(f)

# for endpoint_type in data.get("endpointTypes", []):
#     if endpoint_type.get("id") == 2 or endpoint_type.get("name") == "MA-videoplayer":
#         endpoint_type["name"] = "MA-onofflight"
#         endpoint_type["deviceTypeCode"] = 256
#         endpoint_type["deviceTypeName"] = "MA-onofflight"
#         if "deviceTypeRef" in endpoint_type:
#             endpoint_type["deviceTypeRef"]["code"] = 256
#             endpoint_type["deviceTypeRef"]["label"] = "MA-onofflight"
#             endpoint_type["deviceTypeRef"]["name"] = "MA-onofflight"
#         if "deviceTypes" in endpoint_type:
#             for dt in endpoint_type["deviceTypes"]:
#                 dt["code"] = 256
#                 dt["label"] = "MA-onofflight"
#                 dt["name"] = "MA-onofflight"
#         if "deviceIdentifiers" in endpoint_type:
#             endpoint_type["deviceIdentifiers"] = [256]

#         original_clusters = endpoint_type.get("clusters", [])
#         filtered_clusters = [
#             c for c in original_clusters 
#             if c.get("code") != 257 and c.get("code") != 768
#         ]
#         endpoint_type["clusters"] = filtered_clusters

# for ep in data.get("endpoints", []):
#     if ep.get("endpointId") == 1 or ep.get("endpointTypeName") == "MA-videoplayer":
#         ep["endpointTypeName"] = "MA-onofflight"

# with open(zap_path, 'w') as f:
#     json.dump(data, f, indent=2)

# print("✅ INFRA PYTHON: Archivo .zap purgado con éxito manteniendo atributos mandatorios.")
# EOF

# echo "INFRA: Purgando UNICAMENTE los archivos que causaban errores de compilación en el BUILD.gn..."
# # Mantenemos AppImpl.cpp activo para que el servidor de red pueda arrancar de forma conforme
# sed -i 's|"java/ColorControlManager.cpp",|# "java/ColorControlManager.cpp",|g' "$GN_FILE"
# sed -i 's|"java/ColorControlManager.h",|# "java/ColorControlManager.h",|g' "$GN_FILE"
# sed -i 's|"java/DoorLockManager.cpp",|# "java/DoorLockManager.cpp",|g' "$GN_FILE"
# sed -i 's|"java/DoorLockManager.h",|# "java/DoorLockManager.h",|g' "$GN_FILE"
# sed -i 's|"java/ClusterChangeAttribute.cpp",|# "java/ClusterChangeAttribute.cpp",|g' "$GN_FILE"
# sed -i 's|"java/PowerSourceManager.cpp",|# "java/PowerSourceManager.cpp",|g' "$GN_FILE"
# sed -i 's|"java/PowerSourceManager.h",|# "java/PowerSourceManager.h",|g' "$GN_FILE"

# echo "INFRA: Reescribiendo el envoltorio JNI core limpio de llamadas obsoletas..."
# cat << 'EOF' > "$SRC_JNI"
# #include "DeviceApp-JNI.h"
# #include "AppImpl.h"
# #include "JNIDACProvider.h"
# #include "OnOffManager.h"
# #include "credentials/DeviceAttestationCredsProvider.h"
# #include <app/server/java/AndroidAppServerWrapper.h>
# #include <credentials/examples/DeviceAttestationCredsExample.h>
# #include <app/util/af-types.h> // 🔑 CRÍTICO: Define EmberAfDeviceType
# #include <jni.h>
# #include <lib/core/CHIPError.h>
# #include <lib/support/CHIPJNIError.h>
# #include <lib/support/JniReferences.h>

# using namespace chip;

# #define JNI_METHOD(RETURN, METHOD_NAME) \
#     extern "C" JNIEXPORT RETURN JNICALL Java_com_matter_virtual_device_app_DeviceApp_##METHOD_NAME

# EmberAfDeviceType gDeviceTypeIds[] = { { 0, 1 } };
# DeviceAppJNI DeviceAppJNI::sInstance;

# void DeviceAppJNI::InitializeWithObjects(jobject app) {
#     JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
#     if (env != nullptr) { mDeviceAppObject.Init(app); }
# }
# void DeviceAppJNI::PostClusterInit(int clusterId, int endpoint) {}
# void DeviceAppJNI::PostEvent(int event) {}

# jint JNI_OnLoad(JavaVM * jvm, void * reserved) { return AndroidAppServerJNI_OnLoad(jvm, reserved); }
# void JNI_OnUnload(JavaVM * jvm, void * reserved) { AndroidAppServerJNI_OnUnload(jvm, reserved); }

# JNI_METHOD(void, nativeInit)(JNIEnv *, jobject app) { DeviceAppJNIMgr().InitializeWithObjects(app); }
# JNI_METHOD(void, preServerInit)(JNIEnv *, jobject app) { PreServerInit(); }
# JNI_METHOD(void, postServerInit)(JNIEnv *, jobject app, jint deviceTypeId) {
#     gDeviceTypeIds[0].deviceId = static_cast<uint16_t>(deviceTypeId);
# }
# JNI_METHOD(void, setDACProvider)(JNIEnv *, jobject, jobject provider) {
#     if (!chip::Credentials::IsDeviceAttestationCredentialsProviderSet()) {
#         chip::Credentials::SetDeviceAttestationCredentialsProvider(chip::Credentials::Examples::GetExampleDACProvider());
#     }
# }
# JNI_METHOD(void, setOnOffManager)(JNIEnv *, jobject, jint endpoint, jobject manager) { OnOffManager::NewManager(endpoint, manager); }
# JNI_METHOD(jboolean, setOnOff)(JNIEnv *, jobject, jint endpoint, jboolean value) { return true; }

# // STUBS DE ENLACE DINÁMICO EN VACÍO
# JNI_METHOD(void, setPowerSourceManager)(JNIEnv *, jobject, jint ep, jobject m) {}
# JNI_METHOD(jboolean, setBatPercentRemaining)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(void, setColorControlManager)(JNIEnv *, jobject, jint ep, jobject m) {}
# JNI_METHOD(void, setDoorLockManager)(JNIEnv *, jobject, jint ep, jobject m) {}
# JNI_METHOD(jboolean, setLockType)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setLockState)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setActuatorEnabled)(JNIEnv *, jobject, jint ep, jboolean v) { return true; }
# JNI_METHOD(jboolean, setAutoRelockTime)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setOperatingMode)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setSupportedOperatingModes)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, sendLockAlarmEvent)(JNIEnv *, jobject, jint ep) { return true; }
# EOF

# echo "INFRA: Invocando la CLI de ZAP para compilar el nuevo Data Model limpio..."
# ./scripts/tools/zap/generate.py "$ZAP_FILE"




########## COMPILO LA APP y Funciona el Emparejamiento con Alexa v4 (version minimalista = la de node.js <<----------------
# # =========================================================================
# # 🏗️ PIPELINE INTEGRAL: FILTRADO PYTHON .ZAP + DESACOPLAMIENTO DE FUENTES C++
# # =========================================================================
# GN_FILE="examples/virtual-device-app/android/BUILD.gn"
# SRC_JNI="examples/virtual-device-app/android/java/DeviceApp-JNI.cpp"
# ZAP_FILE="examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"

# echo "INFRA: Creando buffers de respaldo temporales para Git..."
# cp "$GN_FILE" "${GN_FILE}.bak"
# cp "$SRC_JNI" "${SRC_JNI}.bak"
# cp "$ZAP_FILE" "${ZAP_FILE}.bak"

# # Disparador de seguridad: Si la compilación falla, se restaura el estado original de Git
# trap 'echo "🚨 Revertiendo parches de fuentes nativos..."; mv "${ZAP_FILE}.bak" "$ZAP_FILE" || true; mv "${SRC_JNI}.bak" "$SRC_JNI" || true; mv "${GN_FILE}.bak" "$GN_FILE" || true' ERR

# echo "INFRA: Filtrando el .zap original en vuelo para conservar la conformidad de comandos y atributos..."
# python3 - << 'EOF'
# import json

# zap_path = "examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"

# # 1. Cargar el JSON original del repositorio con todos sus atributos y comandos mandatorios
# with open(zap_path, 'r') as f:
#     data = json.load(f)

# # 2. Mutar el Endpoint 1 para que sea una Luz On/Off (0x0100 -> 256) idéntica a matter.js
# for endpoint_type in data.get("endpointTypes", []):
#     if endpoint_type.get("id") == 2 or endpoint_type.get("name") == "MA-videoplayer":
#         endpoint_type["name"] = "MA-onofflight"
#         endpoint_type["deviceTypeCode"] = 256
#         endpoint_type["deviceTypeName"] = "MA-onofflight"
        
#         if "deviceTypeRef" in endpoint_type:
#             endpoint_type["deviceTypeRef"]["code"] = 256
#             endpoint_type["deviceTypeRef"]["label"] = "MA-onofflight"
#             endpoint_type["deviceTypeRef"]["name"] = "MA-onofflight"
            
#         if "deviceTypes" in endpoint_type:
#             for dt in endpoint_type["deviceTypes"]:
#                 dt["code"] = 256
#                 dt["label"] = "MA-onofflight"
#                 dt["name"] = "MA-onofflight"
                
#         if "deviceIdentifiers" in endpoint_type:
#             endpoint_type["deviceIdentifiers"] = [256]

#         # 3. LISTA BLANCA ESTRICTA (Clon exacto de OnOffLightDevice en matter.js)
#         # Mantiene únicamente:
#         #   - 3  (0x0003): Identify
#         #   - 4  (0x0004): Groups
#         #   - 6  (0x0006): On/Off
#         #   - 29 (0x001D): Descriptor
#         # Elimina: Power Source Config (47), Scenes (98), Door Lock (257) y Color Control (768)
#         original_clusters = endpoint_type.get("clusters", [])
#         filtered_clusters = [
#             c for c in original_clusters 
#             if c.get("code") in [3, 4, 6, 29]
#         ]
#         endpoint_type["clusters"] = filtered_clusters

# # 4. Actualizar el mapeo en el array de instanciación de los Endpoints
# for ep in data.get("endpoints", []):
#     if ep.get("endpointId") == 1 or ep.get("endpointTypeName") == "MA-videoplayer":
#         ep["endpointTypeName"] = "MA-onofflight"

# # 5. Guardar el archivo .zap purgado listo para generar el código C++
# with open(zap_path, 'w') as f:
#     json.dump(data, f, indent=2)

# print("✅ INFRA PYTHON: Archivo .zap purgado con lista blanca [3, 4, 6, 29] (Clon exacto de matter.js).")
# EOF

# echo "INFRA: Purgando UNICAMENTE los archivos que causaban errores de compilación en el BUILD.gn..."
# # Mantenemos AppImpl.cpp activo para que el servidor de red pueda arrancar de forma conforme
# sed -i 's|"java/ColorControlManager.cpp",|# "java/ColorControlManager.cpp",|g' "$GN_FILE"
# sed -i 's|"java/ColorControlManager.h",|# "java/ColorControlManager.h",|g' "$GN_FILE"
# sed -i 's|"java/DoorLockManager.cpp",|# "java/DoorLockManager.cpp",|g' "$GN_FILE"
# sed -i 's|"java/DoorLockManager.h",|# "java/DoorLockManager.h",|g' "$GN_FILE"
# sed -i 's|"java/ClusterChangeAttribute.cpp",|# "java/ClusterChangeAttribute.cpp",|g' "$GN_FILE"
# sed -i 's|"java/PowerSourceManager.cpp",|# "java/PowerSourceManager.cpp",|g' "$GN_FILE"
# sed -i 's|"java/PowerSourceManager.h",|# "java/PowerSourceManager.h",|g' "$GN_FILE"

# echo "INFRA: Reescribiendo el envoltorio JNI core limpio de llamadas obsoletas..."
# cat << 'EOF' > "$SRC_JNI"
# #include "DeviceApp-JNI.h"
# #include "AppImpl.h"
# #include "JNIDACProvider.h"
# #include "OnOffManager.h"
# #include "credentials/DeviceAttestationCredsProvider.h"
# #include <app/server/java/AndroidAppServerWrapper.h>
# #include <credentials/examples/DeviceAttestationCredsExample.h>
# #include <app/util/af-types.h> // 🔑 CRÍTICO: Define EmberAfDeviceType
# #include <jni.h>
# #include <lib/core/CHIPError.h>
# #include <lib/support/CHIPJNIError.h>
# #include <lib/support/JniReferences.h>

# using namespace chip;

# #define JNI_METHOD(RETURN, METHOD_NAME) \
#     extern "C" JNIEXPORT RETURN JNICALL Java_com_matter_virtual_device_app_DeviceApp_##METHOD_NAME

# EmberAfDeviceType gDeviceTypeIds[] = { { 0, 1 } };
# DeviceAppJNI DeviceAppJNI::sInstance;

# void DeviceAppJNI::InitializeWithObjects(jobject app) {
#     JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
#     if (env != nullptr) { mDeviceAppObject.Init(app); }
# }
# void DeviceAppJNI::PostClusterInit(int clusterId, int endpoint) {}
# void DeviceAppJNI::PostEvent(int event) {}

# jint JNI_OnLoad(JavaVM * jvm, void * reserved) { return AndroidAppServerJNI_OnLoad(jvm, reserved); }
# void JNI_OnUnload(JavaVM * jvm, void * reserved) { AndroidAppServerJNI_OnUnload(jvm, reserved); }

# JNI_METHOD(void, nativeInit)(JNIEnv *, jobject app) { DeviceAppJNIMgr().InitializeWithObjects(app); }
# JNI_METHOD(void, preServerInit)(JNIEnv *, jobject app) { PreServerInit(); }
# JNI_METHOD(void, postServerInit)(JNIEnv *, jobject app, jint deviceTypeId) {
#     gDeviceTypeIds[0].deviceId = static_cast<uint16_t>(deviceTypeId);
# }
# JNI_METHOD(void, setDACProvider)(JNIEnv *, jobject, jobject provider) {
#     if (!chip::Credentials::IsDeviceAttestationCredentialsProviderSet()) {
#         chip::Credentials::SetDeviceAttestationCredentialsProvider(chip::Credentials::Examples::GetExampleDACProvider());
#     }
# }
# JNI_METHOD(void, setOnOffManager)(JNIEnv *, jobject, jint endpoint, jobject manager) { OnOffManager::NewManager(endpoint, manager); }
# JNI_METHOD(jboolean, setOnOff)(JNIEnv *, jobject, jint endpoint, jboolean value) { return true; }

# // STUBS DE ENLACE DINÁMICO EN VACÍO
# JNI_METHOD(void, setPowerSourceManager)(JNIEnv *, jobject, jint ep, jobject m) {}
# JNI_METHOD(jboolean, setBatPercentRemaining)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(void, setColorControlManager)(JNIEnv *, jobject, jint ep, jobject m) {}
# JNI_METHOD(void, setDoorLockManager)(JNIEnv *, jobject, jint ep, jobject m) {}
# JNI_METHOD(jboolean, setLockType)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setLockState)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setActuatorEnabled)(JNIEnv *, jobject, jint ep, jboolean v) { return true; }
# JNI_METHOD(jboolean, setAutoRelockTime)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setOperatingMode)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, setSupportedOperatingModes)(JNIEnv *, jobject, jint ep, jint v) { return true; }
# JNI_METHOD(jboolean, sendLockAlarmEvent)(JNIEnv *, jobject, jint ep) { return true; }
# EOF

# echo "INFRA: Invocando la CLI de ZAP para compilar el nuevo Data Model limpio..."
# ./scripts/tools/zap/generate.py "$ZAP_FILE"



########## COMPILO LA APP y Funciona el Emparejamiento con Alexa v5 <<----------------
# =========================================================================
# 🏗️ PIPELINE INTEGRAL: FILTRADO PYTHON .ZAP + DESACOPLAMIENTO DE FUENTES C++
# =========================================================================
GN_FILE="examples/virtual-device-app/android/BUILD.gn"
SRC_JNI="examples/virtual-device-app/android/java/DeviceApp-JNI.cpp"
ZAP_FILE="examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"

echo "INFRA: Creando buffers de respaldo temporales para Git..."
cp "$GN_FILE" "${GN_FILE}.bak"
cp "$SRC_JNI" "${SRC_JNI}.bak"
cp "$ZAP_FILE" "${ZAP_FILE}.bak"

# Disparador de seguridad: Si la compilación falla, se restaura el estado original de Git
trap 'echo "🚨 Revertiendo parches de fuentes nativos..."; mv "${ZAP_FILE}.bak" "$ZAP_FILE" || true; mv "${SRC_JNI}.bak" "$SRC_JNI" || true; mv "${GN_FILE}.bak" "$GN_FILE" || true' ERR

echo "INFRA: Filtrando el .zap original en vuelo para conservar la conformidad de comandos y atributos..."
python3 - << 'EOF'
import json

zap_path = "examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"

# 1. Cargar el JSON original del repositorio con todos sus atributos y comandos mandatorios
with open(zap_path, 'r') as f:
    data = json.load(f)

# 2. Mutar el Endpoint 1 para que sea una Luz On/Off (0x0100 -> 256) idéntica a matter.js
for endpoint_type in data.get("endpointTypes", []):
    if endpoint_type.get("id") == 2 or endpoint_type.get("name") == "MA-videoplayer":
        endpoint_type["name"] = "MA-onofflight"
        endpoint_type["deviceTypeCode"] = 256
        endpoint_type["deviceTypeName"] = "MA-onofflight"
        
        if "deviceTypeRef" in endpoint_type:
            endpoint_type["deviceTypeRef"]["code"] = 256
            endpoint_type["deviceTypeRef"]["label"] = "MA-onofflight"
            endpoint_type["deviceTypeRef"]["name"] = "MA-onofflight"
            
        if "deviceTypes" in endpoint_type:
            for dt in endpoint_type["deviceTypes"]:
                dt["code"] = 256
                dt["label"] = "MA-onofflight"
                dt["name"] = "MA-onofflight"
                
        if "deviceIdentifiers" in endpoint_type:
            endpoint_type["deviceIdentifiers"] = [256]

        # 3. LISTA BLANCA ESTRICTA (Clon exacto de OnOffLightDevice en matter.js)
        # Mantiene únicamente:
        #   - 3  (0x0003): Identify
        #   - 4  (0x0004): Groups
        #   - 6  (0x0006): On/Off
        #   - 29 (0x001D): Descriptor
        # Elimina: Power Source Config (47), Scenes (98), Door Lock (257) y Color Control (768)
        original_clusters = endpoint_type.get("clusters", [])
        filtered_clusters = [
            c for c in original_clusters 
            if c.get("code") in [3, 4, 6, 29]
        ]
        endpoint_type["clusters"] = filtered_clusters

# 4. Actualizar el mapeo en el array de instanciación de los Endpoints
for ep in data.get("endpoints", []):
    if ep.get("endpointId") == 1 or ep.get("endpointTypeName") == "MA-videoplayer":
        ep["endpointTypeName"] = "MA-onofflight"

# 5. Guardar el archivo .zap purgado listo para generar el código C++
with open(zap_path, 'w') as f:
    json.dump(data, f, indent=2)

print("✅ INFRA PYTHON: Archivo .zap purgado con lista blanca [3, 4, 6, 29] (Clon exacto de matter.js).")
EOF

echo "INFRA: Purgando UNICAMENTE los archivos que causaban errores de compilación en el BUILD.gn..."
# Mantenemos AppImpl.cpp activo para que el servidor de red pueda arrancar de forma conforme
sed -i 's|"java/ColorControlManager.cpp",|# "java/ColorControlManager.cpp",|g' "$GN_FILE"
sed -i 's|"java/ColorControlManager.h",|# "java/ColorControlManager.h",|g' "$GN_FILE"
sed -i 's|"java/DoorLockManager.cpp",|# "java/DoorLockManager.cpp",|g' "$GN_FILE"
sed -i 's|"java/DoorLockManager.h",|# "java/DoorLockManager.h",|g' "$GN_FILE"
sed -i 's|"java/ClusterChangeAttribute.cpp",|# "java/ClusterChangeAttribute.cpp",|g' "$GN_FILE"
sed -i 's|"java/PowerSourceManager.cpp",|# "java/PowerSourceManager.cpp",|g' "$GN_FILE"
sed -i 's|"java/PowerSourceManager.h",|# "java/PowerSourceManager.h",|g' "$GN_FILE"

echo "INFRA: Reescribiendo DeviceApp-JNI.cpp con notificaciones de eventos restauradas..."
cat << 'EOF' > "$SRC_JNI"
#include "DeviceApp-JNI.h"
#include "AppImpl.h"
#include "JNIDACProvider.h"
#include "OnOffManager.h"
#include "credentials/DeviceAttestationCredsProvider.h"
#include <app/server/java/AndroidAppServerWrapper.h>
#include <credentials/examples/DeviceAttestationCredsExample.h>
#include <app/util/af-types.h>
#include <jni.h>
#include <lib/core/CHIPError.h>
#include <lib/support/CHIPJNIError.h>
#include <lib/support/JniReferences.h>

using namespace chip;

#define JNI_METHOD(RETURN, METHOD_NAME) \
    extern "C" JNIEXPORT RETURN JNICALL Java_com_matter_virtual_device_app_DeviceApp_##METHOD_NAME

EmberAfDeviceType gDeviceTypeIds[] = { { 0, 1 } };
DeviceAppJNI DeviceAppJNI::sInstance;

// 1. RESTAURADO: Obtiene las referencias a los métodos Java de notificación
void DeviceAppJNI::InitializeWithObjects(jobject app)
{
    JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
    VerifyOrReturn(env != nullptr, ChipLogError(Zcl, "Failed to GetEnvForCurrentThread"));
    VerifyOrReturn(mDeviceAppObject.Init(app) == CHIP_NO_ERROR, ChipLogError(Zcl, "Failed to init mDeviceAppObject"));

    jclass managerClass = env->GetObjectClass(app);
    VerifyOrReturn(managerClass != nullptr, ChipLogError(Zcl, "Failed to get DeviceApp Java class"));

    mPostClusterInitMethod = env->GetMethodID(managerClass, "postClusterInit", "(JI)V");
    if (mPostClusterInitMethod == nullptr) { env->ExceptionClear(); }

    mPostEventMethod = env->GetMethodID(managerClass, "postEvent", "(J)V");
    if (mPostEventMethod == nullptr) { env->ExceptionClear(); }
}

// 2. RESTAURADO: Avisa a Java cuando el clúster OnOff inicializa
void DeviceAppJNI::PostClusterInit(int clusterId, int endpoint)
{
    JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
    VerifyOrReturn(env != nullptr && mDeviceAppObject.HasValidObjectRef() && mPostClusterInitMethod != nullptr);

    env->CallVoidMethod(mDeviceAppObject.ObjectRef(), mPostClusterInitMethod, static_cast<jlong>(clusterId), static_cast<jint>(endpoint));
    if (env->ExceptionCheck()) { env->ExceptionClear(); }
}

// 3. RESTAURADO: Avisa a Java cuando termina el comisionamiento (kCommissioningComplete)
void DeviceAppJNI::PostEvent(int event)
{
    JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
    VerifyOrReturn(env != nullptr && mDeviceAppObject.HasValidObjectRef() && mPostEventMethod != nullptr);

    env->CallVoidMethod(mDeviceAppObject.ObjectRef(), mPostEventMethod, static_cast<jlong>(event));
    if (env->ExceptionCheck()) { env->ExceptionClear(); }
}

jint JNI_OnLoad(JavaVM * jvm, void * reserved) { return AndroidAppServerJNI_OnLoad(jvm, reserved); }
void JNI_OnUnload(JavaVM * jvm, void * reserved) { AndroidAppServerJNI_OnUnload(jvm, reserved); }

JNI_METHOD(void, nativeInit)(JNIEnv *, jobject app) { DeviceAppJNIMgr().InitializeWithObjects(app); }
JNI_METHOD(void, preServerInit)(JNIEnv *, jobject app) { PreServerInit(); }
JNI_METHOD(void, postServerInit)(JNIEnv *, jobject app, jint deviceTypeId) {
    gDeviceTypeIds.deviceId = static_cast<uint16_t>(deviceTypeId);
    emberAfSetDeviceTypeList(1, Span<const EmberAfDeviceType>(gDeviceTypeIds));
}
JNI_METHOD(void, setDACProvider)(JNIEnv *, jobject, jobject provider) {
    if (!chip::Credentials::IsDeviceAttestationCredentialsProviderSet()) {
        chip::Credentials::SetDeviceAttestationCredentialsProvider(chip::Credentials::Examples::GetExampleDACProvider());
    }
}
JNI_METHOD(void, setOnOffManager)(JNIEnv *, jobject, jint endpoint, jobject manager) { OnOffManager::NewManager(endpoint, manager); }
JNI_METHOD(jboolean, setOnOff)(JNIEnv *, jobject, jint endpoint, jboolean value) {
    return DeviceLayer::SystemLayer().ScheduleLambda([endpoint, value] { OnOffManager::SetOnOff(endpoint, value); }) == CHIP_NO_ERROR;
}

// STUBS DE ENLACE EN VACÍO PARA CLÚSTERES ELIMINADOS
JNI_METHOD(void, setPowerSourceManager)(JNIEnv *, jobject, jint ep, jobject m) {}
JNI_METHOD(jboolean, setBatPercentRemaining)(JNIEnv *, jobject, jint ep, jint v) { return true; }
JNI_METHOD(void, setColorControlManager)(JNIEnv *, jobject, jint ep, jobject m) {}
JNI_METHOD(void, setDoorLockManager)(JNIEnv *, jobject, jint ep, jobject m) {}
JNI_METHOD(jboolean, setLockType)(JNIEnv *, jobject, jint ep, jint v) { return true; }
JNI_METHOD(jboolean, setLockState)(JNIEnv *, jobject, jint ep, jint v) { return true; }
JNI_METHOD(jboolean, setActuatorEnabled)(JNIEnv *, jobject, jint ep, jboolean v) { return true; }
JNI_METHOD(jboolean, setAutoRelockTime)(JNIEnv *, jobject, jint ep, jint v) { return true; }
JNI_METHOD(jboolean, setOperatingMode)(JNIEnv *, jobject, jint ep, jint v) { return true; }
JNI_METHOD(jboolean, setSupportedOperatingModes)(JNIEnv *, jobject, jint ep, jint v) { return true; }
JNI_METHOD(jboolean, sendLockAlarmEvent)(JNIEnv *, jobject, jint ep) { return true; }
EOF


echo "INFRA: Invocando la CLI de ZAP para compilar el nuevo Data Model limpio..."
./scripts/tools/zap/generate.py "$ZAP_FILE"

#######################################################################################################################################


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


###############################################################################################################

echo "INFRA: Compilación completada con éxito. Restaurando los archivos .zap y cpp's originales de Git..."
mv "${ZAP_FILE}.bak" "$ZAP_FILE" || true

mv "${GN_FILE}.bak" "$GN_FILE" || true
mv "${SRC_JNI}.bak" "$SRC_JNI" || true


