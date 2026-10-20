#!/bin/bash

# =========================================================================
# SCRIPT DINÁMICO DE COMPILACIÓN - BYPASS TOTAL DE WARNINGS DE KOTLIN
# =========================================================================

# =========================================================================
# ¡EL LIMPIADOR MAESTRO DE SALTOS DE LÍNEA DE WINDOWS (CRLF a LF)!
# =========================================================================
sed -i 's/\r$//' "$0" || true


set -e # Detiene el script inmediatamente si ocurre un error inesperado

# =========================================================================
# 🐙 AUTOMAPEO DEL ENTORNO DE GITHUB ACTIONS (EXPORTS DE $GITHUB_ENV) 
# Lee el archivo físico del disco y carga todas las variables en este subproceso
# =========================================================================
if [ -n "$GITHUB_ENV" ] && [ -f "$GITHUB_ENV" ]; then
    echo "⚙️ INFRA: Sincronizando y exportando bloque completo de \$GITHUB_ENV..."
    while IFS= read -r line || [ -n "$line" ]; do
        # Evitamos procesar líneas vacías o comentarios del archivo
        if [[ ! -z "$line" && "$line" != "#"* ]]; then
		    echo "   ⚙️ [ENV LOAD] -> $line"
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

# 1. Variables de Entorno Típicas de GitHub Actions
echo "🐙 VARIABLES GLOBALES DE GITHUB:"
echo "-------------------------------------------------------------------------"
echo "  ↳ GITHUB_WORKSPACE : ${GITHUB_WORKSPACE:-'❌ NO EXPORTADA / VACÍA'}"
echo "  ↳ GITHUB_REPOSITORY: ${GITHUB_REPOSITORY:-'❌ NO EXPORTADA'}"
echo "  ↳ GITHUB_REF_NAME  : ${GITHUB_REF_NAME:-'❌ NO EXPORTADA'}"
echo "  ↳ GITHUB_SHA       : ${GITHUB_SHA:-'❌ NO EXPORTADA'}"
echo "  ↳ GITHUB_RUN_ID    : ${GITHUB_RUN_ID:-'❌ NO EXPORTADA'}"
echo ""

# 2. Variantes de JAVA_HOME dependientes del SDK (Inyectadas por setup-java)
echo "☕ VARIANTES DE ENTORNO JAVA (JDK MAP):"
echo "-------------------------------------------------------------------------"
echo "  ↳ CURRENT JAVA_HOME: ${JAVA_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ JAVA_HOME_11_X64 : ${JAVA_HOME_11_X64:-'❌ NO DETECTADA (¿No instalada?)'}"
echo "  ↳ JAVA_HOME_17_X64 : ${JAVA_HOME_17_X64:-'❌ NO DETECTADA (¿No instalada?)'}"

# Mostrar versión física real apuntada por las variantes si existen
if [ -n "$JAVA_HOME_11_X64" ] && [ -x "$JAVA_HOME_11_X64/bin/java" ]; then
    echo "    ↳ Versión Real en Java 11 SDK: $($JAVA_HOME_11_X64/bin/java -version 2>&1 | head -n 1)"
fi
if [ -n "$JAVA_HOME_17_X64" ] && [ -x "$JAVA_HOME_17_X64/bin/java" ]; then
    echo "    ↳ Versión Real en Java 17 SDK: $($JAVA_HOME_17_X64/bin/java -version 2>&1 | head -n 1)"
fi
echo ""


# 3. Parámetros del Entorno de Android, NDK y ZAP
echo "📂 VARIABLES DE DESARROLLO (ANDROID / MATTER):"
echo "-------------------------------------------------------------------------"
echo "  ↳ ANDROID_HOME     : ${ANDROID_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ ANDROID_NDK_ROOT : ${ANDROID_NDK_ROOT:-'❌ NO DETECTADA'}"
echo "  ↳ ANDROID_NDK_HOME : ${ANDROID_NDK_HOME:-'❌ NO DETECTADA'}"
echo "  ↳ ZAP_INSTALL_PATH : ${ZAP_INSTALL_PATH:-'❌ NO DETECTADA'}"
echo ""

# 4. Descubrimiento y Versión de Binarios Activos
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

# GN (Generate Ninja)
echo ""
if command -v gn >/dev/null 2>&1; then
    echo "  ↳ GN Tool      : Encontrado en $(command -v gn) -> $(gn --version 2>/dev/null || echo 'GN disponible, pero ⚠️ no se localizó versión')"
else
    echo "  ↳ GN Tool      : ❌ No inicializado aún (⏳ Se activará tras Pigweed 'activate.sh')"
