#!/bin/bash

# =========================================================================
# SCRIPT DINÁMICO DE COMPILACIÓN CON ASIGNACIÓN DE ENTORNO AISLADO DE DISCO
# =========================================================================

# Sanitizar saltos de línea de Windows (CRLF a LF) de forma automática e inmediata
sed -i 's/\r$//' "$0" || true

set -e # Detiene el script inmediatamente si ocurre un error inesperado

# 🐙 EXTRACTOR DE ENTORNO DE GITHUB ACTIONS
if [ -n "$GITHUB_ENV" ] && [ -f "$GITHUB_ENV" ]; then
    echo "⚙️ INFRA: Sincronizando bloque completo de variables \$GITHUB_ENV (exports)..."
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ ! -z "$line" && "$line" != "#"* ]]; then
            export "$line"
        fi
    done < "$GITHUB_ENV"
fi

# 🔥 ANULACIÓN CRÍTICA ANTI-CRASH
unset PW_ZAP_CIPD_RELEASE
export -n PW_ZAP_CIPD_RELEASE 2>/dev/null || true

# ⚙️ CONTROL MANUAL DE CACHÉ LOCAL
# Si la variable de entorno FORCE_CLEAR_CACHE existe y tiene un valor, usa ese valor. 
# Si está vacía, no está definida o es nula, usa el valor de reemplazo, false
FORCE_CLEAR_CACHE="${FORCE_CLEAR_CACHE:-false}"

# =========================================================================
# ☕ FORZADO DINÁMICO DE JDK 11 USANDO LAS VARIABLES DEL RUNNER
# 🚀 [MODIFICADO] -> Inicializa JAVA_HOME a partir de JAVA_HOME_11_X64
#                    para garantizar compatibilidad total con KAPT/Kotlin.
# =========================================================================
echo "INFRA: Configurando el entorno del sistema para usar JDK 11 de forma dinámica..."

if [ -n "$JAVA_HOME_11_X64" ] && [ -d "$JAVA_HOME_11_X64" ]; then
    # Asignamos la variable raíz a partir del puntero oficial de GitHub
    export JAVA_HOME="$JAVA_HOME_11_X64"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    echo "  ↳ ✅ JAVA_HOME asignado con éxito desde JAVA_HOME_11_X64."
    echo "  ↳ Versión de Java activa en el PATH: $(java -version 2>&1 | head -n 1)"
    
    # Exportamos los cambios al entorno persistente del pipeline de GitHub
    if [ -n "$GITHUB_ENV" ] && [ -f "$GITHUB_ENV" ]; then
        echo "JAVA_HOME=$JAVA_HOME" >> "$GITHUB_ENV"
        echo "PATH=$PATH" >> "$GITHUB_ENV"
    fi
else
    echo "⚠️ ADVERTENCIA CRÍTICA: La variable JAVA_HOME_11_X64 está vacía o su ruta no existe."
    echo "  ↳ Se mantendrá el Java del sistema actual: $(java -version 2>&1 | head -n 1)"
fi
# =========================================================================




echo "INFRA: Levantando escudo interceptor de comandos para desarmar sdkmanager..."

# 1. Limpiamos cualquier rastro de modificaciones previas en el código fuente
git checkout -- scripts/build/runner/shell.py || true
git checkout -- scripts/build/builders/android.py || true

# # 2. Creamos una carpeta binaria privada con prioridad absoluta en el PATH
# BIN_TRAP_DIR="$HOME/.infra_bin_trap"
# mkdir -p "$BIN_TRAP_DIR"

# # 3. Creamos un ejecutable 'bash' falso que actuará como filtro del sistema
# cat << 'EOF' > "$BIN_TRAP_DIR/bash"
# #!/bin/env bash
# echo "$@"
# echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# # Si el comando invocado intenta usar sdkmanager, respondemos éxito instantáneo (exit 0)
# if [[ "$*" == *"sdkmanager"* ]]; then
#     echo "[INFRA INTERCEPTOR]: sdkmanager bloqueado de forma segura. Retornando exit 0."
#     exit 0
# fi
# # Para cualquier otro comando de compilación, actuamos de puente transparente usando el bash real

# exec /bin/bash "$@"
# EOF

# chmod +x "$BIN_TRAP_DIR/bash"

