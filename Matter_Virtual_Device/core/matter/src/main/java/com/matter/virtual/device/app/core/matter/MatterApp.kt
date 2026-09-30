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