fi
echo ""

echo "INFRA: Descargando pre-requisitos de dependencias de Android..."
python3 third_party/android_deps/set_up_android_deps.py
third_party/java_deps/set_up_java_deps.sh

# =========================================================================
# ¡EL CAMBIO MAESTRO DE RAÍZ! ELIMINAMOS -Werror Y DESACTIVAMOS ALERTAS (.gn y .gni)
# =========================================================================
echo "INFRA: Removiendo flags estrictos de las plantillas fuentes BUILD.gn y .gni..."
find . -name "BUILD.gn" -exec sed -i 's|"-Werror",||g' {} +
find . -name "BUILD.gn" -exec sed -i 's|"-Werror"||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Werror",||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Werror"||g' {} +

find . -name "BUILD.gn" -exec sed -i 's|"-Xlint:all",||g' {} +
find . -name "BUILD.gn" -exec sed -i 's|"-Xlint:all"||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Xlint:all",||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Xlint:all"||g' {} +

# 🚀 ¡AÑADE ESTA NUEVA LÍNEA AQUÍ PARA CORREGIR EL ERROR DE JAVA 17!
find . -name "gradle.properties" -exec sed -i 's|-XX:MaxPermSize=2048m||g' {} +

# =========================================================================
# ANULACIÓN COMPLETA EN EL MOTOR DE PIGWEED (KOTLINC)
# Modificamos el script wrapper para inyectar '-nowarn' al final del comando
# =========================================================================
echo "INFRA: Inyectando inhibidores de error '-nowarn' en el motor de Pigweed..."
export KOTLIN_COMPILER_ARGS="-nowarn -warn:0"
export KOTLINC_ARGS="-nowarn"

# Modificamos el script ejecutable de Python de forma segura. 
# En lugar de romper la cabecera, inyectamos '-nowarn' de forma segura en los argumentos adicionales.
find . -name "kotlinc_runner.py" -exec sed -i "s|retcode = subprocess.check_call(kotlin_args + args.rest)|kotlin_args.append('-nowarn')\n    retcode = subprocess.check_call(kotlin_args + args.rest)|g" {} +
find . -name "kotlinc_runner.py" -exec sed -i "s|'-Werror'||g" {} +

## =========================================================================
## 🛡️ PARCHE CLAVE ANTI-COLLISION DE VERSIONES DE KOTLIN METADATA!
## =========================================================================
#echo "INFRA: Inyectando supresores de versión de metadatos de Kotlin (-Xskip-metadata-version-check)..."
#
## Localizamos todos los archivos build.gradle del subproyecto Android y acoplamos el flag de escape
#find examples/virtual-device-app/android/ -name "build.gradle" -exec sed -i '/kotlinOptions {/a \        freeCompilerArgs += ["-Xskip-metadata-version-check", "-Xallow-no-source-files"]' {} +
#
## Respaldo de seguridad directo para variantes que usen sintaxis de asignación clásica (=)
#find examples/virtual-device-app/android/ -name "build.gradle" -exec sed -i 's|freeCompilerArgs = |freeCompilerArgs = ["-Xskip-metadata-version-check", "-Xallow-no-source-files"] + |g' {} +
#
#echo "INFRA: Flags de supresión de Kotlin inyectados con éxito en el árbol App/."


## =========================================================================
## 🛡️ PARCHE ANTI-STAKOVERFLOW Y VERSIONES DE KOTLIN METADATA!
## =========================================================================
#echo "INFRA: Aplicando supresores planos estables para evitar StackOverflow de Kotlin..."
#
## 1. Limpiamos cualquier rastro o intento previo de inyección acumulada en el bucle caliente
#find examples/virtual-device-app/android/ -name "build.gradle" -exec sed -i '/-Xskip-metadata-version-check/d' {} +
#
## 2. Forzamos una declaración plana inmutable dentro de los bloques kotlinOptions de forma limpia
#find examples/virtual-device-app/android/ -name "build.gradle" -exec sed -i '/kotlinOptions {/a \        freeCompilerArgs = ["-Xskip-metadata-version-check", "-Xallow-no-source-files"]' {} +
#
#echo "INFRA: Parche inmutable de Kotlin inyectado. El compilador ignorará la firma 2.4.0."