# # 4. Inyectamos la carpeta al inicio del PATH para engañar a Python y Pigweed
# export PATH="$BIN_TRAP_DIR:$PATH"
# echo "  ✅ PATH alterado con éxito. Prioridad asignada a: $(which bash)"
# # ======







# echo ""
# if [ -f "$ANDROID_PY_FILE" ]; then
#     if [ -s "$ANDROID_PY_FILE" ]; then
#         cat "$ANDROID_PY_FILE"
#     else
#         echo "⚠️ ADVERTENCIA: El archivo existe en el disco, pero está completamente VACÍO."
#     fi
# else
#     echo "⚠️ ADVERTENCIA: El archivo no existe en la ruta especificada."
# fi

echo "========================================================================="
echo ""


# # =========================================================================
# # 🧹 PURGA Y KILL DE PROCESOS DEMONIOS DE GRADLE HUÉRFANOS
# # 🚀 Evita que Gradle reutilice procesos antiguos sin los nuevos flags de memoria
# # =========================================================================
# echo "INFRA: Purgando hilos y demonios Gradle en ejecución en la memoria RAM..."
# if [ -f "examples/virtual-device-app/android/App/gradlew" ]; then
#     ./examples/virtual-device-app/android/App/gradlew --stop || true
# fi
# if [ -f "third_party/android_deps/gradlew" ]; then
#     ./third_party/android_deps/gradlew --stop || true
# fi
# pkill -f 'gradle' || true  # 🚀 [AÑADIDO] -> Matanza total a nivel de kernel de la máquina virtual
# echo "  ✅ Memoria RAM del Runner purgada. Iniciando entorno limpio..."
# # =========================================================================


# =========================================================================
#//////////////////////////////////////////////////////////////////////////
# =========================================================================

# =========================================================================
# 🛡️ BLINDAJE GLOBAL: STACK & GRADLE COMPILER (MEMORY FORCE + INIT SCRIPT)
# =========================================================================
echo "INFRA: Protejemos la compilación incrementando la memoria (STACK & METASPACE DE 8MB)..."

# 1. Configurar directivas físicas en el archivo global gradle.properties del Runner
# Esto obliga al demonio raíz y a sus subprocesos KAPT a levantar con un Stack ampliado
mkdir -p ~/.gradle
touch ~/.gradle/gradle.properties
sed -i '/org.gradle.jvmargs/d' ~/.gradle/gradle.properties || true

# Traducimos ThreadStackSize=8192 a -Xss8m (8 Megabytes por hilo de ejecución)
# Incrementamos el montón base a 4 Gigabytes (-Xmx4g) y Metaspace a 1024m
echo "org.gradle.jvmargs=-Xmx4g -Xms2g -Xss8m -XX:MaxMetaspaceSize=1024m -Dfile.encoding=UTF-8 -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files" >> ~/.gradle/gradle.properties

echo "  ✅ Propiedades de memoria global JVM asignadas en ~/.gradle/gradle.properties"

# 2. Generar el script init.gradle para interceptar las tareas de Kotlin
echo "🛡️ INFRA: Injected Global Resolution Shield to force Kotlin 1.8.10 mapping..."
mkdir -p ~/.gradle
cat << 'EOF' > ~/.gradle/init.gradle
allprojects {
    // Obliga a todos los submódulos a usar las librerías de la versión 1.8.10
    configurations.all {
        resolutionStrategy {
            eachDependency { DependencyResolveDetails details ->
                if (details.requested.group == 'org.jetbrains.kotlin') {
                    details.useVersion '1.8.10'
                }
            }
        }
    }

    afterEvaluate { project ->
        // Force skip-metadata flags on every Kotlin task
        project.tasks.matching { it.class.name.contains("KotlinCompile") }.configureEach { task ->
            try {
                if (task.hasProperty('kotlinOptions')) {
                    task.kotlinOptions {
                        freeCompilerArgs += ["-Xskip-metadata-version-check", "-Xallow-no-source-files"]
                    }
                }
            } catch (Exception e) {}
        }

        // Allocate strict memory heaps to KAPT workers to prevent background crashes
        // Forzar la herencia de los argumentos de la JVM en el entorno de KAPT
        project.tasks.matching { it.name.contains("kapt") || it.class.name.contains("Kapt") }.configureEach { task ->
            try {
                if (task.hasProperty('kaptProcessJvmArgs')) {
                    // 🚀 Forzamos a KAPT a asimilar los 8MB de pila para romper la recursión de Matter
                    task.kaptProcessJvmArgs += ["-Xss8m", "-Xmx4g", "-XX:MaxMetaspaceSize=1024m"]
                }
            } catch (Exception e) {}
        }
    }
}
EOF
echo "  ✅ Global master interceptor saved to ~/.gradle/init.gradle"


