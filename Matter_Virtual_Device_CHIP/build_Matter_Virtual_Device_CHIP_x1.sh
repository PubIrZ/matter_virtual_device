#!/bin/bash

# =========================================================================
# SCRIPT DINÁMICO DE COMPILACIÓN CON ASIGNACIÓN DE ENTORNO AISLADO DE DISCO
# =========================================================================
# Plantilla didáctica optimizada para compilaciones complejas en Matter/Android.
# Evita la colisión de variables globales destructivas y limpia la terminal.
# =========================================================================

# Sanitizar saltos de línea de Windows (CRLF a LF) de forma automática e inmediata
sed -i 's/\r$//' "$0" || true

set -e # Detiene el script inmediatamente si ocurre un error inesperado

#echo "🚨 MODO RESCATE ACTIVO: Saltando compilación y forzando subida inmediata del out (gh artifact upload)."
#exit 10

# 🐙 EXTRACTOR DE ENTORNO DE GITHUB ACTIONS
# Escanea de forma física el mapa del disco asignado al pipeline para heredar
# variables refrescadas en caliente entre ciclos del bucle interactivo.
if [ -n "$GITHUB_ENV" ] && [ -f "$GITHUB_ENV" ]; then
    echo "⚙️ INFRA: Sincronizando bloque completo de variables \$GITHUB_ENV (exports)..."
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ ! -z "$line" && "$line" != "#"* ]]; then
            export "$line"
        fi
    done < "$GITHUB_ENV"
fi

# 🔥 ANULACIÓN CRÍTICA ANTI-CRASH: Forzamos el borrado de la variable conflictiva
# Esto evita que el validador estricto de Python de Pigweed aborte la compilación.
unset PW_ZAP_CIPD_RELEASE
export -n PW_ZAP_CIPD_RELEASE 2>/dev/null || true

# =========================================================================
# ⚙️ CONTROL MANUAL DE CACHÉ LOCAL (COMENTAR / DESCOMENTAR SEGÚN NECESIDAD)
# =========================================================================
# Descomenta la siguiente línea para FORZAR la limpieza y ejecución en limpio:
# FORCE_CLEAR_CACHE="true"

# Si sigue comentada, heredará automáticamente el valor del botón web de GitHub:
FORCE_CLEAR_CACHE="${FORCE_CLEAR_CACHE:-false}"



## 🚀 FORZAR USO DE JAVA 11 PARA EVITAR EL ERROR "major version 61"
#POSIBLE_JAVA_11=$(find /opt/hostedtoolcache/Java_Zulu_jdk/ -maxdepth 2 -name "11.*" | head -n 1)
#if [ -n "$POSIBLE_JAVA_11" ]; then
#    export JAVA_HOME="$POSIBLE_JAVA_11/x64"
#    export PATH="$JAVA_HOME/bin:$PATH"
#fi
#
#echo "INFRA: Ajustando entorno a $(java -version 2>&1 | head -n 1)"


echo "========================================================================="
echo "🔍 DIAGNÓSTICO AVANZADO DE ENTORNO EN EL RUNNER (HOST VIRTUAL)"
echo "========================================================================="
echo ""
# 1. Variables de Entorno Típicas de GitHub Actions
echo "-------------------------------------------------------------------------"
echo "🐙 VARIABLES GLOBALES DE GITHUB:"
echo "-------------------------------------------------------------------------"
echo "  ↳ GITHUB_WORKSPACE : ${GITHUB_WORKSPACE:-'❌ NO EXPORTADA / VACÍA'}"
echo "  ↳ GITHUB_REPOSITORY: ${GITHUB_REPOSITORY:-'❌ NO EXPORTADA'}"
echo "  ↳ GITHUB_REF_NAME  : ${GITHUB_REF_NAME:-'❌ NO EXPORTADA'}"
echo "  ↳ GITHUB_SHA       : ${GITHUB_SHA:-'❌ NO EXPORTADA'}"
echo "  ↳ GITHUB_RUN_ID    : ${GITHUB_RUN_ID:-'❌ NO EXPORTADA'}"
echo ""
echo "-------------------------------------------------------------------------"
# 2. Variantes de JAVA_HOME dependientes del SDK (Inyectadas por setup-java)
echo "-------------------------------------------------------------------------"
echo "☕ VARIANTES DE ENTORNO JAVA (JDK MAP):"
echo "-------------------------------------------------------------------------"
echo "  ↳ CURRENT JAVA_HOME: ${JAVA_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ JAVA_HOME_11_X64 : ${JAVA_HOME_11_X64:-'❌ NO DETECTADA (¿No instalada?)'}"
echo "  ↳ JAVA_HOME_17_X64 : ${JAVA_HOME_17_X64:-'❌ NO DETECTADA (¿No instalada?)'}"
echo ""
# Mostrar versión física real apuntada por las variantes si existen
if [ -n "$JAVA_HOME_11_X64" ] && [ -x "$JAVA_HOME_11_X64/bin/java" ]; then
    echo "    ↳ Versión Real en Java 11 SDK: $($JAVA_HOME_11_X64/bin/java -version 2>&1 | head -n 1)"