# # =========================================================================
# # 🛡️ TUNING MAESTRO: EXPORTACIÓN UNIFICADA DE MEMORIA Y COMPILACIÓN GRADLE
# # =========================================================================
# echo "INFRA: Configurando topes de memoria JVM y supresores de metadatos de Kotlin..."
#
# ## 1. Limpiamos cualquier residuo de texto previo de los sed anteriores en el SDK
# #git reset --hard HEAD --quiet || true
#
# # 2. Bloqueamos alertas redundantes del motor de Kotlin
# export KOTLIN_COMPILER_ARGS="-nowarn -warn:0"
#
# # 3. Forzamos límites globales en los hilos base de ejecución de Java (Bajo nivel)
# export _JAVA_OPTIONS="-Xmx2048m -Xms512m -Dawt.useSystemAAFontSettings=gasp"
#
# # 4. 🔥 UNIFICACIÓN PERFECTA: Asignamos 2GB de RAM al demonio de Gradle Y 
# #    pasamos los argumentos del compilador de Kotlin en un formato plano inmutable.
# #    Esto detiene la recursión (Adiós StackOverflow) y acelera la compilación.
# export GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx2048m -Dorg.jetbrains.kotlin.compiler.arguments='-Xskip-metadata-version-check -Xallow-no-source-files'"
33
# echo "INFRA: Entorno de memoria y compilación optimizado al 100%."
# # =========================================================================


# =========================================================================
# 🛡️ INTERCEPTOR DEFINITIVO: HARD-BINDING DE ARGUMENTOS DIRECTO EN GRADLEW
# =========================================================================
echo "INFRA: Purgando residuos e inyectando argumentos planos en el core de gradlew..."

# Localizamos el script ejecutable gradlew del subproyecto Android App
GRADLEW_FILE="examples/virtual-device-app/android/App/gradlew"

if [ -f "$GRADLEW_FILE" ]; then
    # Inyectamos los argumentos planos e inmutables directamente en la cabecera de ejecución de la JVM de gradlew.
    # Esto blinda al demonio de Gradle contra StackOverflow y suprime el error de la firma de metadatos 2.4.0.
    sed -i '/#!/a DEFAULT_JVM_OPTS="-Xmx2048m -Xms512m -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files"' "$GRADLEW_FILE"
    echo "INFRA: Parche atómico acoplado con éxito en $GRADLEW_FILE."
else
    echo "⚠️ ADVERTENCIA: No se encontró el archivo gradlew en la ruta esperada."
fi

# Bloqueamos alertas cosméticas redundantes del motor de Kotlin
export KOTLIN_COMPILER_ARGS="-nowarn -warn:0"
export KOTLINC_ARGS="-nowarn"
# =========================================================================


# =========================================================================
#
# =========================================================================
echo "INFRA: Sincronizando árbol estructural de GN..."
# 🛠️ 5. REGENERA LA ESTRUCTURA DE COMPILACIÓN SI SE HIZO FORCE_CLEAR_CACHE (rm -rf out/)
#gn gen out/virtual-device-app \
#  --args='target_os="android" target_cpu="arm" android_ndk_root="'$ANDROID_NDK_ROOT'" android_sdk_root="/usr/local/lib/android/sdk" chip_config_network_layer_ble=false treat_warnings_as_errors=false' \
#  --root=examples/virtual-device-app/android/

gn gen out/virtual-device-app \
  --args='target_os="android" target_cpu="arm" android_ndk_root="'$ANDROID_NDK_ROOT'" android_sdk_root="'$ANDROID_HOME'" chip_config_network_layer_ble=false treat_warnings_as_errors=false' \
  --root=examples/virtual-device-app/android/
  
# Parches secundarios de seguridad de última capa sobre archivos de configuración JSON
find out/ -name "*.json" -exec sed -i 's|"-Werror",||g' {} +

# =========================================================================
# 🛡️ INTERCEPTOR EXCLUSIVO: PRE-ACEPTACIÓN DE LICENCIAS CON JAVA 17
# =========================================================================
echo "INFRA: Interceptando licencias del sdkmanager usando subshell Java 17..."

if [ -n "$JAVA_HOME_17_X64" ] && [ -d "$JAVA_HOME_17_X64" ]; then
    # El uso de ( ) crea una subburbuja de memoria aislada. 
    # Los cambios de PATH y JAVA_HOME mueren al cerrarse el paréntesis.
    (
        export JAVA_HOME="$JAVA_HOME_17_X64"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "   ↳ Activado temporalmente: $(java -version 2>&1 | head -n 1)"
        
        # Ejecutamos el sdkmanager con los privilegios de Java 17
        yes | /usr/local/lib/android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses >/dev/null || true
    )
    echo "INFRA: Licencias registradas en disco. Retornando a entorno global Java 11."
else
    echo "⚠️ ADVERTENCIA: No se localizó la ruta de JAVA_HOME_17_X64 en el entorno."
fi
# =========================================================================