# 🚀 Actualizamos también las variables de entorno de la sesión para procesos hijos Python
#export GRADLE_OPTS="-Xmx4g -Xms2g -Xss8m -XX:MaxMetaspaceSize=1024m -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files"
export GRADLE_OPTS="-Xmx4g -Xms2g -Xss8m -XX:MaxMetaspaceSize=1024m -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files -Dorg.gradle.logging.level=debug"



# export KOTLIN_COMPILER_ARGS="-nowarn -warn:0 -Xskip-metadata-version-check"
# export KOTLINC_ARGS="-nowarn -Xskip-metadata-version-check"
echo "INFRA: Configurando inhibidores de error y metadatos en el motor de Kotlin..."
export KOTLIN_COMPILER_ARGS="-nowarn -warn:0 -Xskip-metadata-version-check -Xallow-no-source-files"
export KOTLINC_ARGS="-nowarn"

#export KAPT_ARGS="--stacktrace --info"
# =========================================================================


# =========================================================================
#//////////////////////////////////////////////////////////////////////////
# =========================================================================




echo "========================================================================="
echo "🔍 DIAGNÓSTICO AVANZADO DE ENTORNO EN EL RUNNER (HOST VIRTUAL)"
echo "========================================================================="
echo "🐙 VARIABLES GLOBALES DE GITHUB:"
echo "-------------------------------------------------------------------------"
echo "  ↳ GITHUB_WORKSPACE : ${GITHUB_WORKSPACE:-'❌ NO EXPORTADA / VACÍA'}"
echo "  ↳ GITHUB_REPOSITORY: ${GITHUB_REPOSITORY:-'❌ NO EXPORTADA'}"
echo "  ↳ GITHUB_REF_NAME  : ${GITHUB_REF_NAME:-'❌ NO EXPORTADA'}"
echo "  ↳ GITHUB_SHA       : ${GITHUB_SHA:-'❌ NO EXPORTADA'}"
echo "  ↳ GITHUB_RUN_ID    : ${GITHUB_RUN_ID:-'❌ NO EXPORTADA'}"
echo ""
echo "☕ VARIANTES DE ENTORNO JAVA (JDK MAP):"
echo "-------------------------------------------------------------------------"
echo "  ↳ CURRENT JAVA_HOME: ${JAVA_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ JAVA_HOME_11_X64 : ${JAVA_HOME_11_X64:-'❌ NO DETECTADA (¿No instalada?)'}"
echo "  ↳ JAVA_HOME_17_X64 : ${JAVA_HOME_17_X64:-'❌ NO DETECTADA (¿No instalada?)'}"
echo ""

if [ -n "$JAVA_HOME_11_X64" ] && [ -x "$JAVA_HOME_11_X64/bin/java" ]; then
    echo "    ↳ Versión Real en Java 11 SDK: $($JAVA_HOME_11_X64/bin/java -version 2>&1 | head -n 1)"
fi
if [ -n "$JAVA_HOME_17_X64" ] && [ -x "$JAVA_HOME_17_X64/bin/java" ]; then
    echo "    ↳ Versión Real en Java 17 SDK: $($JAVA_HOME_17_X64/bin/java -version 2>&1 | head -n 1)"
fi

echo ""
echo "📂 VARIABLES DE DESARROLLO (ANDROID / MATTER):"
echo "-------------------------------------------------------------------------"
echo "  ↳ ANDROID_HOME     : ${ANDROID_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ ANDROID_NDK_ROOT : ${ANDROID_NDK_ROOT:-'❌ NO DETECTADA'}"
echo "  ↳ ANDROID_NDK_HOME : ${ANDROID_NDK_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ ZAP_INSTALL_PATH : ${ZAP_INSTALL_PATH:-'❌ NO DETECTADA'}"
echo ""
echo "🛠️ BINARIOS Y VERSIONES REALES (EN PATH ACTIVO):"
echo "-------------------------------------------------------------------------"

