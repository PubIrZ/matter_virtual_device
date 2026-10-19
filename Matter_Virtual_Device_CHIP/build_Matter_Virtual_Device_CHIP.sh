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
echo "  ↳ JAVA_11_HOME_X64 : ${JAVA_11_HOME_X64:-'❌ NO DETECTADA (¿No instalada?)'}"
echo "  ↳ JAVA_17_HOME_X64 : ${JAVA_17_HOME_X64:-'❌ NO DETECTADA (¿No instalada?)'}"

# Mostrar versión física real apuntada por las variantes si existen
if [ -n "$JAVA_11_HOME_X64" ] && [ -x "$JAVA_11_HOME_X64/bin/java" ]; then
    echo "    ↳ Versión Real en Java 11 SDK: $($JAVA_11_HOME_X64/bin/java -version 2>&1 | head -n 1)"
fi
if [ -n "$JAVA_17_HOME_X64" ] && [ -x "$JAVA_17_HOME_X64/bin/java" ]; then
    echo "    ↳ Versión Real en Java 17 SDK: $($JAVA_17_HOME_X64/bin/java -version 2>&1 | head -n 1)"
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


# 5. VARIABLES CUSTOM DE CONTROL
echo "📂 VARIABLES CUSTOM DE CONTROL:"
echo "-------------------------------------------------------------------------"
echo "  ↳ FORCE_CLEAR_CACHE: $FORCE_CLEAR_CACHE"
echo ""

echo "========================================================================="

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
# INICIALIZACIÓN DEL ENTORNO DE COMPILACIÓN DE MATTER
# =========================================================================
echo "INFRA: Inicializando el entorno virtual aislado de Pigweed..."
source scripts/activate.sh


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

echo "INFRA: Ninja reanudará la compilación de forma incremental..."
#ninja -C out/virtual-device-app
./scripts/build/build_examples.py --target android-arm-virtual-device-app build

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