fi
if [ -n "$JAVA_HOME_17_X64" ] && [ -x "$JAVA_HOME_17_X64/bin/java" ]; then
    echo "    ↳ Versión Real en Java 17 SDK: $($JAVA_HOME_17_X64/bin/java -version 2>&1 | head -n 1)"
fi

echo ""
# 3. Parámetros del Entorno de Android, NDK y ZAP
echo "-------------------------------------------------------------------------"
echo "📂 VARIABLES DE DESARROLLO (ANDROID / MATTER):"
echo "-------------------------------------------------------------------------"
echo "  ↳ ANDROID_HOME     : ${ANDROID_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ ANDROID_NDK_ROOT : ${ANDROID_NDK_ROOT:-'❌ NO DETECTADA'}"
echo "  ↳ ANDROID_NDK_HOME : ${ANDROID_NDK_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ ZAP_INSTALL_PATH : ${ZAP_INSTALL_PATH:-'❌ NO DETECTADA'}"

echo ""
# 4. Descubrimiento y Versión de Binarios Activos
echo "-------------------------------------------------------------------------"
echo "🛠️ BINARIOS Y VERSIONES REALES (EN PATH ACTIVO):"
echo "-------------------------------------------------------------------------"
#echo "  ↳ Java CLI Activo  : $(java -version 2>&1 | head -n 1 || echo '❌ No encontrado')"
#echo "  ↳ Python Ejecutable: $(python3 --version 2>&1 || echo '❌ No encontrado')"

# Java Compiler / Runtime
if command -v java >/dev/null 2>&1; then
    echo "  ↳ Java CLI     : $(java -version 2>&1 | head -n 1)"
else
    echo "  ↳ Java CLI     : ❌ NO ENCONTRADO EN EL PATH"
fi

# Python
if command -v python3 >/dev/null 2>&1; then
    echo "  ↳ Python       : $(python3 --version 2>&1)"
else
    echo "  ↳ Python       : ❌ NO ENCONTRADO EN EL PATH"
fi

# GN (Generate Ninja)
if command -v gn >/dev/null 2>&1; then
    echo "  ↳ GN Tool      : Encontrado en $(command -v gn) -> $(gn --version 2>/dev/null || echo 'GN disponible, pero ⚠️ no se localizó versión')"
else
    echo "  ↳ GN Tool      : ❌ No inicializado aún (⏳ Se activará tras Pigweed 'activate.sh')"
fi

# ZAP CLI
if command -v zap-cli >/dev/null 2>&1; then
    echo "  ↳ ZAP CLI      : Encontrado en $(command -v zap-cli)"
else
    echo "  ↳ ZAP CLI      : ❌ NO ACCESIBLE (Verificar enlace simbólico)"
fi

# NDK Compiler (Clang de LLVM específico del NDK configurado)
CLANG_NDK="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
if [ -f "$CLANG_NDK" ]; then
    echo "  ↳ NDK Clang    : Encontrado ($($CLANG_NDK --version | head -n 1 | cut -d' ' -f1-4))"
else
    echo "  ↳ NDK Clang    : ❌ Binario del compilador no hallado en la ruta del NDK"
fi

echo ""
# 5. VARIABLES CUSTOM DE CONTROL
echo "-------------------------------------------------------------------------"
echo "📂 VARIABLES CUSTOM DE CONTROL:"
echo "-------------------------------------------------------------------------"
echo "  ↳ FORCE_CLEAR_CACHE: $FORCE_CLEAR_CACHE"
echo ""
echo "========================================================================="