if command -v java >/dev/null 2>&1; then
    echo "  ↳ Java CLI     : $(java -version 2>&1 | head -n 1)"
else
    echo "  ↳ Java CLI     : ❌ NO ENCONTRADO EN EL PATH"
fi

if command -v python3 >/dev/null 2>&1; then
    echo "  ↳ Python       : $(python3 --version 2>&1)"
else
    echo "  ↳ Python       : ❌ NO ENCONTRADO EN EL PATH"
fi

if command -v gn >/dev/null 2>&1; then
    echo "  ↳ GN Tool      : Encontrado en $(command -v gn) -> $(gn --version 2>/dev/null || echo 'GN disponible, pero ⚠️ no se localizó versión')"
else
    echo "  ↳ GN Tool      : ❌ No inicializado aún (⏳ Se activará tras Pigweed 'activate.sh')"
fi

if command -v zap-cli >/dev/null 2>&1; then
    echo "  ↳ ZAP CLI      : Encontrado en $(command -v zap-cli)"
else
    echo "  ↳ ZAP CLI      : ❌ NO ACCESIBLE (Verificar enlace simbólico)"
fi

CLANG_NDK="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
if [ -f "$CLANG_NDK" ]; then
    echo "  ↳ NDK Clang    : Encontrado ($($CLANG_NDK --version | head -n 1 | cut -d' ' -f1-4))"
else
    echo "  ↳ NDK Clang    : ❌ Binario del compilador no hallado en la ruta del NDK"
fi

echo ""
echo "📂 VARIABLES CUSTOM DE CONTROL:"
echo "-------------------------------------------------------------------------"
echo "  ↳ FORCE_CLEAR_CACHE: $FORCE_CLEAR_CACHE"
echo "========================================================================="

# 🧹 LIMPIEZA ATÓMICA DE CÓDIGO FUENTE
echo "INFRA: Limpiando parches de texto residuales del intento de compilación anterior..."
git reset --hard HEAD --quiet || true
git clean -fd --quiet || true

if [ "$FORCE_CLEAR_CACHE" = "true" ]; then
    echo "⚠️ INFRA: Flag 'clear_cache' detectado como TRUE. Destruyendo carpeta out/ de forma segura..."
    rm -rf out/
else
    echo "⚡ INFRA: Manteniendo carpeta 'out/' para permitir compilación incremental rápida."
fi

# ¡EL PARCHE CLAVE ANTI-CIPD DE CONFIGURACIÓN NEUTRALIZADA!
echo "INFRA: Neutralizando configuraciones JSON rígidas de CIPD para ZAP..."
if [ -f "scripts/setup/zap.json" ]; then
    echo '{"packages": []}' > scripts/setup/zap.json
fi
find . -name "zap.json" -exec sh -c 'echo "{\"packages\": []}" > "{}"' \;
echo "INFRA: Archivos zap.json vaciados con éxito. CIPD ignorará la descarga de red."

echo "INFRA: Parcheando dependencia crítica libgirepository en caliente..."
sudo apt-get update && sudo apt-get install -y libgirepository1.0-dev

# INICIALIZACIÓN DEL ENTORNO DE COMPILACIÓN DE MATTER
echo "INFRA: Inicializando el entorno virtual aislado de Pigweed..."
source scripts/activate.sh
echo ""

# Sincronización local de librerías nativas internas del SDK de Matter
echo "INFRA: Descargando pre-requisitos de dependencias de Android..."
python3 third_party/android_deps/set_up_android_deps.py
third_party/java_deps/set_up_java_deps.sh

# 🧹 LIMPIEZA DE WARNINGS ESTRICTOS (-Werror & -Xlint)
echo "INFRA: Se eliminan los flags Warning-Error de las plantillas .gn y .gni del código fuente Matter."
find . -name "BUILD.gn" -exec sed -i 's|"-Werror",||g' {} +
find . -name "BUILD.gn" -exec sed -i 's|"-Werror"||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Werror",||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Werror"||g' {} +

find . -name "BUILD.gn" -exec sed -i 's|"-Xlint:all",||g' {} +
find . -name "BUILD.gn" -exec sed -i 's|"-Xlint:all"||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Xlint:all",||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Xlint:all"||g' {} +

