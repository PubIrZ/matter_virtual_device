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

# Ruta para volcado de memoria si hay OOM en Jetifier/Kotlin
DUMP_DIR="${GITHUB_WORKSPACE}/matter-sdk/examples/virtual-device-app/android/App/app/build/outputs/reports"
mkdir -p "$DUMP_DIR"

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

# =========================================================================
# 🛡️ PIPELINE DE INICIALIZACIÓN NATIVA (GRADLE GLOBAL OPTIMIZER)
# =========================================================================
mkdir -p ~/.gradle

cat << 'EOF' > ~/.gradle/init.gradle
allprojects {
    // CONFIGURACIÓN DE OPTIMIZACIÓN GLOBAL
    def ENABLE_STRIP = true

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

########## COMPILO LA APP y Funciona el Emparejamiento con Alexa v8 (BridgeJNI Dynamic) <<----------------
# =========================================================================
# 🏗️ PIPELINE INTEGRAL: FILTRADO PYTHON .ZAP + PUENTE JNI C++ DESACOPLADO y DINÁMICO C++
# =========================================================================
# Ficheros Sobreescritos del SDK original (se respaldan en .bak antes de mutarlos)
GN_FILE="examples/virtual-device-app/android/BUILD.gn"

SRC_JNI_H="examples/virtual-device-app/android/java/DeviceApp-JNI.h"
SRC_JNI="examples/virtual-device-app/android/java/DeviceApp-JNI.cpp"
ZAP_FILE="examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"
SRC_ATTR="examples/virtual-device-app/android/java/ClusterChangeAttribute.cpp"
LVL_CPP="src/app/clusters/level-control/level-control.cpp"

# Ficheros Nuevos inyectados para el televisor virtual (se borran tras compilar)
SRC_DELEGATES="examples/virtual-device-app/android/java/MiTeleDelegates.cpp"

echo "INFRA: Creando buffers de respaldo temporales para Git..."
cp "$ZAP_FILE" "${ZAP_FILE}.bak"
cp "$GN_FILE" "${GN_FILE}.bak"

cp "$SRC_JNI_H" "${SRC_JNI_H}.bak"
cp "$SRC_JNI" "${SRC_JNI}.bak"

cp "$SRC_ATTR" "${SRC_ATTR}.bak"
cp "$LVL_CPP" "${LVL_CPP}.bak"

# 1. Definir función de limpieza unificada para dejar limpio el árbol Git tras compilar o restaurar si la compilación fallar
restore_overwritten_files() {
    echo "🧹 INFRA: Restaurando archivos originales de Git y eliminando temporales..."

    # Ficheros Sobreescritos
    mv "${ZAP_FILE}.bak" "$ZAP_FILE" || true

    mv "${GN_FILE}.bak" "$GN_FILE" || true

    mv "${SRC_JNI_H}.bak" "$SRC_JNI_H" || true
    mv "${SRC_JNI}.bak" "$SRC_JNI" || true
    mv "${SRC_ATTR}.bak" "$SRC_ATTR" || true
    mv "${LVL_CPP}.bak" "$LVL_CPP" || true

    # Ficheros Nuevos
    rm -f "$SRC_DELEGATES" || true
}

# 2. Registrar la función en el trap (disparador) ERR
trap restore_overwritten_files ERR


# Generación del .zap en Python (con FeatureMap = "0" en Brillo para evitar saltos al pasar el switch de Off a On)
echo "INFRA: Generando archivo .zap compuesto para MiTele..."
echo "INFRA: Fusionando .zap original del SDK con clústeres oficiales para MiTele..."
python3 - << 'EOF'
import json
import copy
import os

# Rutas de los archivos .zap oficiales dentro del SDK de Matter (connectedhomeip)
base_zap_path = "examples/virtual-device-app/virtual-device-common/virtual-device-app.zap"
all_zap_path  = "examples/all-clusters-app/all-clusters-common/all-clusters-app.zap"
wc_zap_path   = "examples/window-app/common/window-app.zap"
rvc_zap_path  = "examples/rvc-app/rvc-common/rvc-app.zap"
dw_zap_path   = "examples/dishwasher-app/dishwasher-common/dishwasher-app.zap"

with open(base_zap_path, "r", encoding="utf-8") as f:
    zap_obj = json.load(f)

def extract_cluster(zap_files, cluster_code):
    """
    Busca la definición completa (atributos + comandos obligatorios) de un clúster
    en una lista ordenada de archivos .zap oficiales y lo devuelve habilitado.
    """
    for zfile in zap_files:
        if not os.path.exists(zfile):
            continue
        with open(zfile, "r", encoding="utf-8") as f:
            data = json.load(f)
        for ep_t in data.get("endpointTypes", []):
            for c in ep_t.get("clusters", []):
                if c.get("code") == cluster_code and c.get("side") == "server":
                    c_copy = copy.deepcopy(c)
                    c_copy["enabled"] = 1
                    return c_copy
    return None

# 1. Mantener INTACTO el Endpoint 0 (Root Device: Red, Seguridad, Comisionamiento)
#    y fijar el nombre por defecto del nodo ("MiTele") en Basic Information (0x0028 -> 40)
for ep_t in zap_obj.get("endpointTypes", []):
    if ep_t.get("deviceTypeCode") == 22 or ep_t.get("id") == 1:
        for c in ep_t.get("clusters", []):
            if c.get("code") == 40:  # Basic Information (0x0028)
                for attr in c.get("attributes", []):
                    if attr.get("code") in {3, 5}:  # ProductName (3) y NodeLabel (5)
                        attr["included"] = 1
                        attr["defaultValue"] = "MiTele"

# 2. Extraer cada clúster desde su app dedicada (con fallback a all-clusters-app.zap)
c_level    = extract_cluster(list((all_zap_path,)), 8)               # 0x0008 Level Control (Nivel 0-10)
c_wc       = extract_cluster(list((wc_zap_path, all_zap_path)), 258) # 0x0102 Window Covering (Volumen 0-100%)
c_dw_mode  = extract_cluster(list((dw_zap_path, all_zap_path)), 89)  # 0x0059 Dishwasher Mode (Lista 1: Apps/HDMI)
c_op_stat  = extract_cluster(list((dw_zap_path, all_zap_path)), 96)  # 0x0060 Operational State (Estado 1)
c_rvc_run  = extract_cluster(list((rvc_zap_path, all_zap_path)), 84) # 0x0054 RVC Run Mode (Lista 2: Imagen)
c_rvc_cln  = extract_cluster(list((rvc_zap_path, all_zap_path)), 85) # 0x0055 RVC Clean Mode (Lista 3: Sonido)
c_rvc_stat = extract_cluster(list((rvc_zap_path, all_zap_path)), 97) # 0x0061 RVC Operational State (Estado 2)

# 3. Ajustar valores iniciales específicos de MiTele en Level Control (8)
if c_level:
    for attr in c_level.get("attributes", []):
        if attr.get("code") == 0:        # CurrentLevel = 76 (~30% / Nivel 3 de 10)
            attr["included"] = 1
            attr["defaultValue"] = "76"
        elif attr.get("code") == 2:      # MinLevel = 1
            attr["included"] = 1
            attr["defaultValue"] = "1"
        elif attr.get("code") == 3:      # MaxLevel = 254
            attr["included"] = 1
            attr["defaultValue"] = "254"
        elif attr.get("code") == 15:     # Options = 1 (executeIfOff = true: permite ajustar estando apagado)
            attr["included"] = 1
            attr["defaultValue"] = "1"
        elif attr.get("code") == 65532:  # FeatureMap = 0 (Desactiva Lighting fade: evita salto de brillo al encender On/Off)
            attr["included"] = 1
            attr["defaultValue"] = "0"

# 4. Ajustar valores iniciales específicos de MiTele en Window Covering (258 -> Volumen)
if c_wc:
    for attr in c_wc.get("attributes", []):
        if attr.get("code") == 0:            # Type = 0 (Rollershade)
            attr["included"] = 1
            attr["defaultValue"] = "0"
        elif attr.get("code") == 7:          # ConfigStatus = 11 (Operational + Online + LiftPositionAware)
            attr["included"] = 1
            attr["defaultValue"] = "11"
        elif attr.get("code") == 8:          # CurrentPositionLiftPercentage = 70 (70% volumen inicial)
            attr["included"] = 1
            attr["defaultValue"] = "70"
        elif attr.get("code") in {11, 14}:   # Target & Current Lift 100ths = 7000
            attr["included"] = 1
            attr["defaultValue"] = "7000"
        elif attr.get("code") == 65532:      # FeatureMap = 5 (Lift + PositionAwareLift)
            attr["included"] = 1
            attr["defaultValue"] = "5"

# 5. Mutar el Endpoint 1 conservando sus clústeres base (Identify=3, Groups=4, On/Off=6, Descriptor=29)
#    Nota: Se declara un único deviceType (266 = Enchufe) en el .zap para satisfacer la restricción SQLite
#    de zap-cli, y los 5 deviceTypes compuestos se inyectan dinámicamente en DeviceApp-JNI.cpp.
for ep_t in zap_obj.get("endpointTypes", []):
    if ep_t.get("id") == 2 or ep_t.get("name") == "MA-videoplayer":
        ep_t["name"] = "MA-mitele-composite"
        ep_t["deviceTypeName"] = "MA-onoffpluginunit"
        ep_t["deviceTypeCode"] = 266
        ep_t["deviceTypeProfileId"] = 259
        ep_t["deviceTypeRef"] = {
            "code": 266,
            "profileId": 259,
            "label": "MA-onoffpluginunit",
            "name": "MA-onoffpluginunit"
        }
        ep_t["deviceTypes"] = list((ep_t["deviceTypeRef"],))
        ep_t["deviceVersions"] = list((3,))
        ep_t["deviceIdentifiers"] = list((266,))

        # Conservar los clústeres válidos originales del Endpoint 1 (3, 4, 6, 29)
        base_clusters = list((
            c for c in ep_t.get("clusters", ())
            if c.get("code") in {3, 4, 6, 29} and c.get("side") == "server"
        ))

        # Encender On/Off (6) por defecto (OnOff = 1)
        for c in base_clusters:
            c["enabled"] = 1
            if c.get("code") == 6:
                for attr in c.get("attributes", []):
                    if attr.get("code") == 0:
                        attr["included"] = 1
                        attr["defaultValue"] = "1"

        # Inyectar todos los clústeres extraídos del SDK
        extra_list = (c_level, c_wc, c_dw_mode, c_op_stat, c_rvc_run, c_rvc_cln, c_rvc_stat)
        for extra_c in extra_list:
            if extra_c is not None:
                base_clusters.append(extra_c)
            else:
                print("⚠️ AVISO: No se encontró uno de los clústeres solicitados en los .zap de origen.")

        ep_t["clusters"] = base_clusters

# 6. Actualizar el mapeo del Endpoint 1
for ep in zap_obj.get("endpoints", []):
    if ep.get("endpointId") == 1 or ep.get("endpointTypeName") == "MA-videoplayer":
        ep["endpointTypeName"] = "MA-mitele-composite"

with open(base_zap_path, "w", encoding="utf-8") as f:
    json.dump(zap_obj, f, indent=2)

print("✅ INFRA PYTHON: .zap fusionado con éxito (Endpoint 0 intacto + 11 clústeres en Endpoint 1).")
EOF


# Desacoplando MoveToLevelWithOnOff de OnOffServer en level-control.cpp...
# El sed en level-control.cpp (setOnOffValue): Evita que deslizar la barra de brillo en Alexa encienda automáticamente el switch On/Off
if [ -f "$LVL_CPP" ]; then
    echo "INFRA: Desacoplando MoveToLevelWithOnOff de OnOffServer en level-control.cpp..."
    git checkout -- "$LVL_CPP" || true
    # Neutraliza las llamadas internas de LevelControl hacia OnOffServer::Instance().setOnOffValue(...)
    sed -i 's|OnOffServer::Instance().setOnOffValue|// OnOffServer::Instance().setOnOffValue|g' "$LVL_CPP"
fi	

#Limpieza de BUILD.gn

echo "INFRA: Purgando managers innecesarios e inyectando MiTeleDelegates.cpp en BUILD.gn..."
# Mantenemos AppImpl.cpp activo para que el servidor de red pueda arrancar de forma conforme
sed -i 's|"java/ColorControlManager.cpp",|# "java/ColorControlManager.cpp",|g' "$GN_FILE"
sed -i 's|"java/ColorControlManager.h",|# "java/ColorControlManager.h",|g' "$GN_FILE"
sed -i 's|"java/DoorLockManager.cpp",|# "java/DoorLockManager.cpp",|g' "$GN_FILE"
sed -i 's|"java/DoorLockManager.h",|# "java/DoorLockManager.h",|g' "$GN_FILE"
sed -i 's|"java/PowerSourceManager.cpp",|# "java/PowerSourceManager.cpp",|g' "$GN_FILE"
sed -i 's|"java/PowerSourceManager.h",|# "java/PowerSourceManager.h",|g' "$GN_FILE"
sed -i 's|"java/OnOffManager.cpp",|"java/OnOffManager.cpp", "java/MiTeleDelegates.cpp",|g' "$GN_FILE"


# Cabecera DeviceApp-JNI.h
echo "INFRA: Escribiendo DeviceApp-JNI.h con despachador universal PostMatterEvent..."
cat << 'EOF' > "$SRC_JNI_H"

#pragma once

#include <jni.h>
#include <lib/support/JniReferences.h>

/**
 * Puente singleton entre el stack nativo de Matter (C++) y la capa Java/Kotlin de Android.
 * Encapsula la referencia global al objeto DeviceApp y los identificadores de métodos JNI.
 */
class DeviceAppJNI
{
public:
    void InitializeWithObjects(jobject app);
    void PostClusterInit(int clusterId, int endpoint);
    void PostEvent(int event);

    // Despachador universal Matter -> Android: notifica cualquier cambio de atributo, modo o estado Matter a la app Android
    void PostMatterEvent(int clusterId, int attributeId, int value);

private:
    friend DeviceAppJNI & DeviceAppJNIMgr();

    static DeviceAppJNI sInstance;
    chip::JniGlobalReference mDeviceAppObject;
    jmethodID mPostClusterInitMethod = nullptr;
    jmethodID mPostEventMethod       = nullptr;
    jmethodID mPostMatterEventMethod = nullptr;
};

inline class DeviceAppJNI & DeviceAppJNIMgr()
{
    return DeviceAppJNI::sInstance;
}
EOF



# Implementación bidireccional DeviceApp-JNI.cpp (onMatterEvent + updateAttribute + Configuración Dinámica)																		  

echo "INFRA: Reescribiendo DeviceApp-JNI.cpp con puente bidireccional desacoplado..."
cat << 'EOF' > "$SRC_JNI"
#include "DeviceApp-JNI.h"
#include "AppImpl.h"
#include "JNIDACProvider.h"
#include "OnOffManager.h"
#include "credentials/DeviceAttestationCredsProvider.h"
#include <app-common/zap-generated/attributes/Accessors.h>
#include <app-common/zap-generated/ids/Clusters.h>
#include <app/app-platform/ContentAppPlatform.h>
#include <app/server/Dnssd.h>
#include <app/server/java/AndroidAppServerWrapper.h>
#include <app/util/endpoint-config-api.h>
#include <credentials/examples/DeviceAttestationCredsExample.h>
#include <jni.h>
#include <lib/core/CHIPError.h>
#include <lib/support/CHIPJNIError.h>
#include <lib/support/JniReferences.h>
#include <lib/support/JniTypeWrappers.h>
#include <platform/CHIPDeviceLayer.h>
#include <string>
#include <vector>

using namespace chip;
using namespace chip::app;
using namespace chip::app::Clusters;
using namespace chip::AppPlatform;
using namespace chip::Credentials;
using namespace chip::DeviceLayer;

#define JNI_METHOD(RETURN, METHOD_NAME) \
    extern "C" JNIEXPORT RETURN JNICALL Java_com_matter_virtual_device_app_DeviceApp_##METHOD_NAME

// Funciones externas implementadas en MiTeleDelegates.cpp
extern void InitMiTeleClusters(chip::EndpointId endpoint);
extern void UpdateMiTeleModeOrState(chip::EndpointId endpoint, uint32_t clusterId, uint8_t newValue);
extern void SetDynamicMiTeleModes(uint32_t clusterId, std::vector<std::string> labels, std::vector<uint16_t> tags);
extern void SetDynamicMiTeleStates(uint32_t clusterId, std::vector<uint8_t> states);

// Nombre personalizado del nodo Matter (Endpoint 0) configurable desde Android antes de postServerInit
static std::string gCustomNodeLabel = "MiTele";

// Lista compuesta de 5 tipos de dispositivo Matter declarados en el Descriptor del Endpoint 1
EmberAfDeviceType gDeviceTypeIds[] = {
    { 266, 3 }, // 0x010A On/Off Plug-in Unit (Enchufe) (Prioridad visual en Alexa - Permite Identificarlo con el Dispositivo que realmente está enchufado a él -TV-)
    { 257, 3 }, // 0x0101 Dimmable Light  (Habilita LevelControl 0-10)
    { 514, 2 }, // 0x0202 Window Covering (Habilita barra porcentual pura 0-100% para Volumen)
    { 117, 1 }, // 0x0075 Dishwasher      (Habilita Lista 1 de modos personalizados + Estado 1)
    { 116, 1 }  // 0x0074 Robotic Vacuum Cleaner (Habilita Listas 2 y 3 de modos + Estado 2)
};

DeviceAppJNI DeviceAppJNI::sInstance;

void DeviceAppJNI::InitializeWithObjects(jobject app)
{
    JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
    VerifyOrReturn(env != nullptr, ChipLogError(Zcl, "Failed to GetEnvForCurrentThread for DeviceAppJNI"));

    VerifyOrReturn(mDeviceAppObject.Init(app) == CHIP_NO_ERROR, ChipLogError(Zcl, "Failed to init mDeviceAppObject"));

    jclass managerClass = env->GetObjectClass(app);
    VerifyOrReturn(managerClass != nullptr, ChipLogError(Zcl, "Failed to get DeviceAppJNI Java class"));

    mPostClusterInitMethod = env->GetMethodID(managerClass, "postClusterInit", "(JI)V");
    if (mPostClusterInitMethod == nullptr)
    {
        ChipLogError(Zcl, "Failed to access DeviceApp 'postClusterInit' method");
        env->ExceptionClear();
    }

    mPostEventMethod = env->GetMethodID(managerClass, "postEvent", "(J)V");
    if (mPostEventMethod == nullptr)
    {
        ChipLogError(Zcl, "Failed to access DeviceApp 'postEvent' method");
        env->ExceptionClear();
    }

//onMatterEvent: Callback Matter -> Android)
// Firma JNI: void onMatterEvent(int clusterId, int attributeId, int value)
    mPostMatterEventMethod = env->GetMethodID(managerClass, "onMatterEvent", "(III)V");
    if (mPostMatterEventMethod == nullptr)
    {
        ChipLogError(Zcl, "Failed to access DeviceApp 'onMatterEvent(III)V' method");
        env->ExceptionClear();
    }
}

void DeviceAppJNI::PostClusterInit(int clusterId, int endpoint)
{
    JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
    VerifyOrReturn(env != nullptr, ChipLogError(Zcl, "Failed to GetEnvForCurrentThread for DeviceAppJNI::PostClusterInit"));
    VerifyOrReturn(mDeviceAppObject.HasValidObjectRef(), ChipLogError(Zcl, "DeviceAppJNI::mDeviceAppObject null"));
    VerifyOrReturn(mPostClusterInitMethod != nullptr, ChipLogError(Zcl, "DeviceAppJNI::mPostClusterInitMethod null"));

    env->CallVoidMethod(mDeviceAppObject.ObjectRef(), mPostClusterInitMethod, static_cast<jlong>(clusterId),
                        static_cast<jint>(endpoint));
    if (env->ExceptionCheck())
    {
        ChipLogError(Zcl, "Failed to call DeviceAppJNI 'postClusterInit' method");
        env->ExceptionClear();
    }
}

void DeviceAppJNI::PostEvent(int event)
{
    JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
    VerifyOrReturn(env != nullptr, ChipLogError(Zcl, "Failed to GetEnvForCurrentThread for DeviceAppJNI::PostEvent"));
    VerifyOrReturn(mDeviceAppObject.HasValidObjectRef(), ChipLogError(Zcl, "DeviceAppJNI::mDeviceAppObject null"));
    VerifyOrReturn(mPostEventMethod != nullptr, ChipLogError(Zcl, "DeviceAppJNI::mPostEventMethod null"));

    env->CallVoidMethod(mDeviceAppObject.ObjectRef(), mPostEventMethod, static_cast<jlong>(event));
    if (env->ExceptionCheck())
    {
        ChipLogError(Zcl, "Failed to call DeviceAppJNI 'postEventMethod' method");
        env->ExceptionClear();
    }
}

void DeviceAppJNI::PostMatterEvent(int clusterId, int attributeId, int value)
{
    JNIEnv * env = JniReferences::GetInstance().GetEnvForCurrentThread();
    VerifyOrReturn(env != nullptr, ChipLogError(Zcl, "Failed to GetEnvForCurrentThread for DeviceAppJNI::PostMatterEvent"));
    VerifyOrReturn(mDeviceAppObject.HasValidObjectRef(), ChipLogError(Zcl, "DeviceAppJNI::mDeviceAppObject null"));
    VerifyOrReturn(mPostMatterEventMethod != nullptr, ChipLogError(Zcl, "DeviceAppJNI::mPostMatterEventMethod null"));

    env->CallVoidMethod(mDeviceAppObject.ObjectRef(), mPostMatterEventMethod,
                        static_cast<jint>(clusterId),
                        static_cast<jint>(attributeId),
                        static_cast<jint>(value));
    if (env->ExceptionCheck())
    {
        ChipLogError(Zcl, "Failed to call DeviceAppJNI 'onMatterEvent' method");
        env->ExceptionClear();
    }
}

//Métodos JNI nativos invocables desde Android)
//Añade métodos nativos JNI Android -> Matter en DeviceApp-JNI.cpp..."

jint JNI_OnLoad(JavaVM * jvm, void * reserved)
{
    return AndroidAppServerJNI_OnLoad(jvm, reserved);
}

void JNI_OnUnload(JavaVM * jvm, void * reserved)
{
    return AndroidAppServerJNI_OnUnload(jvm, reserved);
}

JNI_METHOD(void, nativeInit)(JNIEnv *, jobject app)
{
    DeviceAppJNIMgr().InitializeWithObjects(app);
}

JNI_METHOD(void, preServerInit)(JNIEnv *, jobject app)
{
    chip::DeviceLayer::StackLock lock;
    ChipLogProgress(Zcl, "DeviceAppJNI::preServerInit");

    PreServerInit();
}

JNI_METHOD(void, postServerInit)(JNIEnv *, jobject app, jint deviceTypeId)
{
    chip::DeviceLayer::StackLock lock;
    ChipLogProgress(Zcl, "DeviceAppJNI::postServerInit - MiTele Device Compuesto Dinámico");

    // Aplicar NodeLabel personalizado en Endpoint 0 (Basic Information)
    if (!gCustomNodeLabel.empty())
    {
        BasicInformation::Attributes::NodeLabel::Set(0, CharSpan(gCustomNodeLabel.data(), gCustomNodeLabel.size()));
    }

    emberAfSetDeviceTypeList(1, Span<const EmberAfDeviceType>(gDeviceTypeIds));
    InitMiTeleClusters(1);
}

JNI_METHOD(void, setDACProvider)(JNIEnv *, jobject, jobject provider)
{
    if (!chip::Credentials::IsDeviceAttestationCredentialsProviderSet())
    {
        chip::Credentials::SetDeviceAttestationCredentialsProvider(chip::Credentials::Examples::GetExampleDACProvider());
    }
}

/**
 * Configura dinámicamente el nombre del dispositivo Matter (Endpoint 0 - NodeLabel) desde Android.
 * Debe invocarse antes de postServerInit().
 */
JNI_METHOD(void, setNodeLabel)(JNIEnv * env, jobject, jstring label)
{
    VerifyOrReturn(label != nullptr);
    const char * utf = env->GetStringUTFChars(label, nullptr);
    if (utf != nullptr)
    {
        gCustomNodeLabel = std::string(utf);
        env->ReleaseStringUTFChars(label, utf);
    }
}

/**
 * Configura dinámicamente las etiquetas y tags de los modos de un clúster (0x0059, 0x0054, 0x0055).
 * Debe invocarse antes de postServerInit().
 */
JNI_METHOD(void, setClusterModes)(JNIEnv * env, jobject, jint clusterId, jobjectArray labels, jintArray tags)
{
    VerifyOrReturn(labels != nullptr && tags != nullptr);
    jsize count = env->GetArrayLength(labels);
    jint * tagElements = env->GetIntArrayElements(tags, nullptr);

    std::vector<std::string> labelVec;
    std::vector<uint16_t> tagVec;
    labelVec.reserve(count);
    tagVec.reserve(count);

    for (jsize i = 0; i < count; i++)
    {
        jstring jstr = static_cast<jstring>(env->GetObjectArrayElement(labels, i));
        const char * utf = env->GetStringUTFChars(jstr, nullptr);
        labelVec.emplace_back(utf != nullptr ? utf : "");
        tagVec.push_back(static_cast<uint16_t>(tagElements[i]));
        if (utf != nullptr) env->ReleaseStringUTFChars(jstr, utf);
        env->DeleteLocalRef(jstr);
    }
    env->ReleaseIntArrayElements(tags, tagElements, JNI_ABORT);

    SetDynamicMiTeleModes(static_cast<uint32_t>(clusterId), std::move(labelVec), std::move(tagVec));
}

/**
 * Configura dinámicamente la lista de IDs de estado permitidos en OperationalState (0x0060 / 0x0061).
 * Debe invocarse antes de postServerInit().
 */
JNI_METHOD(void, setClusterStates)(JNIEnv * env, jobject, jint clusterId, jintArray stateIds)
{
    VerifyOrReturn(stateIds != nullptr);
    jsize count = env->GetArrayLength(stateIds);
    jint * elements = env->GetIntArrayElements(stateIds, nullptr);

    std::vector<uint8_t> stateVec;
    stateVec.reserve(count);
    for (jsize i = 0; i < count; i++)
    {
        stateVec.push_back(static_cast<uint8_t>(elements[i]));
    }
    env->ReleaseIntArrayElements(stateIds, elements, JNI_ABORT);

    SetDynamicMiTeleStates(static_cast<uint32_t>(clusterId), std::move(stateVec));
}

/**
 * Puente Android UI -> Matter / Alexa:
 * Actualiza cualquier atributo, modo o estado en el servidor Matter desde la interfaz Android.
 */
JNI_METHOD(void, updateAttribute)(JNIEnv *, jobject, jint endpoint, jint clusterId, jint attributeId, jint value)
{
    DeviceLayer::SystemLayer().ScheduleLambda([endpoint, clusterId, attributeId, value] {
        chip::EndpointId ep = static_cast<chip::EndpointId>(endpoint);
        if (clusterId == 0x0006) // On/Off
        {
            OnOff::Attributes::OnOff::Set(ep, value != 0);
        }
        else if (clusterId == 0x0008) // Level Control (1..254)
        {
            uint8_t lvl = static_cast<uint8_t>(value < 1 ? 1 : (value > 254 ? 254 : value));
            LevelControl::Attributes::CurrentLevel::Set(ep, lvl);
        }
        else if (clusterId == 0x0102) // Window Covering (0..100%)
        {
            uint8_t pct = static_cast<uint8_t>(value < 0 ? 0 : (value > 100 ? 100 : value));
            uint16_t pct100 = static_cast<uint16_t>(pct * 100);
            WindowCovering::Attributes::CurrentPositionLiftPercentage::Set(ep, pct);
            WindowCovering::Attributes::CurrentPositionLiftPercent100ths::Set(ep, pct100);
            WindowCovering::Attributes::TargetPositionLiftPercent100ths::Set(ep, pct100);
        }
        else
        {
            UpdateMiTeleModeOrState(ep, static_cast<uint32_t>(clusterId), static_cast<uint8_t>(value));
        }
    });
}


/*
 * On Off Manager y Stubs de compatibilidad con la plantilla base
 */
JNI_METHOD(void, setOnOffManager)(JNIEnv *, jobject, jint endpoint, jobject manager)
{
    OnOffManager::NewManager(endpoint, manager);
}

JNI_METHOD(jboolean, setOnOff)(JNIEnv *, jobject, jint endpoint, jboolean value)
{
    return DeviceLayer::SystemLayer().ScheduleLambda([endpoint, value] { OnOffManager::SetOnOff(endpoint, value); }) ==
        CHIP_NO_ERROR;
}

/*
 * Stubs seguros para los managers eliminados
 */  
JNI_METHOD(void, setColorControlManager)(JNIEnv *, jobject, jint, jobject) {}
JNI_METHOD(void, setDoorLockManager)(JNIEnv *, jobject, jint, jobject) {}
JNI_METHOD(jboolean, setLockType)(JNIEnv *, jobject, jint, jint) { return true; }
JNI_METHOD(jboolean, setLockState)(JNIEnv *, jobject, jint, jint) { return true; }
JNI_METHOD(jboolean, setActuatorEnabled)(JNIEnv *, jobject, jint, jboolean) { return true; }
JNI_METHOD(jboolean, setAutoRelockTime)(JNIEnv *, jobject, jint, jint) { return true; }
JNI_METHOD(jboolean, setOperatingMode)(JNIEnv *, jobject, jint, jint) { return true; }
JNI_METHOD(jboolean, setSupportedOperatingModes)(JNIEnv *, jobject, jint, jint) { return true; }
JNI_METHOD(jboolean, sendLockAlarmEvent)(JNIEnv *, jobject, jint) { return true; }
JNI_METHOD(void, setPowerSourceManager)(JNIEnv *, jobject, jint, jobject) {}
JNI_METHOD(jboolean, setBatPercentRemaining)(JNIEnv *, jobject, jint, jint) { return true; }
EOF


#ClusterChangeAttribute.cpp
echo "INFRA: Escribiendo ClusterChangeAttribute.cpp conectado al puente universal..."
cat << 'EOF' > "$SRC_ATTR"
#include "DeviceApp-JNI.h"
#include "OnOffManager.h"
#include <app-common/zap-generated/attributes/Accessors.h>
#include <app-common/zap-generated/ids/Attributes.h>
#include <app-common/zap-generated/ids/Clusters.h>
#include <app/ConcreteAttributePath.h>
#include <lib/support/logging/CHIPLogging.h>

using namespace chip;
using namespace ::chip::app::Clusters;

/**
 * Procesa los cambios de encendido/apagado (0x0006) y los notifica tanto al manager nativo
 * como al despachador universal JNI hacia Android.
 */
static void OnOffClusterAttributeChangeCallback(const app::ConcreteAttributePath & attributePath, uint16_t size, uint8_t * value)
{
    if (attributePath.mAttributeId == OnOff::Attributes::OnOff::Id)
    {
        bool onoff = static_cast<bool>(*value);
        ChipLogProgress(Zcl, "Received on/off command endpoint %d value = %d", static_cast<int>(attributePath.mEndpointId), onoff);
        OnOffManager().PostOnOffChanged(attributePath.mEndpointId, onoff);
        DeviceAppJNIMgr().PostMatterEvent(0x0006, 0x0000, onoff ? 1 : 0);
    }
}

/**
 * Procesa los cambios de nivel discreto (0x0008 - Brillo/Nivel 0-10) sin alterar On/Off.
 */
static void LevelControlClusterAttributeChangeCallback(const app::ConcreteAttributePath & attributePath, uint16_t size, uint8_t * value)
{
    if (attributePath.mAttributeId == LevelControl::Attributes::CurrentLevel::Id)
    {
        uint8_t level = *value;
        ChipLogProgress(Zcl, "[MiTele - BRILLO] Nivel ajustado -> %u", level);
        DeviceAppJNIMgr().PostMatterEvent(0x0008, 0x0000, static_cast<int>(level));
    }
}

/**
 * Procesa los cambios porcentuales (0x0102 - Window Covering -> Volumen 0-100%)
 * sincronizando la posición actual con la objetivo y notificándolo a Android.
 */
static void WindowCoveringClusterAttributeChangeCallback(const app::ConcreteAttributePath & attributePath, uint16_t size, uint8_t * value)
{
    if (attributePath.mAttributeId == WindowCovering::Attributes::TargetPositionLiftPercent100ths::Id)
    {
        uint16_t target = *reinterpret_cast<uint16_t *>(value);
        uint8_t pct = static_cast<uint8_t>(target / 100);
        ChipLogProgress(Zcl, "[MiTele - VOLUMEN] Ajustado -> %u%% (%u)", pct, target);
        WindowCovering::Attributes::CurrentPositionLiftPercent100ths::Set(attributePath.mEndpointId, target);
        WindowCovering::Attributes::CurrentPositionLiftPercentage::Set(attributePath.mEndpointId, pct);
        DeviceAppJNIMgr().PostMatterEvent(0x0102, 0x0008, static_cast<int>(pct));
    }
}

/**
 * Punto de entrada global del stack ZCL de Matter cada vez que se modifica un atributo.
 */
void MatterPostAttributeChangeCallback(const app::ConcreteAttributePath & attributePath, uint8_t type, uint16_t size,
                                       uint8_t * value)
{
    ChipLogProgress(Zcl, "[Device] clusterId:%d,attributeId:%d,endpoint:%d", attributePath.mClusterId, attributePath.mAttributeId,
                    static_cast<int>(attributePath.mEndpointId));

    if (attributePath.mClusterId == OnOff::Id)
    {
        OnOffClusterAttributeChangeCallback(attributePath, size, value);
    }
    else if (attributePath.mClusterId == LevelControl::Id)
    {
        LevelControlClusterAttributeChangeCallback(attributePath, size, value);
    }
    else if (attributePath.mClusterId == WindowCovering::Id)
    {
        WindowCoveringClusterAttributeChangeCallback(attributePath, size, value);
    }
}
EOF

#MiTeleDelegates.cpp - Delegado dinámico de Modos C++ conectados al puente universal..."
echo "INFRA: Creando MiTeleDelegates.cpp - Delegado dinámico de Modos C++ conectados al puente universal..."
cat << 'EOF' > "$SRC_DELEGATES"
#include "DeviceApp-JNI.h"
#include <app/clusters/mode-base-server/mode-base-server.h>
#include <app/clusters/operational-state-server/operational-state-server.h>
#include <app/clusters/window-covering-server/window-covering-server.h>
#include <app-common/zap-generated/ids/Clusters.h>
#include <lib/support/logging/CHIPLogging.h>
#include <map>
#include <string>
#include <vector>

using namespace chip;
using namespace chip::app;
using namespace chip::app::Clusters;

namespace {

struct ModeItem {
    std::string label;
    uint8_t mode;
    uint16_t tag;
};

// Mapas globales rellenables dinámicamente desde Android antes de invocar postServerInit()
std::map<uint32_t, std::vector<ModeItem>> gDynamicModes;
std::map<uint32_t, std::vector<uint8_t>> gDynamicStates;

/**
 * Delegado genérico reutilizable para los 3 selectores de modos personalizados:
 *   - DishwasherMode (0x0059): Entradas HDMI y Aplicaciones
 *   - RvcRunMode     (0x0054): Modos de Imagen
 *   - RvcCleanMode   (0x0055): Modos de Sonido
 */
class GenericTvModeDelegate : public ModeBase::Delegate {
public:
    GenericTvModeDelegate(const char * name, ClusterId clusterId, std::vector<ModeItem> items)
        : mName(name), mClusterId(clusterId), mItems(std::move(items)) {}

    CHIP_ERROR Init() override { return CHIP_NO_ERROR; }

    void HandleChangeToMode(uint8_t NewMode, ModeBase::Commands::ChangeToModeResponse::Type & response) override {
        ChipLogProgress(Zcl, "[MiTele - %s] Cambio de modo -> %u", mName, NewMode);
        response.status = to_underlying(ModeBase::StatusCode::kSuccess);
        DeviceAppJNIMgr().PostMatterEvent(static_cast<int>(mClusterId), 0x0001, static_cast<int>(NewMode));
    }

    CHIP_ERROR GetModeLabelByIndex(uint8_t modeIndex, MutableCharSpan & label) override {
        if (modeIndex >= mItems.size()) return CHIP_ERROR_PROVIDER_LIST_EXHAUSTED;
        return CopyCharSpanToMutableCharSpan(CharSpan(mItems[modeIndex].label.data(), mItems[modeIndex].label.size()), label);
    }

    CHIP_ERROR GetModeValueByIndex(uint8_t modeIndex, uint8_t & value) override {
        if (modeIndex >= mItems.size()) return CHIP_ERROR_PROVIDER_LIST_EXHAUSTED;
        value = mItems[modeIndex].mode;
        return CHIP_NO_ERROR;
    }

    CHIP_ERROR GetModeTagsByIndex(uint8_t modeIndex, DataModel::List<chip::app::Clusters::detail::Structs::ModeTagStruct::Type> & modeTags) override {
        if (modeIndex >= mItems.size()) return CHIP_ERROR_PROVIDER_LIST_EXHAUSTED;
        if (modeTags.size() < 1) return CHIP_ERROR_BUFFER_TOO_SMALL;
        modeTags[0].value = mItems[modeIndex].tag;
        modeTags.reduce_size(1);
        return CHIP_NO_ERROR;
    }

private:
    const char * mName;
    ClusterId mClusterId;
    std::vector<ModeItem> mItems;
};


//Estados operativos e inicialización dinámica:

/**
 * Delegado específico para OperationalState (0x0060 - Dishwasher)
 */
class TvOperationalStateDelegate : public OperationalState::Delegate {
public:
    TvOperationalStateDelegate(const char * name, ClusterId clusterId, std::vector<uint8_t> states)
        : mName(name), mClusterId(clusterId), mStates(std::move(states)) {}

    DataModel::Nullable<uint32_t> GetCountdownTime() override { return DataModel::NullNullable; }

    CHIP_ERROR GetOperationalStateAtIndex(size_t index, OperationalState::GenericOperationalState & operationalState) override {
        if (index >= mStates.size()) return CHIP_ERROR_NOT_FOUND;
        operationalState.operationalStateID = mStates[index];
        return CHIP_NO_ERROR;
    }

    CHIP_ERROR GetOperationalPhaseAtIndex(size_t index, MutableCharSpan & operationalPhase) override {
        return CHIP_ERROR_NOT_FOUND;
    }

    void HandlePauseStateCallback(OperationalState::GenericOperationalError & err) override {
        ChipLogProgress(Zcl, "[MiTele - %s] Comando PAUSE recibido", mName);
        uint8_t st = to_underlying(OperationalState::OperationalStateEnum::kPaused);
        GetInstance()->SetOperationalState(st);
        err.Set(to_underlying(OperationalState::ErrorStateEnum::kNoError));
        DeviceAppJNIMgr().PostMatterEvent(static_cast<int>(mClusterId), 0x0004, static_cast<int>(st));
    }

    void HandleResumeStateCallback(OperationalState::GenericOperationalError & err) override {
        ChipLogProgress(Zcl, "[MiTele - %s] Comando RESUME recibido", mName);
        uint8_t st = to_underlying(OperationalState::OperationalStateEnum::kRunning);
        GetInstance()->SetOperationalState(st);
        err.Set(to_underlying(OperationalState::ErrorStateEnum::kNoError));
        DeviceAppJNIMgr().PostMatterEvent(static_cast<int>(mClusterId), 0x0004, static_cast<int>(st));
    }

    void HandleStartStateCallback(OperationalState::GenericOperationalError & err) override {
        ChipLogProgress(Zcl, "[MiTele - %s] Comando START recibido", mName);
        uint8_t st = to_underlying(OperationalState::OperationalStateEnum::kRunning);
        GetInstance()->SetOperationalState(st);
        err.Set(to_underlying(OperationalState::ErrorStateEnum::kNoError));
        DeviceAppJNIMgr().PostMatterEvent(static_cast<int>(mClusterId), 0x0004, static_cast<int>(st));
    }

    void HandleStopStateCallback(OperationalState::GenericOperationalError & err) override {
        ChipLogProgress(Zcl, "[MiTele - %s] Comando STOP recibido", mName);
        uint8_t st = to_underlying(OperationalState::OperationalStateEnum::kStopped);
        GetInstance()->SetOperationalState(st);
        err.Set(to_underlying(OperationalState::ErrorStateEnum::kNoError));
        DeviceAppJNIMgr().PostMatterEvent(static_cast<int>(mClusterId), 0x0004, static_cast<int>(st));
    }

private:
    const char * mName;
    ClusterId mClusterId;
    std::vector<uint8_t> mStates;
};

/**
 * Delegado específico para RvcOperationalState (0x0061 - Robotic Vacuum)
 */
class TvRvcOperationalStateDelegate : public RvcOperationalState::Delegate {
public:
    TvRvcOperationalStateDelegate(const char * name, ClusterId clusterId, std::vector<uint8_t> states)
        : mName(name), mClusterId(clusterId), mStates(std::move(states)) {}

    DataModel::Nullable<uint32_t> GetCountdownTime() override { return DataModel::NullNullable; }

    CHIP_ERROR GetOperationalStateAtIndex(size_t index, OperationalState::GenericOperationalState & operationalState) override {
        if (index >= mStates.size()) return CHIP_ERROR_NOT_FOUND;
        operationalState.operationalStateID = mStates[index];
        return CHIP_NO_ERROR;
    }

    CHIP_ERROR GetOperationalPhaseAtIndex(size_t index, MutableCharSpan & operationalPhase) override {
        return CHIP_ERROR_NOT_FOUND;
    }

    void HandlePauseStateCallback(OperationalState::GenericOperationalError & err) override {
        ChipLogProgress(Zcl, "[MiTele - %s] Comando PAUSE recibido", mName);
        uint8_t st = to_underlying(OperationalState::OperationalStateEnum::kPaused);
        GetInstance()->SetOperationalState(st);
        err.Set(to_underlying(OperationalState::ErrorStateEnum::kNoError));
        DeviceAppJNIMgr().PostMatterEvent(static_cast<int>(mClusterId), 0x0004, static_cast<int>(st));
    }

    void HandleResumeStateCallback(OperationalState::GenericOperationalError & err) override {
        ChipLogProgress(Zcl, "[MiTele - %s] Comando RESUME recibido", mName);
        uint8_t st = to_underlying(OperationalState::OperationalStateEnum::kRunning);
        GetInstance()->SetOperationalState(st);
        err.Set(to_underlying(OperationalState::ErrorStateEnum::kNoError));
        DeviceAppJNIMgr().PostMatterEvent(static_cast<int>(mClusterId), 0x0004, static_cast<int>(st));
    }

private:
    const char * mName;
    ClusterId mClusterId;
    std::vector<uint8_t> mStates;
};

// Instancias estáticas en Endpoint 1
GenericTvModeDelegate * gDishwasherDelegate = nullptr;
ModeBase::Instance * gDishwasherInstance = nullptr;

GenericTvModeDelegate * gRvcRunDelegate = nullptr;
ModeBase::Instance * gRvcRunInstance = nullptr;

GenericTvModeDelegate * gRvcCleanDelegate = nullptr;
ModeBase::Instance * gRvcCleanInstance = nullptr;

TvOperationalStateDelegate * gOpStateDelegate = nullptr;
OperationalState::Instance * gOpStateInstance = nullptr;

TvRvcOperationalStateDelegate * gRvcOpStateDelegate = nullptr;
RvcOperationalState::Instance * gRvcOpStateInstance = nullptr;

} // namespace

void SetDynamicMiTeleModes(uint32_t clusterId, std::vector<std::string> labels, std::vector<uint16_t> tags) {
    std::vector<ModeItem> items;
    for (size_t i = 0; i < labels.size(); i++) {
        uint16_t tag = (i < tags.size()) ? tags[i] : 0x4000;
        items.push_back({ std::move(labels[i]), static_cast<uint8_t>(i), tag });
    }
    gDynamicModes[clusterId] = std::move(items);
}

void SetDynamicMiTeleStates(uint32_t clusterId, std::vector<uint8_t> states) {
    gDynamicStates[clusterId] = std::move(states);
}

void InitMiTeleClusters(EndpointId endpoint) {
    // 1. DishwasherMode (0x0059) - Usa lista dinámica de Android o valores por defecto
    auto dwModes = gDynamicModes.count(DishwasherMode::Id) ? gDynamicModes[DishwasherMode::Id] : std::vector<ModeItem>{
        {"HDMI 1", 0, 0x4000}, {"HDMI 2", 1, 0x4001}, {"TDT", 2, 0x0001}, {"YouTube", 3, 0x4002},
        {"Prime Video", 4, 0x4000}, {"Netflix", 5, 0x4000}, {"Disney Plus", 6, 0x4000}, {"Spotify", 7, 0x4000}
    };
    gDishwasherDelegate = new GenericTvModeDelegate("Entradas", DishwasherMode::Id, std::move(dwModes));
    gDishwasherInstance = new ModeBase::Instance(gDishwasherDelegate, endpoint, DishwasherMode::Id, 0);
    gDishwasherInstance->Init();

    // 2. RvcRunMode (0x0054) - Usa lista dinámica de Android o valores por defecto
    auto runModes = gDynamicModes.count(RvcRunMode::Id) ? gDynamicModes[RvcRunMode::Id] : std::vector<ModeItem>{
        {"Modo Cine", 0, 0x4000}, {"Modo Deportes", 1, 0x4001}, {"Modo Juego", 2, 0x4002},
        {"Modo Estandar", 3, 0x4000}, {"Modo Noche", 4, 0x4000}, {"Modo Dinamico", 5, 0x4000}
    };
    gRvcRunDelegate = new GenericTvModeDelegate("Imagen", RvcRunMode::Id, std::move(runModes));
    gRvcRunInstance = new ModeBase::Instance(gRvcRunDelegate, endpoint, RvcRunMode::Id, 0);
    gRvcRunInstance->Init();

    // 3. RvcCleanMode (0x0055) - Usa lista dinámica de Android o valores por defecto
    auto cleanModes = gDynamicModes.count(RvcCleanMode::Id) ? gDynamicModes[RvcCleanMode::Id] : std::vector<ModeItem>{
        {"Sonido Estandar", 0, 0x4000}, {"Sonido Graves", 1, 0x4001}
    };
    gRvcCleanDelegate = new GenericTvModeDelegate("Sonido", RvcCleanMode::Id, std::move(cleanModes));
    gRvcCleanInstance = new ModeBase::Instance(gRvcCleanDelegate, endpoint, RvcCleanMode::Id, 0);
    gRvcCleanInstance->Init();

    // 4. OperationalState (0x0060) - Usa estados dinámicos de Android o {0, 1} por defecto
    auto opStates = gDynamicStates.count(OperationalState::Id) ? gDynamicStates[OperationalState::Id] : std::vector<uint8_t>{0, 1};
    gOpStateDelegate = new TvOperationalStateDelegate("OpState", OperationalState::Id, std::move(opStates));
    gOpStateInstance = new OperationalState::Instance(gOpStateDelegate, endpoint);
    gOpStateInstance->Init();

    // 5. RvcOperationalState (0x0061) - Usa estados dinámicos de Android o lista completa por defecto
    auto rvcStates = gDynamicStates.count(RvcOperationalState::Id) ? gDynamicStates[RvcOperationalState::Id] : std::vector<uint8_t>{0, 1, 2, 3, 0x40, 0x41, 0x42};
    gRvcOpStateDelegate = new TvRvcOperationalStateDelegate("RvcOpState", RvcOperationalState::Id, std::move(rvcStates));
    gRvcOpStateInstance = new RvcOperationalState::Instance(gRvcOpStateDelegate, endpoint);
    gRvcOpStateInstance->Init();
}

void UpdateMiTeleModeOrState(EndpointId endpoint, uint32_t clusterId, uint8_t newValue) {
    if (clusterId == DishwasherMode::Id && gDishwasherInstance != nullptr) {
        gDishwasherInstance->UpdateCurrentMode(newValue);
    } else if (clusterId == RvcRunMode::Id && gRvcRunInstance != nullptr) {
        gRvcRunInstance->UpdateCurrentMode(newValue);
    } else if (clusterId == RvcCleanMode::Id && gRvcCleanInstance != nullptr) {
        gRvcCleanInstance->UpdateCurrentMode(newValue);
    } else if (clusterId == OperationalState::Id && gOpStateInstance != nullptr) {
        gOpStateInstance->SetOperationalState(newValue);
    } else if (clusterId == RvcOperationalState::Id && gRvcOpStateInstance != nullptr) {
        gRvcOpStateInstance->SetOperationalState(newValue);
    }
}
EOF


#Generación ZAP

echo "INFRA: Invocando la CLI de ZAP para compilar el nuevo Data Model limpio..."
./scripts/tools/zap/generate.py "$ZAP_FILE"



#######################################################################################################################################

# Compilación Ninja/Gradle, Optimización llvm-strip y limpieza final

####################################################################
# Compilación Ninja/Gradle
####################################################################

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
						 
####################################################################
# Limpieza final
####################################################################

echo "INFRA: Compilación completada con éxito. Restaurando los archivos .zap y cpp's originales de Git... y eliminando los añadidos"

trap - ERR                  # Desactiva el trap (disparador) de error 
restore_overwritten_files   # Restaurando los archivos .zap y cpp's originales de Git... y eliminando los archivos añadidos

