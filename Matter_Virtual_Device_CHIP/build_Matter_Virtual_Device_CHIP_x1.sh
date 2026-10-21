#!/bin/bash

# =========================================================================
# SCRIPT DINÁMICO DE COMPILACIÓN CON ASIGNACIÓN DE ENTORNO AISLADO DE DISCO
# =========================================================================
# Plantilla didáctica optimizada para compilaciones complejas en Matter/Android.
# Evita la colisión de variables globales destructivas y limpia la terminal.
# =========================================================================

# Sanitizar saltos de línea de Windows (CRLF a LF) de forma automática e inmediata
sed -i 's/
$//' "$0" || true
set -e 

# 🐙 EXTRACTOR DE ENTORNO DE GITHUB ACTIONS
# Escanea de forma física el mapa del disco asignado al pipeline para heredar
# variables refrescadas en caliente entre ciclos del bucle interactivo.
if [ -n "$GITHUB_ENV" ] && [ -f "$GITHUB_ENV" ]; then
    echo "⚙️ INFRA: Sincronizando bloque completo de variables \$GITHUB_ENV..."
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ ! -z "$line" && "$line" != "#"* ]]; then
            export "$line"
        fi
    done < "$GITHUB_ENV"
fi

# Neutralizar el disparador de descargas redundantes de red del motor ZAP de CIPD
unset PW_ZAP_CIPD_RELEASE
export -n PW_ZAP_CIPD_RELEASE 2>/dev/null || true

# Configuración de limpieza incremental condicional controlada por interfaz web
FORCE_CLEAR_CACHE="${FORCE_CLEAR_CACHE:-false}"

echo "========================================================================="
echo "🔍 DIAGNÓSTICO DE PRE-COMPILACIÓN EN EL ENTORNO VIRTUAL HÍBRIDO"
echo "========================================================================="
echo "  ↳ ENTORNO GLOBAL RUNNER (Java Base del Sistema): $(java -version 2>&1 | head -n 1)"
echo "  ↳ TARGET JDK MAP (Puntero inyectado aislado): ${MATTER_TARGET_JAVA_HOME:-'❌ NO DETECTADO'}"
echo "  ↳ ANDROID_HOME MAPPED RUTA: ${ANDROID_HOME:-'❌ NO DETECTADA'}"
echo "========================================================================="

# Limpieza atómica de la carpeta estructural out/ si el flag está activo
if [ "$FORCE_CLEAR_CACHE" = "true" ]; then
    echo "⚠️ INFRA: Detectado flag 'clear_cache' como TRUE. Destruyendo out/..."
    rm -rf out/
fi

# Parche anti-descarga CIPD sobre ficheros zap.json
if [ -f "scripts/setup/zap.json" ]; then echo '{"packages": []}' > scripts/setup/zap.json; fi
find . -name "zap.json" -exec sh -c 'echo "{"packages": []}" > "{}"' \;

# 🚀 ACTIVACIÓN DEL ENTORNO VIRTUAL DEL SDK (PIGWEED MOTOR ENGINE)
echo "INFRA: Inicializando el entorno virtual aislado de Pigweed..."
source scripts/activate.sh

# 🛡️ PROTECCIÓN CRÍTICA ANTI-SOF (STACK OVERFLOW) EN KOTLIN / GRADLE
# Inyectamos argumentos seguros en la JVM del demonio constructor. El parámetro
# '-Xskip-metadata-version-check' evita la colisión de firmas de metadatos de Kotlin
# que provocan errores de compilación fatales en entornos Android clásicos.
export GRADLE_OPTS="-Xmx2048m -Xms512m -Dorg.jetbrains.kotlin.compiler.arguments=-Xskip-metadata-version-check -Dorg.jetbrains.kotlin.compiler.arguments=-Xallow-no-source-files"

# Sincronización local de librerías nativas internas del SDK de Matter
echo "INFRA: Descargando pre-requisitos de dependencias de Android..."
python3 third_party/android_deps/set_up_android_deps.py
third_party/java_deps/set_up_java_deps.sh