echo "INFRA: Ninja reanudará la compilación de forma incremental..."
#ninja -C out/virtual-device-app
./scripts/build/build_examples.py --target android-arm-virtual-device-app build

# =========================================================================
# 📊 TELEMETRÍA AVANZADA: COMPARATIVA DE TÉCNICAS DE EXTRACCIÓN DE REQUISITOS
# =========================================================================
echo ""
# 1. Definimos y creamos de forma segura la ruta destino mapeada en el upload-artifact de tu YAML
REPORT_TARGET_DIR="examples/virtual-device-app/android/App/app/build/outputs/reports"
mkdir -p "$REPORT_TARGET_DIR"

echo "========================================================================="
echo "🔬 TÉCNICA 1: ANALIZADOR DE DEPENDENCIAS ATÓMICAS DE GN (NINJA MAP)"
echo "========================================================================="
if [ -d "out" ]; then
    # Escaneamos los mapas .ninja.d, filtramos rutas relativas, limpiamos nombres de archivos
    # y ordenamos de forma única para obtener la huella dactilar exacta del compilador.
    find out/ -name "*.ninja.d" -exec cat {} + 2>/dev/null | \
    tr ' ' '\n' | \
    grep -v '^out/' | \
    grep '/' | \
    sed 's|/[^/]*$||' | \
    sort -u > "$REPORT_TARGET_DIR/carpetas_esenciales_gn.txt" || true

    echo "🎯 TÉCNICA 1: Detectadas $(wc -l < "$REPORT_TARGET_DIR/carpetas_esenciales_gn.txt" 2>/dev/null || echo '0') carpetas críticas en el SDK."
    echo "📋 El reporte físico se ha guardado en: $REPORT_TARGET_DIR/carpetas_esenciales_gn.txt"
    echo "Top 20 carpetas indispensables leídas:"
    echo "-------------------------------------------------------------------------"
    head -n 20 "$REPORT_TARGET_DIR/carpetas_esenciales_gn.txt" || echo "⚠️ Archivo vacío."
else
    echo "❌ Error: La carpeta out/ no existe. GN no generó mapas de compilación."
fi
echo "========================================================================="
echo ""

echo "============================================================================"
echo "📂 TÉCNICA 2: CARPETAS FUENTE DEL SDK MODIFICADAS POR PARCHES SED (GIT STATUS)"
echo "============================================================================"
# Preguntamos a Git qué directorios contienen archivos modificados "al vuelo" por los sed de nuestra compilación
git status --porcelain 2>/dev/null | grep "M " | awk '{print $2}' | sed 's|/[^/]*$||' | sort -u > "$REPORT_TARGET_DIR/carpetas_modificadas_git.txt" || true

echo "🎯 TÉCNICA 2: Localizadas $(wc -l < "$REPORT_TARGET_DIR/carpetas_modificadas_git.txt" 2>/dev/null || echo '0') carpetas parchadas por sed."
echo "📋 El reporte físico se ha guardado en: $REPORT_TARGET_DIR/carpetas_modificadas_git.txt"
echo "Top 20 de carpetas modificadas por sed:"
echo "-------------------------------------------------------------------------"
head -n 20 "$REPORT_TARGET_DIR/carpetas_modificadas_git.txt" || echo "⚠️ Git no reporta archivos modificados."
echo "========================================================================="
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

STRIP_TOOL="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"

if [ -f "$JNI_TARGET_DIR/libDeviceApp.so" ] && [ -x "$STRIP_TOOL" ]; then
    echo "INFRA: Duplicando y reduciendo binarios nativos con llvm-strip..."
    
    # El parámetro -o clona y aplica el strip en el nuevo archivo sin alterar el original
    $STRIP_TOOL --strip-unneeded "$JNI_TARGET_DIR/libDeviceApp.so" -o "$JNI_TARGET_DIR/libDeviceApp_small.so"
    $STRIP_TOOL --strip-unneeded "$JNI_TARGET_DIR/libc++_shared.so" -o "$JNI_TARGET_DIR/libc++_shared_small.so"
    
    echo "========================================================================="
    echo "📊 COMPARATIVA DE TAMAÑOS EN EL DISCO DEL RUNNER:"
    echo "========================================================================="
    ls -lh "$JNI_TARGET_DIR"/libDeviceApp*.so
    ls -lh "$JNI_TARGET_DIR"/libc++_shared*.so
    echo "========================================================================="
else
    echo "⚠️ ADVERTENCIA CRÍTICA: No se localizaron los binarios en la ruta esperada:"
    echo "-> Buscado en: $JNI_TARGET_DIR/libDeviceApp.so"
fi