# =========================================================================
# 🧹 LIMPIEZA ATÓMICA DE CÓDIGO FUENTE (EVITA ACUMULACIÓN ENTRE INTENTOS DEL BUCLE)
# =========================================================================
echo "INFRA: Limpiando parches de texto residuales del intento de compilación anterior..."
# Forzamos a Git a restaurar cualquier BUILD.gn alterado en el SDK de Matter antes de aplicar los nuevos sed
git reset --hard HEAD --quiet || true
git clean -fd --quiet || true

# =========================================================================
# 🔥 LIMPIEZA CONDICIONAL DE CACHÉ LOCAL (ANTES DE COMPILAR / ACTIVAR)
# Nota: No afecta scripts/activate.sh (el script de activación de Matter, ya que
#       Pigweed no guarda su entorno dentro de out/)
#       Pero se pone antes de scripts/activate.sh para que este no pierda el
#       tiempo escaneando y validando metadatos que se borraran.
# =========================================================================
if [ "$FORCE_CLEAR_CACHE" = "true" ]; then
    echo "⚠️ INFRA: Flag 'clear_cache' detectado como TRUE. Destruyendo carpeta out/ de forma segura..."
    rm -rf out/
else
    echo "⚡ INFRA: Manteniendo carpeta 'out/' para permitir compilación incremental rápida."
fi


# =========================================================================
# ¡EL PARCHE CLAVE AN_TI-CIPD DE CONFIGURACIÓN NEUTRALIZADA!
# Vaciar zap.json para que CIPD ignore su  intento de descarga
# =========================================================================
echo "INFRA: Neutralizando configuraciones JSON rígidas de CIPD para ZAP..."
if [ -f "scripts/setup/zap.json" ]; then
    echo '{"packages": []}' > scripts/setup/zap.json
fi
find . -name "zap.json" -exec sh -c 'echo "{\"packages\": []}" > "{}"' \;

echo "INFRA: Archivos zap.json vaciados con éxito. CIPD ignorará la descarga de red."

# =========================================================================
# INICIALIZACIÓN DEL ENTORNO DE COMPILACIÓN DE MATTER
# =========================================================================
echo "INFRA: Inicializando el entorno virtual aislado de Pigweed..."
source scripts/activate.sh

## ==========================================================================
## 🛡️ Proteger la COMPILACION KOTLIN contra los errores de StackOverflow
##    y la colision entre versiones del metadata de KOTLIN con GRADLE_OPTS
## ==========================================================================
#  Configuramos los flags de JVM, separados por un espacio simple y sin 
#  comillas dobles internas para evitar errores.
# 🛡️ PROTECCIÓN CRÍTICA ANTI ERRORES (STACK OVERFLOW) EN KOTLIN / GRADLE
# Inyectamos argumentos seguros en la JVM del demonio constructor. El parámetro
# '-Xskip-metadata-version-check' evita la colisión de firmas de metadatos de Kotlin
# que provocan errores de compilación fatales en entornos Android clásicos.

export GRADLE_OPTS="-Xmx2048m -Xms512m -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files"

echo "INFRA: Parche GRADLE_OPTS justo tras la activación de Pigweed."
# =========================================================================
echo ""

# GN (Generate Ninja)
echo ""
echo "INFRA: INFO GN (Generate Ninja)"
if command -v gn >/dev/null 2>&1; then
    echo "  ↳ GN Tool      : Encontrado en $(command -v gn) -> $(gn --version 2>/dev/null || echo 'GN disponible, pero ⚠️ no se localizó versión')"
else
    echo "  ↳ GN Tool      : ❌ No inicializado aún (⏳ Se activará tras Pigweed 'activate.sh')"
fi
echo ""


# =========================================================================
# 🛡️ INYECCIÓN INTEGRAL ANTI-CRASH DE METADATOS EN EL SUBPROYECTO DE TERCEROS
# =========================================================================
echo "INFRA: Aplicando parche de mitigación en caliente sobre third_party/android_deps..."

TARGET_NESTED_GRADLE="third_party/android_deps/build.gradle"