# 🧹 OPERACIÓN LIMPIEZA DE WARNINGS ESTRICTOS (-Werror & -Xlint)
# Evita que el compilador nativo de C/C++ (Ninja) y el de Java aborten la ejecución 
# por avisos informativos menores u obsoletos en el árbol del código fuente de Matter.
echo "INFRA: Neutralizando flags estrictos en plantillas GN, GNI y properties..."
find . -name "BUILD.gn" -exec sed -i 's|"-Werror",||g; s|"-Werror"||g; s|"-Xlint:all",||g; s|"-Xlint:all"||g' {} +
find . -name "*.gni" -exec sed -i 's|"-Werror",||g; s|"-Werror"||g; s|"-Xlint:all",||g; s|"-Xlint:all"||g' {} +
find . -name "gradle.properties" -exec sed -i 's|-XX:MaxPermSize=2048m||g' {} +

# Forzado de inhibidores '-nowarn' en el motor de Pigweed para el compilador Kotlinc
export KOTLIN_COMPILER_ARGS="-nowarn -warn:0"
export KOTLINC_ARGS="-nowarn"
find . -name "kotlinc_runner.py" -exec sed -i "s|retcode = subprocess.check_call(kotlin_args + args.rest)|kotlin_args.append('-nowarn')
    retcode = subprocess.check_call(kotlin_args + args.rest)|g" {} +
find . -name "kotlinc_runner.py" -exec sed -i "s|'-Werror'||g" {} +

# 🛠️ GENERACIÓN DEL ÁRBOL ESTRUCTURAL GN (GENERATE NINJA)
echo "INFRA: Sincronizando árbol estructural de mapas de GN..."
gn gen out/virtual-device-app   --args='target_os="android" target_cpu="arm" android_ndk_root="'$ANDROID_NDK_ROOT'" android_sdk_root="'$ANDROID_HOME'" chip_config_network_layer_ble=false treat_warnings_as_errors=false'   --root=examples/virtual-device-app/android/
  
find out/ -name "*.json" -exec sed -i 's|"-Werror",||g' {} +

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

# 🚀 EJECUCIÓN DEL MÓDULO INTÉRPRETE DE COMPILACIÓN DE MATTER
echo "INFRA: Invocando script compilador nativo (Llamada Python a Gradle Wrapper)..."
./scripts/build/build_examples.py --target android-arm-virtual-device-app build

# 📊 EXTRACCIÓN DE TELEMETRÍA NATIVA (ANÁLISIS DE HUELLES INDISPENSABLES)
REPORT_TARGET_DIR="examples/virtual-device-app/android/App/app/build/outputs/reports"
mkdir -p "$REPORT_TARGET_DIR"

if [ -d "out" ]; then
    find out/ -name "*.ninja.d" -exec cat {} + 2>/dev/null | tr ' ' '
' | grep -v '^out/' | grep '/' | sed 's|/[^/]*$||' | sort -u > "$REPORT_TARGET_DIR/carpetas_esenciales_gn.txt" || true
fi
git status --porcelain 2>/dev/null | grep "M " | awk '{print $2}' | sed 's|/[^/]*$||' | sort -u > "$REPORT_TARGET_DIR/carpetas_git_modificadas.txt" || true

# ⚡ REDUCCIÓN ATÓMICA DE PESO MEDIANTE LLVM-STRIP (OPTIMIZACIÓN DE BINARIOS NATIVOS .SO)
JNI_TARGET_DIR="examples/virtual-device-app/android/App/app/libs/jniLibs/armeabi-v7a"
STRIP_TOOL="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"

if [ -f "$JNI_TARGET_DIR/libDeviceApp.so" ] && [ -x "$STRIP_TOOL" ]; then
    echo "INFRA: Optimizando peso de empaquetado de librerías nativas con llvm-strip..."
    $STRIP_TOOL --strip-unneeded "$JNI_TARGET_DIR/libDeviceApp.so" -o "$JNI_TARGET_DIR/libDeviceApp_small.so"
    $STRIP_TOOL --strip-unneeded "$JNI_TARGET_DIR/libc++_shared.so" -o "$JNI_TARGET_DIR/libc++_shared_small.so"
    ls -lh "$JNI_TARGET_DIR"/libDeviceApp*.so
fi
