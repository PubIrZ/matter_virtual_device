package com.matter.virtual.device.app.feature.hvac

import androidx.lifecycle.LiveData
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.asLiveData
import androidx.lifecycle.viewModelScope
import com.matter.virtual.device.app.core.common.result.successOr
import com.matter.virtual.device.app.core.domain.usecase.matter.IsFabricRemovedUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.StartMatterAppServiceUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.fancontrol.GetFanModeFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.fancontrol.SetFanModeUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.powersource.GetBatPercentRemainingUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.powersource.SetBatPercentRemainingUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.relativehumiditymeasurement.GetRelativeHumidityUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.relativehumiditymeasurement.SetRelativeHumidityUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat.GetLocalTemperatureUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat.GetOccupiedCoolingSetpointFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat.GetOccupiedHeatingSetpointFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat.GetSystemModeFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat.SetLocalTemperatureUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat.SetOccupiedCoolingSetpointUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat.SetOccupiedHeatingSetpointUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat.SetSystemModeUseCase
import com.matter.virtual.device.app.core.model.matter.FanControlFanMode
import com.matter.virtual.device.app.core.model.matter.ThermostatSystemMode
import com.matter.virtual.device.app.core.ui.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import timber.log.Timber

@HiltViewModel
class ThermostatViewModel
@Inject
constructor(
  getLocalTemperatureUseCase: GetLocalTemperatureUseCase,
  getRelativeHumidityUseCase: GetRelativeHumidityUseCase,
  getSystemModeFlowUseCase: GetSystemModeFlowUseCase,
  getOccupiedCoolingSetpointFlowUseCase: GetOccupiedCoolingSetpointFlowUseCase,
  getOccupiedHeatingSetpointFlowUseCase: GetOccupiedHeatingSetpointFlowUseCase,
  getBatPercentRemainingUseCase: GetBatPercentRemainingUseCase,
  getFanModeFlowUseCase: GetFanModeFlowUseCase,
  private val startMatterAppServiceUseCase: StartMatterAppServiceUseCase,
  private val isFabricRemovedUseCase: IsFabricRemovedUseCase,
  private val setLocalTemperatureUseCase: SetLocalTemperatureUseCase,
  private val setBatPercentRemainingUseCase: SetBatPercentRemainingUseCase,
  private val setSystemModeUseCase: SetSystemModeUseCase,
  private val setOccupiedCoolingSetpointUseCase: SetOccupiedCoolingSetpointUseCase,
  private val setOccupiedHeatingSetpointUseCase: SetOccupiedHeatingSetpointUseCase,
  private val setFanModeUseCase: SetFanModeUseCase,
  private val setRelativeHumidityUseCase: SetRelativeHumidityUseCase,
  savedStateHandle: SavedStateHandle
) : BaseViewModel(savedStateHandle) {

  init {
    viewModelScope.launch { startMatterAppServiceUseCase(matterSettings) }

    viewModelScope.launch {
      val isFabricRemoved = isFabricRemovedUseCase().successOr(false)
      if (isFabricRemoved) {
        Timber.d("Fabric Removed")
        onFabricRemoved()
      }
    }
  }
  // ===================================================================================
  // [CODELAB] Get cluster value : Thermostat
  // The current status of the temperature. The int value is used by the [ThermostatFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _temperature: MutableStateFlow<Int> =
    getLocalTemperatureUseCase() as MutableStateFlow<Int>
  val temperature: LiveData<Int>
    get() = _temperature.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : Thermostat
  // The current status of the humidity. The int value is used by the [ThermostatFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _humidity: MutableStateFlow<Int> =
    getRelativeHumidityUseCase() as MutableStateFlow<Int>
  val humidity: LiveData<Int>
    get() = _humidity.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : Thermostat
  // The current status of the system mode. The enum value is used by the [ThermostatFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _systemMode: StateFlow<ThermostatSystemMode> = getSystemModeFlowUseCase()
  val systemMode: LiveData<ThermostatSystemMode>
    get() = _systemMode.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : Thermostat
  // The current status of the fan mode. The enum value is used by the [ThermostatFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _fanMode: StateFlow<FanControlFanMode> = getFanModeFlowUseCase()
  val fanMode: LiveData<FanControlFanMode>
    get() = _fanMode.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : Thermostat
  // The current status of the cooling setpoint. The int value is used by the [ThermostatFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _occupiedCoolingSetpoint: StateFlow<Int> = getOccupiedCoolingSetpointFlowUseCase()
  val occupiedCoolingSetpoint: LiveData<Int>
    get() = _occupiedCoolingSetpoint.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : Thermostat
  // The current status of the heating setpoint. The int value is used by the [ThermostatFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _occupiedHeatingSetpoint: StateFlow<Int> = getOccupiedHeatingSetpointFlowUseCase()
  val occupiedHeatingSetpoint: LiveData<Int>
    get() = _occupiedHeatingSetpoint.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : Thermostat
  // The current status of the battery. The int value is used by the [ThermostatFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _batteryStatus: MutableStateFlow<Int> =
    getBatPercentRemainingUseCase() as MutableStateFlow<Int>
  val batteryStatus: LiveData<Int>
    get() = _batteryStatus.asLiveData()
  // ===================================================================================

  override fun onCleared() {
    Timber.d("Hit")
    super.onCleared()
  }

  fun updateHumiditySeekbarProgress(progress: Int) {
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Humidity" seekbar in the [ThermostatFragment]
    // [humidity] store the current status of the humidity to indicate the progress.
    // -----------------------------------------------------------------------------------
    _humidity.value = progress * 100
    // ===================================================================================
  }

  fun updateHumidityToCluster(progress: Int) {
    Timber.d("progress:$progress")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Humidity" seekbar in the [ThermostatFragment]
    // [updateHumiditySeekbarProgress] update the current status of the humidity to indicate the
    // progress.
    // [SetRelativeHumidityUseCase] will update the int value of the new humidity status. ([0...100]
    // * 100)
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      updateHumiditySeekbarProgress(progress)
      setRelativeHumidityUseCase(progress * 100)
    }
    // ===================================================================================
  }

  fun updateTemperatureSeekbarProgress(progress: Int) {
    Timber.d("progress:$progress")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Temperature" seekbar in the [ThermostatFragment]
    // [temperature] store the current status of the temperature to indicate the progress.
    // -----------------------------------------------------------------------------------
    _temperature.value = progress * 100
    // ===================================================================================
  }

  fun updateTemperatureToCluster(progress: Int) {
    Timber.d("progress:$progress")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Temperature" seekbar in the [ThermostatFragment]
    // [updateTemperatureSeekbarProgress] update the current status of the temperature to indicate
    // the progress.
    // [SetLocalTemperatureUseCase] will update the int value of the new temperature status.
    // ([value] * 100)
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      updateTemperatureSeekbarProgress(progress)
      setLocalTemperatureUseCase(progress * 100)
    }
    // ====================================================================================
  }

  fun updateBatterySeekbarProgress(progress: Int) {
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Battery" seekbar in the [ThermostatFragment]
    // [batteryStatus] store the current status of the battery to indicate the progress.
    // -----------------------------------------------------------------------------------
    _batteryStatus.value = progress
    // ====================================================================================
  }

  fun updateBatteryStatusToCluster(progress: Int) {
    Timber.d("progress:$progress")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Battery" seekbar in the [ThermostatFragment]
    // [updateBatterySeekbarProgress] update the current status of the battery to indicate the
    // progress.
    // [SetBatPercentRemainingUseCase] will update the int value of the new battery status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      updateBatterySeekbarProgress(progress)
      setBatPercentRemainingUseCase(progress)
    }
    // ====================================================================================
  }

  fun setSystemMode(systemMode: ThermostatSystemMode) {
    Timber.d("systemMode:$systemMode")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "SystemMode" popup in the [ThermostatFragment]
    // [SetSystemModeUseCase] will update the enum value of the new system mode status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch { setSystemModeUseCase(systemMode) }
    // ====================================================================================
  }

  fun setFanMode(fanMode: FanControlFanMode) {
    Timber.d("fanMode:$fanMode")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "FanMode" popup in the [ThermostatFragment]
    // [SetFanModeUseCase] will update the enum value of the new fan mode status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch { setFanModeUseCase(fanMode) }
    // ====================================================================================
  }

  fun onClickHeatingPlus() {
    Timber.d("Hit")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Heating Plus" button in the [fragment_thermostat.xml]
    // [SetOccupiedHeatingSetpointUseCase] will update the int value of the +1 degree. ([degree] *
    // 100)
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      val nextValue = _occupiedHeatingSetpoint.value + 100
      Timber.d("current value = ${_occupiedHeatingSetpoint.value} set value = $nextValue")
      setOccupiedHeatingSetpointUseCase(nextValue)
    }
    // ====================================================================================
  }

  fun onClickHeatingMinus() {
    Timber.d("Hit")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Heating Minus" button in the [fragment_thermostat.xml]
    // [SetOccupiedHeatingSetpointUseCase] will update the int value of the -1 degree. ([degree] *
    // 100)
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      val nextValue = _occupiedHeatingSetpoint.value - 100
      Timber.d("current value = ${_occupiedHeatingSetpoint.value} set value = $nextValue")
      setOccupiedHeatingSetpointUseCase(nextValue)
    }
    // ====================================================================================
  }

  fun onClickCoolingPlus() {
    Timber.d("Hit")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Cooling Plus" button in the [fragment_thermostat.xml]
    // [SetOccupiedCoolingSetpointUseCase] will update the int value of the +1 degree. ([degree] *
    // 100)
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      val nextValue = _occupiedCoolingSetpoint.value + 100
      Timber.d("current value = ${_occupiedCoolingSetpoint.value} set value = $nextValue")
      setOccupiedCoolingSetpointUseCase(nextValue)
    }
    // ====================================================================================
  }

  fun onClickCoolingMinus() {
    Timber.d("Hit")
    // ===================================================================================
    // [CODELAB] Get cluster value : Thermostat
    // Triggered by the "Cooling Minus" button in the [fragment_thermostat.xml]
    // [SetOccupiedCoolingSetpointUseCase] will update the int value of the -1 degree. ([degree] *
    // 100)
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      val nextValue = _occupiedCoolingSetpoint.value - 100
      Timber.d("current value = ${_occupiedCoolingSetpoint.value} set value = $nextValue")
      setOccupiedCoolingSetpointUseCase(nextValue)
    }
    // ====================================================================================
  }
}
