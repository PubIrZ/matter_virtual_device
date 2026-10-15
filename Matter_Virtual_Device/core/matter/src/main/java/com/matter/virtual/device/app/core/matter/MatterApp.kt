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
          Timber.d("onClusterInit():clusterId:$clusterId,endpoint:$endpoint")

//INSERT BEGIN
          val currentDeviceType = matterSettings.device.deviceTypeId.toInt()

          // FILTRADO DINÁMICO: Si el cluster no corresponde al dispositivo seleccionado, nos lo saltamos
          if (!isClusterValidForDevice(clusterId, currentDeviceType)) {
            Timber.w("Cluster ID $clusterId bloqueado dinámicamente para el Device Type ID $currentDeviceType")
            return
          }
//INSERT END
		  
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

    deviceApp.preServerInit()

    chipAppServer = ChipAppServer()
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

    deviceApp.postServerInit(matterSettings.device.deviceTypeId.toInt())
  }

//INSERT BEGIN
  /**
  * Filtra dinámicamente qué clusters se permiten inicializar en base a la especificación Matter 1.6
  */
  private fun isClusterValidForDevice(clusterId: Int, deviceTypeId: Int): Boolean {
      // Definición de los Cluster Requirements obligatorios de cada Device Type IDs según la librería de dispositivos de Matter 1.6
      // https://leconiot.com/matter/1.0/device_library.html
	  return when (deviceTypeId) {
          
          // =================================================================
          // ILUMINACIÓN Y ACTUADORES (Lighting & Actuators)
          // =================================================================
          0x0100 -> { // On/Off Light
              clusterId == Clusters.ClusterId_OnOff 
          }
          0x0101 -> { // Dimmable Light
              clusterId == Clusters.ClusterId_OnOff || 
              clusterId == Clusters.ClusterId_LevelControl
          }
          0x010C -> { // Color Temperature Light
              // clusterId == Clusters.ClusterId_Groups ||			 // Es obligatorio pero NO esta previsto en la aplicación (NO hay Manager en app\core\data\repository\cluster) 
			  // clusterId == Clusters.ClusterId_Scenes ||           // Es obligatorio pero NO esta previsto en la aplicación (NO hay Manager en app\core\data\repository\cluster)
              clusterId == Clusters.ClusterId_OnOff ||
              clusterId == Clusters.ClusterId_LevelControl || 
              clusterId == Clusters.ClusterId_ColorControl
          }
          0x010D -> { // Extended Color Light (ExtendedColorLight)   
              // clusterId == Clusters.ClusterId_Groups ||			 // Es obligatorio pero NO esta previsto en la aplicación (NO hay Manager en app\core\data\repository\cluster) 
			  // clusterId == Clusters.ClusterId_Scenes ||           // Es obligatorio pero NO esta previsto en la aplicación (NO hay Manager en app\core\data\repository\cluster)
              clusterId == Clusters.ClusterId_OnOff || 
              clusterId == Clusters.ClusterId_LevelControl || 
              clusterId == Clusters.ClusterId_ColorControl
			  
          }
  
          // =================================================================
          // INTERRUPTORES Y CONTROLADORES (Switches & Controllers)
          // Nota: Los controladores suelen usar estos clusters como *Clients*, 
          // pero si tu dispositivo virtual expone atributos locales (Server), 
          // se restringen a su respectivo nivel de control.
          // =================================================================
          0x0103 -> { // On/Off Light Switch   ( OnOffLightSwitch )
		      // Aunque el ID sea de un interruptor simple, le permitimos adquirir el LevelControl		  
              clusterId == Clusters.ClusterId_OnOff
			  clusterId == Clusters.ClusterId_LevelControl           // Adicionado para probar sin añadir el dispositivo
          }
          0x0104 -> { // Dimmer Switch         ( DimmerSwitch )
              clusterId == Clusters.ClusterId_OnOff || 
              clusterId == Clusters.ClusterId_LevelControl
          }
          0x0105 -> { // Color Dimmer Switch 
              clusterId == Clusters.ClusterId_OnOff || 
              clusterId == Clusters.ClusterId_LevelControl || 
              clusterId == Clusters.ClusterId_ColorControl
          }
  
          // =================================================================
          // CLIMATIZACIÓN Y CONFORT (HVAC / Smart Energy)
          // =================================================================
          0x0301 -> { // Thermostat            ( Thermostat ) 
              clusterId == Clusters.ClusterId_Thermostat || 
              clusterId == Clusters.ClusterId_TemperatureMeasurement
          }
          0x0302 -> { // Fan Control 
              clusterId == Clusters.ClusterId_OnOff || 
              clusterId == Clusters.ClusterId_FanControl
          }
  
          // =================================================================
          // CIERRES Y ACCESOS (Closures)
          // =================================================================
          0x000A -> { // Door Lock             ( DoorLock )          // Cerradura inteligente
              clusterId == Clusters.ClusterId_DoorLock
          }
          0x0202 -> { // Window Covering       ( WindowCovering )    // Persianas / Cortinas motorizadas)
              clusterId == Clusters.ClusterId_WindowCovering
          }
  
          // =================================================================
          // SENSORES (Sensors)
          // =================================================================
          0x0015 -> { // Contact Sensor        ( ContactSensor )
              clusterId == Clusters.ClusterId_BooleanState           // Habitual en sensores binarios (FALSE=open or no contact /  TRUE=closed or contac)
          }
          0x0107 -> { // Occupancy Sensor      ( OccupancySensor )
              clusterId == Clusters.ClusterId_OccupancySensing
          }
          0x030C -> { // Temperature Sensor
              clusterId == Clusters.ClusterId_TemperatureMeasurement
          }
          0x030F -> { // Humidity Sensor
              clusterId == Clusters.ClusterId_RelativeHumidityMeasurement
          }
  
          // =================================================================
          // DISPOSITIVOS MULTIMEDIA (Media / Video Player)
          // =================================================================
          0x0028 -> { // Basic Video Player    (VideoPlayer) // Smart TV / Smart Box
		      clusterId == Clusters.ClusterId_OnOff ||
			  clusterId == Clusters.ClusterId_MediaPlayback ||
              clusterId == Clusters.ClusterId_KeypadInput

          }
  
          0x0023 -> { // Castin Video Player    (CastingVideoPlayer) // Smart TV (Streaming) / Smart Box (Streaming)
		      clusterId == Clusters.ClusterId_OnOff ||
			  clusterId == Clusters.ClusterId_MediaPlayback ||
              clusterId == Clusters.ClusterId_KeypadInput
              //clusterId == Clusters.ClusterId_ContentLauncher      // Es obligatorio pero NO esta previsto en la aplicación (NO hay Manager en app\core\data\repository\cluster)
			  
              //clusterId == Clusters.ClusterId_LowPower ||
              //clusterId == Clusters.ClusterId_Channel  ||  
              //clusterId == Clusters.ClusterId_WakeOnLan ||
              //clusterId == Clusters.ClusterId_MediaInput			  
          }
	  
		  
          // =================================================================
          // FILTRO COMPLEMENTARIO (Fallback / Default)
          // =================================================================
          else -> {
              // Clusters transversales a todos los dispositivos en Matter (ej: Infraestructura)
              val isInfrastructureCluster = clusterId == Clusters.ClusterId_NetworkCommissioning || 
                                            clusterId == Clusters.ClusterId_PowerSource
              
              if (isInfrastructureCluster) {
                  true
              } else {
                  // Si añades prototipos dinámicos custom no mapeados arriba, 
                  // Timber registrará una alerta para que decidas si bloquearlo o no.
                  Timber.w("DeviceType desconocido ($deviceTypeId). Permitiendo cluster $clusterId de forma preventiva.")
                  true 
              }
          }
      }
  }

//INSERT END


  fun stop() {
    chipAppServer?.stopApp()
  }

  fun reset() {
    chipAppServer?.resetApp()
  }

  fun addDeviceEventCallback(deviceEventCallback: MatterDeviceEventCallback) {
    Timber.d("Hit")
    if (!this.deviceEventCallbackList.contains(deviceEventCallback)) {
      Timber.d("Add")
      this.deviceEventCallbackList.add(deviceEventCallback)
    }
  }

  fun removeDeviceEventCallback(deviceEventCallback: MatterDeviceEventCallback) {
    Timber.d("Hit")
    if (this.deviceEventCallbackList.contains(deviceEventCallback)) {
      Timber.d("Remove")
      this.deviceEventCallbackList.remove(deviceEventCallback)
    }
  }
}
