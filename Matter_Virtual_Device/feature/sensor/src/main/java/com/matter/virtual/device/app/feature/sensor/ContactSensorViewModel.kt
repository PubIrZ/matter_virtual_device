package com.matter.virtual.device.app.feature.sensor

import androidx.lifecycle.*
import com.matter.virtual.device.app.core.common.result.successOr
import com.matter.virtual.device.app.core.domain.usecase.matter.IsFabricRemovedUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.StartMatterAppServiceUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.booleanstate.GetStateValueFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.booleanstate.SetStateValueUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.powersource.GetBatPercentRemainingUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.powersource.SetBatPercentRemainingUseCase
import com.matter.virtual.device.app.core.ui.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import timber.log.Timber

@HiltViewModel
class ContactSensorViewModel
@Inject
constructor(
  getStateValueFlowUseCase: GetStateValueFlowUseCase,
  getBatPercentRemainingUseCase: GetBatPercentRemainingUseCase,
  private val startMatterAppServiceUseCase: StartMatterAppServiceUseCase,
  private val setStateValueUseCase: SetStateValueUseCase,
  private val setBatPercentRemainingUseCase: SetBatPercentRemainingUseCase,
  private val isFabricRemovedUseCase: IsFabricRemovedUseCase,
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
  // [CODELAB] Get cluster value : ContactSensor
  // The current status of the contact. The boolean value is used by the [ContactSensorFragment]
  // to react to update ui.
  // -----------------------------------------------------------------------------------
  private val _stateValue: StateFlow<Boolean> = getStateValueFlowUseCase()
  val stateValue: LiveData<Boolean>
    get() = _stateValue.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : ContactSensor
  // The current status of the battery. The int value is used by the [ContactSensorFragment]
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

  fun onClickButton() {
    // ===================================================================================
    // [CODELAB] Get cluster value : ContactSensor
    // Triggered by the "Contact" button in the [ContactSensorFragment]
    // [SetStateValueUseCase] will update the boolean value of the new contact status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      Timber.d("current value = ${_stateValue.value}")
      if (_stateValue.value) {
        Timber.d("set value = false")
        setStateValueUseCase(false)
      } else {
        Timber.d("set value = true")
        setStateValueUseCase(true)
      }
    }
    // ===================================================================================
  }

  fun updateBatterySeekbarProgress(progress: Int) {
    // ===================================================================================
    // [CODELAB] Get cluster value : ContactSensor
    // Triggered by the "Battery" seekbar in the [ContactSensorFragment]
    // [batteryStatus] store the current status of the battery to indicate the progress.
    // -----------------------------------------------------------------------------------
    _batteryStatus.value = progress
    // ===================================================================================
  }

  fun updateBatteryStatusToCluster(progress: Int) {
    Timber.d("progress:$progress")
    // ===================================================================================
    // [CODELAB] Get cluster value : ContactSensor
    // Triggered by the "Battery" seekbar in the [ContactSensorFragment]
    // [updateBatterySeekbarProgress] update the current status of the battery to indicate the
    // progress.
    // [SetBatPercentRemainingUseCase] will update the int value of the new battery status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      updateBatterySeekbarProgress(progress)
      setBatPercentRemainingUseCase(progress)
    }
    // ===================================================================================
  }
}
