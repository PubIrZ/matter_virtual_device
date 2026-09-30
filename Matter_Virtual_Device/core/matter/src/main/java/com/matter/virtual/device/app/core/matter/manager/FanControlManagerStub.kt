package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.FanControlManager
import com.matter.virtual.device.app.core.common.MatterConstants
import com.matter.virtual.device.app.core.model.matter.FanControlFanMode
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class FanControlManagerStub @Inject constructor(private val deviceApp: DeviceApp) :
  FanControlManager {

  private val _fanMode = MutableStateFlow(FanControlFanMode.OFF)
  val fanMode: StateFlow<FanControlFanMode>
    get() = _fanMode

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("endpoint:$endpoint")
    deviceApp.setFanControlFeatureMap(endpoint, FanControlManager.FanControlFeatureMap_kAll)
    deviceApp.setFanMode(endpoint, FanControlManager.FanControlFanMode_kAuto)
    deviceApp.setFanModeSequence(endpoint, FanControlManager.FanModeSequence_kOff_Low_Med_High_Auto)
  }

  override fun handleFanModeChanged(endpoint: Int, value: Int) {
    Timber.d("value:$value")
    _fanMode.value = value.asFacControlFacMode()
  }

  fun setFanMode(mode: FanControlFanMode) {
    Timber.d("mode:$mode")
    deviceApp.setFanMode(MatterConstants.DEFAULT_ENDPOINT, mode.value)
  }
}

fun Int.asFacControlFacMode() =
  when (this) {
    FanControlManager.FanControlFanMode_kOff -> FanControlFanMode.OFF
    FanControlManager.FanControlFanMode_kLow -> FanControlFanMode.LOW
    FanControlManager.FanControlFanMode_kMedium -> FanControlFanMode.MEDIUM
    FanControlManager.FanControlFanMode_kHigh -> FanControlFanMode.HIGH
    FanControlManager.FanControlFanMode_kOn -> FanControlFanMode.ON
    FanControlManager.FanControlFanMode_kAuto -> FanControlFanMode.AUTO
    FanControlManager.FanControlFanMode_kSmart -> FanControlFanMode.SMART
    else -> FanControlFanMode.OFF
  }