if [ -f "$TARGET_NESTED_GRADLE" ]; then
    # 1. Creamos el bloque de código Groovy que obliga a saltarse la validación estricta de Kotlin
    BLOCK_COMPATIBILITY=$(cat << 'EOF'

// Parche de compatibilidad inyectado por el pipeline de infraestructura de CI
allprojects {
    tasks.withType(executePattern = { it.name.contains("Kotlin") || it.class.name.contains("Kotlin") }).configureEach {
        try {
            kotlinOptions {
                freeCompilerArgs += ["-Xskip-metadata-version-check", "-Xallow-no-source-files"]
            }
        } catch (Exception e) {
            // Silenciar errores si la tarea no expone directamente las opciones de Kotlin
        }
    }
}
EOF
)
    # 2. Inyectamos el bloque completo de configuración al final de build.gradle de dependencias
    echo "$BLOCK_COMPATIBILITY" >> "$TARGET_NESTED_GRADLE"
    echo "  ✅ Bloque de anulación inyectado con éxito en $TARGET_NESTED_GRADLE"
    
    # 3. Blindaje secundario: Escribir parámetros directamente en el archivo gradle.properties interno
    NESTED_PROPERTIES="third_party/android_deps/gradle.properties"
    touch "$NESTED_PROPERTIES"
    sed -i '/Xskip-metadata-version-check/d' "$NESTED_PROPERTIES" || true
    echo "android.kotlinOptions.freeCompilerArgs+=[-Xskip-metadata-version-check]" >> "$NESTED_PROPERTIES"
    echo "kotlin.experimental.tryK2=false" >> "$NESTED_PROPERTIES"
    echo "  ✅ Parámetros de respaldo asignados en $NESTED_PROPERTIES"
else
    echo "⚠️ ADVERTENCIA CRÍTICA: No se localizó $TARGET_NESTED_GRADLE. Saltando inyección."
fi

# 4. Aseguramos que las variables de entorno de la JVM sigan activas para los hilos de Gradle
export GRADLE_OPTS="-Xmx2048m -Xms512m -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files"
export KOTLIN_COMPILER_ARGS="-nowarn -warn:0 -Xskip-metadata-version-check"
export KOTLINC_ARGS="-nowarn -Xskip-metadata-version-check"

# Sincronización local de librerías nativas internas del SDK de Matter
echo "INFRA: Descargando pre-requisitos de dependencias de Android..."
python3 third_party/android_deps/set_up_android_deps.py
third_party/java_deps/set_up_java_deps.sh

# =========================================================================
# 🧹 LIMPIEZA DE WARNINGS ESTRICTOS (-Werror & -Xlint)
# Evita que el compilador nativo de C/C++ (Ninja) y el de Java aborten la ejecución 
# por avisos informativos menores u obsoletos en el árbol del código fuente de Matter.
# =========================================================================
echo "INFRA: Se eliminan los flags Warning-Error de las plantillas .gn y .gni del código fuente Matter."
find . -name "BUILD.gn" -exec sed -i 's|"-Werror",||g' {} +
find . -name "BUILD.gn" -exec sed -i 's|"-Werror"||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Werror",||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Werror"||g' {} +

find . -name "BUILD.gn" -exec sed -i 's|"-Xlint:all",||g' {} +
find . -name "BUILD.gn" -exec sed -i 's|"-Xlint:all"||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Xlint:all",||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Xlint:all"||g' {} +

# 🚀 PARA PREVENIR ERROR EN JAVA 17! 
# Se elimina el flag obsoleto "MaxPermSize" de todo el árbol SDK Matter
# Este flag fue deprecated en Java 8 y eliminado por completo en Java 17
echo "INFRA: Se elimina el flag obsoleto "MaxPermSize" de todo el árbol SDK Matter"
find . -name "gradle.properties" -exec sed -i 's|-XX:MaxPermSize=2048m||g' {} +

# =========================================================================
# Bloqueamos los mensajes de aviso del motor Pigweed (KOTLINC)
# =========================================================================
echo "INFRA: Inyectando inhibidores de error '-nowarn' en el motor de Pigweed..."
export KOTLIN_COMPILER_ARGS="-nowarn -warn:0"
export KOTLINC_ARGS="-nowarn"
 
# Modificamos el script wrapper ejecutable de Python para inyectar '-nowarn' al final del comando 
# En lugar de romper la cabecera, inyectamos '-nowarn' de forma segura en los argumentos adicionales.
find . -name "kotlinc_runner.py" -exec sed -i "s|retcode = subprocess.check_call(kotlin_args + args.rest)|kotlin_args.append('-nowarn')\n    retcode = subprocess.check_call(kotlin_args + args.rest)|g" {} +
find . -name "kotlinc_runner.py" -exec sed -i "s|'-Werror'||g" {} +


