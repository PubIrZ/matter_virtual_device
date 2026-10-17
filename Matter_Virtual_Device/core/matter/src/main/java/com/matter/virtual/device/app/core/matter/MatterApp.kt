package com.matter.virtual.device.app.core.matter

import android.content.Context
import chip.appserver.ChipAppServer
import chip.appserver.ChipAppServerDelegate
import chip.platform.AndroidBleManager
import chip.platform.AndroidChipPlatform
import chip.platform.ChipMdnsCallbackImpl
import chip.platform.ChipWiFiCallbackImpl
import chip.platform.DiagnosticDataProviderImpl
import chip.platform.NsdManagerServiceBrowser
import chip.platform.NsdManagerServiceResolver
import chip.platform.PreferencesKeyValueStoreManager
import com.matter.virtual.device.app.ChannelManagerStub
import com.matter.virtual.device.app.Clusters
import com.matter.virtual.device.app.ContentLaunchManagerStub
import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.DeviceAppCallback
import com.matter.virtual.device.app.DeviceEventType
import com.matter.virtual.device.app.LowPowerManagerStub
import com.matter.virtual.device.app.MediaInputManagerStub
import com.matter.virtual.device.app.NetworkCommissioningManagerStub
import com.matter.virtual.device.app.WakeOnLanManagerStub
import com.matter.virtual.device.app.core.common.MatterConstants
import com.matter.virtual.device.app.core.common.MatterSettings
import com.matter.virtual.device.app.core.common.matter.CustomWiFiManagerImpl
import com.matter.virtual.device.app.core.common.matter.CustomWifiManagerCallback
import com.matter.virtual.device.app.core.matter.manager.BooleanStateManagerStub
import com.matter.virtual.device.app.core.matter.manager.ColorControlManagerStub
import com.matter.virtual.device.app.core.matter.manager.DoorLockManagerStub
import com.matter.virtual.device.app.core.matter.manager.FanControlManagerStub
import com.matter.virtual.device.app.core.matter.manager.KeypadInputManagerStub
import com.matter.virtual.device.app.core.matter.manager.LevelManagerStub
import com.matter.virtual.device.app.core.matter.manager.MediaPlaybackManagerStub
import com.matter.virtual.device.app.core.matter.manager.OccupancySensingManagerStub
import com.matter.virtual.device.app.core.matter.manager.OnOffManagerStub
import com.matter.virtual.device.app.core.matter.manager.PowerSourceManagerStub
import com.matter.virtual.device.app.core.matter.manager.RelativeHumidityMeasurementManagerStub
import com.matter.virtual.device.app.core.matter.manager.TemperatureMeasurementManagerStub
import com.matter.virtual.device.app.core.matter.manager.ThermostatManagerStub
import com.matter.virtual.device.app.core.matter.manager.WindowCoveringManagerStub
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber

