package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.ThermostatManager
import com.matter.virtual.device.app.core.common.MatterConstants
import com.matter.virtual.device.app.core.model.matter.ThermostatRunningMode
import com.matter.virtual.device.app.core.model.matter.ThermostatSystemMode
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class ThermostatManagerStub @Inject constructor(private val deviceApp: DeviceApp) :
  ThermostatManager {

  private val _localTemperature = MutableStateFlow(DEFAULT_TEMPERATURE)
  val localTemperature: StateFlow<Int>
    get() = _localTemperature

  private val _systemMode = MutableStateFlow(ThermostatSystemMode.HEAT)
  val systemMode: StateFlow<ThermostatSystemMode>
    get() = _systemMode

  private val _thermostatRunningState = MutableStateFlow(ThermostatRunningMode.HEAT)
  val thermostatRunningState: StateFlow<ThermostatRunningMode>
    get() = _thermostatRunningState

  private val _occupiedHeatingSetpoint = MutableStateFlow(DEFAULT_OCCUPIED_HEATING_TEMPERATURE)
  val occupiedHeatingSetpoint: StateFlow<Int>
    get() = _occupiedHeatingSetpoint

  private var _occupiedCoolingSetpoint = MutableStateFlow(DEFAULT_OCCUPIED_COOLING_TEMPERATURE)
  val occupiedCoolingSetpoint: StateFlow<Int>
    get() = _occupiedCoolingSetpoint

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("endpoint:$endpoint")
    deviceApp.setThermostatFeatureMap(endpoint, ThermostatManager.ThermostatFeatureMap_kAll)
    deviceApp.setLocalTemperature(endpoint, DEFAULT_TEMPERATURE)
    deviceApp.setAbsMaxCoolSetpointLimit(
      endpoint,
      ThermostatManager.MaxCoolSetpointLimit_kSmartThingsCapabilitiesMax
    )
    deviceApp.setMaxCoolSetpointLimit(
      endpoint,
      ThermostatManager.MaxCoolSetpointLimit_kSmartThingsCapabilitiesMax
    )
    deviceApp.setAbsMinCoolSetpointLimit(
      endpoint,
      ThermostatManager.MinCoolSetpointLimit_kSmartThingsCapabilitiesMin
    )
    deviceApp.setMinCoolSetpointLimit(
      endpoint,
      ThermostatManager.MinCoolSetpointLimit_kSmartThingsCapabilitiesMin
    )
    deviceApp.setAbsMaxHeatSetpointLimit(
      endpoint,
      ThermostatManager.MaxHeatSetpointLimit_kSmartThingsCapabilitiesMax
    )
    deviceApp.setMaxHeatSetpointLimit(
      endpoint,
      ThermostatManager.MaxHeatSetpointLimit_kSmartThingsCapabilitiesMax
    )
    deviceApp.setAbsMinHeatSetpointLimit(
      endpoint,
      ThermostatManager.MinHeatSetpointLimit_kSmartThingsCapabilitiesMix
    )
    deviceApp.setMinHeatSetpointLimit(
      endpoint,
      ThermostatManager.MinHeatSetpointLimit_kSmartThingsCapabilitiesMix
    )
    deviceApp.setOccupiedHeatingSetpoint(endpoint, DEFAULT_OCCUPIED_HEATING_TEMPERATURE)
    deviceApp.setOccupiedCoolingSetpoint(endpoint, DEFAULT_OCCUPIED_COOLING_TEMPERATURE)
    deviceApp.setSystemMode(endpoint, ThermostatManager.ThermostatSystemMode_kHeat)
    deviceApp.setThermostatRunningState(endpoint, ThermostatManager.ThermostatRunningMode_kHeat)
    deviceApp.setControlSequenceOfOperation(
      endpoint,
      ThermostatManager.ThermostatControlSequence_kCoolingAndHeating
    )
  }

  override fun handleSystemModeChanged(value: Int) {
    Timber.d("value:$value")
    _systemMode.value = value.asThermostatSystemMode()
  }

  override fun handleThermostatRunningStateChanged(value: Int) {
    Timber.d("value:$value")
    _thermostatRunningState.value = value.asThermostatRunningMode()
  }

  override fun handleOccupiedHeatingSetpointChanged(value: Int) {
    Timber.d("value:$value")
    _occupiedHeatingSetpoint.value = value
  }

  override fun handleOccupiedCoolingSetpointChanged(value: Int) {
    Timber.d("value:$value")
    _occupiedCoolingSetpoint.value = value
  }

  override fun handleLocalTemperatureChanged(value: Int) {
    Timber.d("value:$value")
    _localTemperature.value = value
  }

  fun setLocalTemperature(value: Int) {
    Timber.d("value:$value")
    deviceApp.setLocalTemperature(MatterConstants.DEFAULT_ENDPOINT, value)
  }

  fun setSystemMode(mode: ThermostatSystemMode) {
    Timber.d("mode:$mode")
    deviceApp.setSystemMode(MatterConstants.DEFAULT_ENDPOINT, mode.value)
  }

  fun setThermostatRunningState(mode: ThermostatRunningMode) {
    Timber.d("mode:$mode")
    deviceApp.setThermostatRunningState(MatterConstants.DEFAULT_ENDPOINT, mode.value)
  }

  fun setOccupiedHeatingSetpoint(value: Int) {
    Timber.d("value:$value")
    deviceApp.setOccupiedHeatingSetpoint(MatterConstants.DEFAULT_ENDPOINT, value)
  }

  fun setOccupiedCoolingSetpoint(value: Int) {
    Timber.d("value:$value")
    deviceApp.setOccupiedCoolingSetpoint(MatterConstants.DEFAULT_ENDPOINT, value)
  }

  companion object {
    private const val DEFAULT_TEMPERATURE = 2100 // Temp * 100
    private const val DEFAULT_OCCUPIED_HEATING_TEMPERATURE = 2000
    private const val DEFAULT_OCCUPIED_COOLING_TEMPERATURE = 2600
  }
}

fun Int.asThermostatSystemMode() =
  when (this) {
    ThermostatManager.ThermostatSystemMode_kOff -> ThermostatSystemMode.OFF
    ThermostatManager.ThermostatSystemMode_kAuto -> ThermostatSystemMode.AUTO
    ThermostatManager.ThermostatSystemMode_kCool -> ThermostatSystemMode.COOL
    ThermostatManager.ThermostatSystemMode_kHeat -> ThermostatSystemMode.HEAT
    ThermostatManager.ThermostatSystemMode_kEmergencyHeating ->
      ThermostatSystemMode.EMERGENCY_HEATING
    ThermostatManager.ThermostatSystemMode_kPrecooling -> ThermostatSystemMode.PRECOOLING
    ThermostatManager.ThermostatSystemMode_kFanOnly -> ThermostatSystemMode.FAN_ONLY
    else -> ThermostatSystemMode.OFF
  }

fun Int.asThermostatRunningMode() =
  when (this) {
    ThermostatManager.ThermostatRunningMode_kHeat -> ThermostatRunningMode.HEAT
    ThermostatManager.ThermostatRunningMode_kCool -> ThermostatRunningMode.COOL
    ThermostatManager.ThermostatRunningMode_kFan -> ThermostatRunningMode.FAN
    else -> ThermostatRunningMode.HEAT
  }