echo "INFRA: Se elimina el flag obsoleto 'MaxPermSize' de todo el árbol SDK Matter"
find . -name "gradle.properties" -exec sed -i 's|-XX:MaxPermSize=2048m||g' {} +

echo "INFRA: Inyectando inhibidores de error '-nowarn' en el motor de Pigweed..."
find . -name "kotlinc_runner.py" -exec sed -i "s|retcode = subprocess.check_call(kotlin_args + args.rest)|kotlin_args.append('-nowarn')\n    retcode = subprocess.check_call(kotlin_args + args.rest)|g" {} +
find . -name "kotlinc_runner.py" -exec sed -i "s|'-Werror'||g" {} +

# # 🔥 ASIGNACIÓN DE DISCO DE USUARIO PARA JAVA
# if [ -n "$MATTER_TARGET_JAVA_HOME" ]; then
#     echo "INFRA: Registrando asignación de JDK 11 en las directivas de usuario locales (~/.gradle/)..."
#     mkdir -p ~/.gradle
#     touch ~/.gradle/gradle.properties
#     sed -i '/org.gradle.java.home/d' ~/.gradle/gradle.properties || true
#     echo "org.gradle.java.home=$MATTER_TARGET_JAVA_HOME" >> ~/.gradle/gradle.properties
# else
#     echo "⚠️ ADVERTENCIA: Variable MATTER_TARGET_JAVA_HOME vacía. Se intentará usar JDK del sistema."
# fi

# 🛠️ REGENERAR LA ESTRUCTURA DE COMPILACIÓN GN
echo "INFRA: Sincronizando árbol estructural de mapas de GN..."
gn gen out/virtual-device-app \
  --args='target_os="android" target_cpu="arm" android_ndk_root="'$ANDROID_NDK_ROOT'" android_sdk_root="'$ANDROID_HOME'" chip_config_network_layer_ble=false treat_warnings_as_errors=false' \
  --root=examples/virtual-device-app/android/
  
find out/ -name "*.json" -exec sed -i 's|"-Werror",||g' {} +
echo ""



# =========================================================================
# 🔍 AUDITORÍA DE INFRAESTRUCTURA: UBICACIÓN Y VOLCADO DE CONFIGURACIÓN
# =========================================================================
echo "========================================================================="
echo "📂 DETERMINANDO UBICACIÓN REAL FÍSICA DE LOS FICHEROS GLOBALES:"
echo "========================================================================="

# 1. Resolver y mostrar las rutas absolutas reales en el disco del Runner
echo "  ↳ Ruta real de ~/.gradle/ : $(cd ~/.gradle && pwd)"
[ -f ~/.gradle/gradle.properties ] && echo "  ↳ Fichero gradle.properties: $(realpath ~/.gradle/gradle.properties)" || echo "  ↳ Fichero gradle.properties: ❌ NO EXISTE EN DISCO"
[ -f ~/.gradle/init.gradle ]       && echo "  ↳ Fichero init.gradle:       $(realpath ~/.gradle/init.gradle)"       || echo "  ↳ Fichero init.gradle:       ❌ NO EXISTE EN DISCO"
echo ""

echo "========================================================================="
echo "📄 VOLCADO DE CONTENIDO: ~/.gradle/gradle.properties"
echo "========================================================================="
if [ -f ~/.gradle/gradle.properties ]; then
    cat ~/.gradle/gradle.properties
else
    echo "⚠️ ADVERTENCIA: El archivo gradle.properties está vacío o no se ha creado."
fi
echo "========================================================================="
echo ""

echo "========================================================================="
echo "📄 VOLCADO DE CONTENIDO: ~/.gradle/init.gradle"
echo "========================================================================="
if [ -f ~/.gradle/init.gradle ]; then
    cat ~/.gradle/init.gradle
else
    echo "⚠️ ADVERTENCIA: El archivo init.gradle está vacío o no se ha creado."
fi
echo "========================================================================="



#ANDROID_PY_FILE="scripts/build/builders/android.py"
#ANDROID_PY_FILE="/home/runner/work/MatterTVApp/MatterTVApp/matter-sdk/scripts/build/builders/android.py"
ANDROID_PY_FILE="/home/runner/work/matter_virtual_device/matter_virtual_device/matter-sdk/scripts/build/builders/android.py"