@Singleton
class MatterApp
@Inject
constructor(
  @ApplicationContext private val context: Context,
  private val deviceApp: DeviceApp,
  private val booleanStateManagerStub: BooleanStateManagerStub,
  private val colorControlManagerStub: ColorControlManagerStub,
  private val doorLockManagerStub: DoorLockManagerStub,
  private val fanControlManagerStub: FanControlManagerStub,
  private val keypadInputManagerStub: KeypadInputManagerStub,
  private val levelManagerStub: LevelManagerStub,
  private val mediaPlaybackManagerStub: MediaPlaybackManagerStub,
  private val occupancySensingManagerStub: OccupancySensingManagerStub,
  private val onOffManagerStub: OnOffManagerStub,
  private val powerSourceManagerStub: PowerSourceManagerStub,
  private val relativeHumidityMeasurementManagerStub: RelativeHumidityMeasurementManagerStub,
  private val temperatureMeasurementManagerStub: TemperatureMeasurementManagerStub,
  private val thermostatManagerStub: ThermostatManagerStub,
  private val windowCoveringManagerStub: WindowCoveringManagerStub
) {

  private var androidChipPlatform: AndroidChipPlatform? = null
  private var chipAppServer: ChipAppServer? = null
  private val deviceEventCallbackList = ArrayList<MatterDeviceEventCallback>()

  fun start(matterSettings: MatterSettings) {
    Timber.d("start():$matterSettings")

    deviceApp.setCallback(
      object : DeviceAppCallback {
        override fun onClusterInit(app: DeviceApp, clusterId: Int, endpoint: Int) {
          
          val currentDeviceType = matterSettings.device.deviceTypeId.toInt()
          
          val clusterHex = "0x${clusterId.toString(16).uppercase()}"
          val deviceTypeHex = "0x${currentDeviceType.toString(16).uppercase()}"

          // MENSAJE DE INSPECCIÓN: Captura el momento exacto en el que el .so invoca el clúster
          Timber.i("🔍 INSPECCIÓN JNI :: El binario (.so) solicitó inicializar el Cluster $clusterHex en el Endpoint $endpoint")

          // FILTRADO DINÁMICO: Evaluamos si el clúster es legal para este Device Type ID
          if (!isClusterValidForDevice(clusterId, currentDeviceType)) {
             Timber.w("❌ AUDITORÍA :: Device Type $deviceTypeHex -> Cluster $clusterHex BLOQUEADO dinámicamente")
             return
          } else {
             Timber.w("✅ AUDITORÍA :: Device Type $deviceTypeHex -> Cluster $clusterHex ACTIVADO dinámicamente")
          }

          // * Registrar el "ManagerStub" que expone la lógica de negocio de cada clúster del dispositivo virtual.
          //      Los métodos tipo "set[Clúster]Manager()" actúan como funciones de registro de la interfaz JNI de DeviceApp (SDK nativo).
          //      Estas pasarelas asocian las implementaciones en Kotlin ("Stubs") con el motor de ejecución en C++, delegando 
          //      en la aplicación el procesamiento local de los comandos RPC entrantes desde la red Matter.
          // * Inicializar los atributos del modelo de datos y publicar el estado del servidor en la red mediante "initAttributeValue()".
          when (clusterId) {
            Clusters.ClusterId_KeypadInput ->
              app.setKeypadInputManager(endpoint, keypadInputManagerStub)
            Clusters.ClusterId_WakeOnLan ->
              app.setWakeOnLanManager(endpoint, WakeOnLanManagerStub(endpoint))
            Clusters.ClusterId_MediaInput ->
              app.setMediaInputManager(endpoint, MediaInputManagerStub(endpoint))
            Clusters.ClusterId_ContentLauncher ->
              app.setContentLaunchManager(endpoint, ContentLaunchManagerStub(endpoint))
            Clusters.ClusterId_LowPower ->
              app.setLowPowerManager(endpoint, LowPowerManagerStub(endpoint))
            Clusters.ClusterId_MediaPlayback ->
              app.setMediaPlaybackManager(endpoint, mediaPlaybackManagerStub)
            Clusters.ClusterId_Channel ->
              app.setChannelManager(endpoint, ChannelManagerStub(endpoint))
            Clusters.ClusterId_OnOff -> {
              app.setOnOffManager(endpoint, onOffManagerStub)
              onOffManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_DoorLock -> {
              app.setDoorLockManager(endpoint, doorLockManagerStub)
              doorLockManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_PowerSource -> {
              app.setPowerSourceManager(endpoint, powerSourceManagerStub)
              powerSourceManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_LevelControl -> app.setLevelManager(endpoint, levelManagerStub)
            Clusters.ClusterId_WindowCovering -> {
              app.setWindowCoveringManager(endpoint, windowCoveringManagerStub)
              windowCoveringManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_TemperatureMeasurement -> {
              app.setTemperatureMeasurementManager(endpoint, temperatureMeasurementManagerStub)
              temperatureMeasurementManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_RelativeHumidityMeasurement -> {
              app.setRelativeHumidityMeasurementManager(
                endpoint,
                relativeHumidityMeasurementManagerStub
              )
              relativeHumidityMeasurementManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_NetworkCommissioning ->
              app.setNetworkCommissioningManager(
                endpoint,
                NetworkCommissioningManagerStub(endpoint)
              )
            Clusters.ClusterId_Thermostat -> {
              app.setThermostatManager(endpoint, thermostatManagerStub)
              thermostatManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_FanControl -> {
              app.setFanControlManager(endpoint, fanControlManagerStub)
              fanControlManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_ColorControl -> {
              app.setColorControlManager(endpoint, colorControlManagerStub)
              colorControlManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_OccupancySensing -> {
              app.setOccupancySensingManager(endpoint, occupancySensingManagerStub)
              occupancySensingManagerStub.initAttributeValue(endpoint)
            }
            Clusters.ClusterId_BooleanState -> {
              app.setBooleanStateManager(endpoint, booleanStateManagerStub)
              booleanStateManagerStub.initAttributeValue(endpoint)
            }
          }
        }
        override fun onEvent(event: Int) {
          Timber.d("onEvent():event:$event")

          when (event) {
            DeviceEventType.EventId_DnssdInitialized -> {
              Timber.d("DNS-SD Platform Initialized")
            }
            DeviceEventType.EventId_CHIPoBLEConnectionEstablished -> {
              Timber.d("BLE Connection Established")
            }
            DeviceEventType.EventId_CommissioningComplete -> {
              Timber.d("Commissioning Complete")
              deviceEventCallbackList.forEach { callback -> callback.onCommissioningCompleted() }
            }
            DeviceEventType.EventId_FabricRemoved -> {
              Timber.d("Fabric Removed")
              deviceEventCallbackList.forEach { callback -> callback.onFabricRemoved() }
            }
          }
        }
      }
    )

    androidChipPlatform =
      AndroidChipPlatform(
        CustomWiFiManagerImpl(
          context,
          object : CustomWifiManagerCallback {
            override fun onWifiNotConnected() {}
          }
        ),
        ChipWiFiCallbackImpl(),
        AndroidBleManager().apply {
          configureBle(false)
          setContext(context)
        },
        PreferencesKeyValueStoreManager(context),
        MatterPreferencesConfigurationManager(
          context,
          matterSettings.device.deviceTypeId,
          context.resources.getString(matterSettings.device.deviceNameResId),
          matterSettings.discriminator
        ),
        NsdManagerServiceResolver(context),
        NsdManagerServiceBrowser(context),
        ChipMdnsCallbackImpl(),
        DiagnosticDataProviderImpl(context)
      )

    androidChipPlatform?.updateCommissionableDataProviderData(
      MatterConstants.TEST_SPAKE2P_VERIFIER,
      MatterConstants.TEST_SPAKE2P_SALT,
      MatterConstants.TEST_SPAKE2P_ITERATION_COUNT,
      MatterConstants.TEST_SETUP_PASSCODE,
      matterSettings.discriminator
    )

    Timber.d("🚀 AUDITORÍA MATTER :: Fase 1: Ejecutando deviceApp.preServerInit()...")
    deviceApp.preServerInit()

    chipAppServer = ChipAppServer()
    
    Timber.d("🚀 AUDITORÍA MATTER :: Fase 2: Ejecutando chipAppServer.startAppWithDelegate(). Se levanta la red.")
    chipAppServer?.startAppWithDelegate(
      object : ChipAppServerDelegate {
        override fun onCommissioningSessionStarted() {
          Timber.d("onCommissioningSessionStarted()")
          deviceEventCallbackList.forEach { callback ->
            callback.onCommissioningSessionEstablishmentStarted()
          }
        }

        override fun onCommissioningSessionStopped() {
          Timber.d("onCommissioningSessionStopped()")
        }

        override fun onCommissioningWindowOpened() {
          Timber.d("onCommissioningWindowOpened()")
        }

        override fun onCommissioningWindowClosed() {
          Timber.d("onCommissioningWindowClosed()")
        }
      }
    )

    val targetDeviceType = matterSettings.device.deviceTypeId.toInt()
    Timber.d("🚀 AUDITORÍA MATTER :: Fase 3: Ejecutando deviceApp.postServerInit() para Device ID: 0x${targetDeviceType.toString(16).uppercase()}")
    deviceApp.postServerInit(targetDeviceType)
  }

  /**
   * Filtra dinámicamente qué clústeres son válidos según las especificaciones de la librería Matter 1.6
   */
  private fun isClusterValidForDevice(clusterId: Int, deviceTypeId: Int): Boolean {
    return when (deviceTypeId) {
        // =================================================================
        // INTERRUPTOR ON/OFF ESTÁNDAR (0x0103)
        // =================================================================
        0x0103 -> {
            clusterId == Clusters.ClusterId_OnOff
        }

        // =================================================================
        // MAPEO DEL POOL DINÁMICO (Resto del catálogo del proyecto)
        // =================================================================
        0x0100 -> clusterId == Clusters.ClusterId_OnOff // On/Off Light
        0x0101 -> clusterId == Clusters.ClusterId_OnOff || clusterId == Clusters.ClusterId_LevelControl // Dimmable Light
        0x010C, 0x010D -> { // Color Temperature & Extended Color Light
            clusterId == Clusters.ClusterId_OnOff || 
            clusterId == Clusters.ClusterId_LevelControl || 
            clusterId == Clusters.ClusterId_ColorControl
        }
        0x0301 -> clusterId == Clusters.ClusterId_Thermostat || clusterId == Clusters.ClusterId_TemperatureMeasurement // Thermostat
        0x0202 -> clusterId == Clusters.ClusterId_WindowCovering // Window Covering
        0x000A -> clusterId == Clusters.ClusterId_DoorLock // Door Lock
        0x0015 -> clusterId == Clusters.ClusterId_BooleanState // Contact Sensor
        0x0106 -> clusterId == Clusters.ClusterId_OccupancySensing // Occupancy Sensor
        0x0028 -> { // Video Player / Smart TV
            clusterId == Clusters.ClusterId_KeypadInput ||
            clusterId == Clusters.ClusterId_WakeOnLan ||
            clusterId == Clusters.ClusterId_MediaInput ||
            clusterId == Clusters.ClusterId_ContentLauncher ||
            clusterId == Clusters.ClusterId_LowPower ||
            clusterId == Clusters.ClusterId_MediaPlayback ||
            clusterId == Clusters.ClusterId_Channel
        }

        // =================================================================
        // INFRAESTRUCTURA GENERAL REQUERIDA (Siempre activos)
        // =================================================================
        else -> {
            val isInfrastructureCluster = clusterId == Clusters.ClusterId_NetworkCommissioning || 
                                          clusterId == Clusters.ClusterId_PowerSource
            if (isInfrastructureCluster) {
                true
            } else {
                Timber.w("DeviceType secundario no indexado ($deviceTypeId). Permitiendo cluster $clusterId preventivamente.")
                false
            }
        }
    }
  }

  fun stop() {
    chipAppServer?.stopApp()
  }

  fun reset() {
    chipAppServer?.resetApp()
  }

  fun addDeviceEventCallback(deviceEventCallback: MatterDeviceEventCallback) {
    Timber.d("Hit - ORI")
    if (!this.deviceEventCallbackList.contains(deviceEventCallback)) {
      Timber.d("Add - ORI")
      this.deviceEventCallbackList.add(deviceEventCallback)
    }
  }

  fun removeDeviceEventCallback(deviceEventCallback: MatterDeviceEventCallback) {
    Timber.d("Hit ORI")
    if (this.deviceEventCallbackList.contains(deviceEventCallback)) {
      Timber.d("Remove - ORI")
      this.deviceEventCallbackList.remove(deviceEventCallback)
    }
  }
}