## ==========================================================================
## 🛡️ PARCHEADO DEL FICHERO GRADLE gradle.propertie DE LA COMPILACION KOTLIN
##    ANTI-STAKOVERFLOW Y ANTI-COLLISION DE VERSIONES DE KOTLIN METADATA!
## ==========================================================================
#echo "INFRA: Configurando argumentos en la ruta fija de gradle.properties..."
#
#GRADLE_PROPERTIES="examples/virtual-device-app/android/App/gradle.properties"
#
#if [ -f "$GRADLE_PROPERTIES" ]; then
#
#    # 🔥 En gradle.properties buscamos la línea original de jvmargs Matter y concatenamos al final los flags:
#    #    -Xskip-metadata-version-check y -Xallow-no-source-files 
#	#    Esto blinda al demonio de Gradle contra los errores de la firma de metadatos 2.4.0 y el StackOverflow (detiene la recursión) 
#    #sed -i 's|org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8|org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8 -Xms512m -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files|g' "$GRADLE_PROPERTIES"
#    sed -i 's|^org.gradle.jvmargs=.*|org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8 -Xms512m -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files|g' "$GRADLE_PROPERTIES"
#	
#    echo "INFRA: -Xskip-metadata-version-check y -Xallow-no-source-files inyectados con éxito en $GRADLE_PROPERTIES."
#else
#    echo "⚠️ ADVERTENCIA: No se localizó el archivo $GRADLE_PROPERTIES."
#fi

# =========================================================================
echo ""


# =========================================================================
# 🔥 EL CAMBIO MAESTRO: ESTRATEGIA DE INYECCIÓN A NIVEL DE DISCO DE USUARIO
# =========================================================================
# En lugar de usar 'GRADLE_OPTS' o tocar el properties del repositorio (que 
# corren el riesgo de perderse en subprocesos aislados generados por Python),
# inyectamos la ruta del JDK 11 antiguo directamente en la carpeta global
# de usuario del Runner de GitHub (~/.gradle/gradle.properties).
# Al estar escrito en disco físico, CUALQUIER demonio de Gradle llamado por
# Bash, Python o Pigweed la leerá con total precedencia y compilará con Java 11
# de forma indestructible, manteniendo 'git status' intacto.
# =========================================================================
if [ -n "$MATTER_TARGET_JAVA_HOME" ]; then
    echo "INFRA: Registrando asignación de JDK 11 en las directivas de usuario locales (~/.gradle/)..."
    mkdir -p ~/.gradle
    # Eliminamos entradas antiguas idénticas para evitar duplicidades masivas en el archivo
    touch ~/.gradle/gradle.properties
    sed -i '/org.gradle.java.home/d' ~/.gradle/gradle.properties || true
    # Escribimos el puntero físico definitivo
    echo "org.gradle.java.home=$MATTER_TARGET_JAVA_HOME" >> ~/.gradle/gradle.properties
else
    echo "⚠️ ADVERTENCIA: Variable MATTER_TARGET_JAVA_HOME vacía. Se intentará usar JDK del sistema."
fi


# =========================================================================
#  🛠️ REGENERAR LA ESTRUCTURA DE COMPILACIÓN (FUNDAMENTAL SI SE HIZO FORCE_CLEAR_CACHE (rm -rf out/))
# =========================================================================
echo "INFRA: Sincronizando árbol estructural de mapas de GN..."

# ANDROID_HOME="/usr/local/lib/android/sdk" 
# ANDROID_NDK_ROOT="/opt/hostedtoolcache/ndk/r25c/x64"

gn gen out/virtual-device-app \
  --args='target_os="android" target_cpu="arm" android_ndk_root="'$ANDROID_NDK_ROOT'" android_sdk_root="'$ANDROID_HOME'" chip_config_network_layer_ble=false treat_warnings_as_errors=false' \
  --root=examples/virtual-device-app/android/
  
# Parches secundarios de seguridad de última capa sobre archivos de configuración JSON
find out/ -name "*.json" -exec sed -i 's|"-Werror",||g' {} +
echo ""

# 🚀 EJECUCIÓN DEL MÓDULO INTÉRPRETE DE COMPILACIÓN DE MATTER
echo "INFRA: Invocando script compilador nativo (Llamada Python a Gradle Wrapper)..."
./scripts/build/build_examples.py --target android-arm-virtual-device-app build
echo ""


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