if [ -f "$ANDROID_PY_FILE" ]; then
    echo "INFRA: Aplicando parche de última instancia sobre la línea de ejecución de sdkmanager..."
"yes | JAVA_HOME='"$JAVA_HOME_17_X64"' %s
    #sed -i 's@"yes | %s --licenses >/dev/null"@"yes | JAVA_HOME=/opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/17.0.20-1/x64 %s --licenses >/dev/null"@g' "$ANDROID_PY_FILE"
    #sed -i 's@"yes | %s --licenses >/dev/null"@"JAVA_HOME='"$JAVA_HOME_17_X64"' yes | %s --licenses "@g' "$ANDROID_PY_FILE"
    sed -i 's@"yes | %s --licenses >/dev/null"@"yes | JAVA_HOME='"$JAVA_HOME_17_X64"' %s --licenses >/dev/null"@g' "$ANDROID_PY_FILE"
    echo "  ✅ Parche crítico aplicado sobre los métodos _Execute."
fi
# =========================================================================

# 🚀 EJECUCIÓN DEL MÓDULO INTÉRPRETE DE COMPILACIÓN DE MATTER
echo "INFRA: Invocando script compilador nativo (Llamada Python a Gradle Wrapper)..."
./scripts/build/build_examples.py --target android-arm-virtual-device-app build
echo ""
/home/runner/work/matter_virtual_device/matter_virtual_device/matter-sdk/examples/virtual-device-app/android/App/gradlew \
  -p /home/runner/work/matter_virtual_device/matter_virtual_device/matter-sdk/examples/virtual-device-app/android/App/ \
  -PmatterBuildSrcDir=/home/runner/work/matter_virtual_device/matter_virtual_device/matter-sdk/out/android-arm-virtual-device-app \
  -PmatterSdkSourceBuild=false \
  -PbuildDir=/home/runner/work/matter_virtual_device/matter_virtual_device/matter-sdk/out/android-arm-virtual-device-app \
  assembleDebug \
  --debug \
  --stacktrace \
  --scan
# =============================================================================
# 📊 TELEMETRÍA AVANZADA: COMPARATIVA DE TÉCNICAS DE EXTRACCIÓN DE REQUISITOS
# =============================================================================
echo "INFRA: Descubrimiento de las carpetas de proyecto requeridas por la aplicación"
# 1. Definimos y creamos de forma segura la ruta destino mapeada en el upload-artifact del YAML
REPORT_TARGET_DIR="examples/virtual-device-app/android/App/app/build/outputs/reports"
mkdir -p "$REPORT_TARGET_DIR"

echo "  ========================================================================="
echo "  🔬 DESCUBRIR 1: ANALIZADOR DE DEPENDENCIAS DE GN (NINJA MAP)"
echo "  ========================================================================="
if [ -d "out" ]; then
    # Escaneamos los mapas .ninja.d, filtramos rutas relativas, limpiamos nombres de archivos
    # y ordenamos de forma única para obtener la huella dactilar exacta del compilador.
    find out/ -name "*.ninja.d" -exec cat {} + 2>/dev/null | \
    tr ' ' '\n' | \
    grep -v '^out/' | \
    grep '/' | \
    sed 's|/[^/]*$||' | \
    sort -u > "$REPORT_TARGET_DIR/carpetas_esenciales_gn.txt" || true

    echo "  🎯 Detectadas $(wc -l < "$REPORT_TARGET_DIR/carpetas_esenciales_gn.txt" 2>/dev/null || echo '0') carpetas críticas en el SDK Matter."
    echo   "📋 Report guardado en: $REPORT_TARGET_DIR/carpetas_esenciales_gn.txt"
    echo "  Top 20 carpetas indispensables leídas:"
    echo "-------------------------------------------------------------------------"
    head -n 20 "$REPORT_TARGET_DIR/carpetas_esenciales_gn.txt" | sed 's/^/  /' || echo "  ⚠️ Ninguna carpeta descubierta."
else
    echo "  ❌ Error: La carpeta out/ no existe. GN no generó mapa de compilación."
fi
echo "========================================================================="
echo ""

echo "  ==========================================================================================="
echo "  📂 DESCUBRIR 2: GIT STATUS: CARPETAS FUENTE DEL SDK MODIFICADAS POR PARCHEADO DE FICHEROS "
echo "  ==========================================================================================="
# Preguntamos a Git qué directorios contienen archivos modificados "al vuelo" por los sed de nuestra compilación
git status --porcelain 2>/dev/null | grep "M " | awk '{print $2}' | sed 's|/[^/]*$||' | sort -u > "$REPORT_TARGET_DIR/carpetas_git_modificadas.txt" || true

echo "  🎯 Detectadas $(wc -l < "$REPORT_TARGET_DIR/carpetas_git_modificadas.txt" 2>/dev/null || echo '0') carpetas parchadas por sed."
echo "  📋 Report guardado en: $REPORT_TARGET_DIR/carpetas_git_modificadas.txt"
echo "  Top 20 de carpetas modificadas por sed:"
echo "  -------------------------------------------------------------------------"
head -n 20 "$REPORT_TARGET_DIR/carpetas_git_modificadas.txt" | sed 's/^/  /' || echo "  ⚠️ Git no reporta archivos modificados."
echo "  ========================================================================="
echo ""


# =========================================================================
# 🚀 OPTIMIZACIÓN POST-COMPILACIÓN (LLVM-STRIP)
# =========================================================================
echo "========================================================================="
echo "INFRA: Compilación completada. Generando copias '_small' (LLVM-STRIP) para comparativa..."
echo "========================================================================="

## Usamos la ruta absoluta exacta basada en el Workspace real del host de GitHub
#JNI_TARGET_DIR="/home/runner/work/matter_virtual_device/Matter_Virtual_Device_CHIP/matter-sdk/examples/virtual-device-app/android/App/app/libs/jniLibs/armeabi-v7a"

# $GITHUB_WORKSPACE apunta dinámicamente a /home/runner/work/matter_virtual_device/Matter_Virtual_Device_CHIP
# JNI_TARGET_DIR="$GITHUB_WORKSPACE/matter-sdk/examples/virtual-device-app/android/App/app/libs/jniLibs/armeabi-v7a"

# Usamos la ruta relativa directa ya que nos encontramos dentro de la carpeta 'matter-sdk'
JNI_TARGET_DIR="examples/virtual-device-app/android/App/app/libs/jniLibs/armeabi-v7a"

# Strip Tool
STRIP_TOOL="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"

if [ -x "$STRIP_TOOL" ] && [ -d "$JNI_TARGET_DIR" ]; then
    echo "INFRA: Procesando y reduciendo binarios nativos con llvm-strip..."
    
    # Buscamos solo los archivos .so originales (evitando procesar los *_small.so en ejecuciones repetidas)
    # y mapeamos de manera limpia la lista de librerías a optimizar.
    FOUND_ANY=false
    for so_file in "$JNI_TARGET_DIR"/*.so; do
        # Saltar si el archivo es un subproducto anterior o si no coincide ningún archivo literal
        [[ "$so_file" == *"_small.so" ]] && continue
        [ -f "$so_file" ] || continue
        
        FOUND_ANY=true
        base_name="${so_file%.so}"
        target_small="${base_name}_small.so"
        
        echo "  ↳ Optimizando: $(basename "$so_file") -> $(basename "$target_small")"
        $STRIP_TOOL --strip-unneeded "$so_file" -o "$target_small"
    done

    if [ "$FOUND_ANY" = true ]; then
        echo "========================================================================="
        echo "📊 COMPARATIVA DE TAMAÑOS EN EL DISCO DEL RUNNER:"
        echo "========================================================================="
        ls -lh "$JNI_TARGET_DIR"/*.so
        echo "========================================================================="
    else
        echo "⚠️ ADVERTENCIA: No se encontró ningún archivo .so original para optimizar en $JNI_TARGET_DIR"
    fi
else
    echo "⚠️ ADVERTENCIA CRÍTICA: No se pudo iniciar la optimización post-compilación."
    [ ! -x "$STRIP_TOOL" ] && echo "  ↳ Razón: El binario de stripping no es ejecutable o no existe en: $STRIP_TOOL"
    [ ! -d "$JNI_TARGET_DIR" ] && echo "  ↳ Razón: No se localizó la carpeta de librerías: $JNI_TARGET_DIR"
fi
