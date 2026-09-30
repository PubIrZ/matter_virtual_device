package com.matter.virtual.device.app.feature.closure

import androidx.lifecycle.LiveData
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.asLiveData
import androidx.lifecycle.viewModelScope
import com.matter.virtual.device.app.core.common.result.successOr
import com.matter.virtual.device.app.core.domain.usecase.matter.IsFabricRemovedUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.StartMatterAppServiceUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.powersource.GetBatPercentRemainingUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.powersource.SetBatPercentRemainingUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.windowcovering.GetCurrentPositionFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.windowcovering.GetOperationalStatusFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.windowcovering.GetTargetPositionFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.windowcovering.SetTargetPositionUseCase
import com.matter.virtual.device.app.core.ui.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import timber.log.Timber

@HiltViewModel
class WindowCoveringViewModel
@Inject
constructor(
  getTargetPositionFlowUseCase: GetTargetPositionFlowUseCase,
  getCurrentPositionFlowUseCase: GetCurrentPositionFlowUseCase,
  getOperationalStatusFlowUseCase: GetOperationalStatusFlowUseCase,
  getBatPercentRemainingUseCase: GetBatPercentRemainingUseCase,
  private val setTargetPositionUseCase: SetTargetPositionUseCase,
  private val startMatterAppServiceUseCase: StartMatterAppServiceUseCase,
  private val isFabricRemovedUseCase: IsFabricRemovedUseCase,
  private val setBatPercentRemainingUseCase: SetBatPercentRemainingUseCase,
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

  private val _targetPosition: StateFlow<Int> = getTargetPositionFlowUseCase()
  private val _currentPosition: StateFlow<Int> = getCurrentPositionFlowUseCase()
  private val _operationalStatus: StateFlow<Int> = getOperationalStatusFlowUseCase()

  // ===================================================================================
  // [CODELAB] Get cluster value : WindowCovering
  // The current status of the position/operation. The enum value is used by the
  // [WindowCoveringFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  val windowCoveringStatus: LiveData<WindowCoveringStatus> =
    combine(_currentPosition, _operationalStatus) { currentPosition, operationalStatus ->
        WindowCoveringStatus(currentPosition, operationalStatus)
      }
      .asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : WindowCovering
  // The current status of the battery. The int value is used by the [WindowCoveringFragment]
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

  fun stopMotion(percentage: Int) {
    // ===================================================================================
    // [CODELAB] Get cluster value : WindowCovering
    // Triggered by the "WindowShade" seekbar in the [WindowCoveringFragment]
    // [SetTargetPositionUseCase] will update the int value of the new target position status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      Timber.d("Target position = $percentage")
      setTargetPositionUseCase(percentage)
    }
    // ===================================================================================
  }

  fun onClickOpenButton() {
    // ===================================================================================
    // [CODELAB] Get cluster value : WindowCovering
    // Triggered by the "Open" button in the [fragment_window_covering.xml]
    // [SetTargetPositionUseCase] will update the int value of the open position (100) status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      Timber.d("Target position = 100")
      setTargetPositionUseCase(100)
    }
    // ===================================================================================
  }

  fun onClickCloseButton() {
    // ===================================================================================
    // [CODELAB] Get cluster value : WindowCovering
    // Triggered by the "Close" button in the [fragment_window_covering.xml]
    // [SetTargetPositionUseCase] will update the int value of the close position (0) status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch { setTargetPositionUseCase(0) }
    // ===================================================================================
  }

  fun onClickPauseButton() {
    // ===================================================================================
    // [CODELAB] Get cluster value : WindowCovering
    // Triggered by the "Pause" button in the [fragment_window_covering.xml]
    // [SetTargetPositionUseCase] will update the int value of the pause position status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      Timber.d(
        "current position = ${_currentPosition.value}, target position: ${_targetPosition.value}"
      )
      if (_currentPosition.value != _targetPosition.value) {
        setTargetPositionUseCase(_currentPosition.value)
      }
    }
    // ===================================================================================
  }

  fun updateBatterySeekbarProgress(progress: Int) {
    // ===================================================================================
    // [CODELAB] Get cluster value : WindowCovering
    // Triggered by the "Battery" seekbar in the [WindowCoveringFragment]
    // [batteryStatus] store the current status of the battery to indicate the progress.
    // -----------------------------------------------------------------------------------
    _batteryStatus.value = progress
    // ===================================================================================
  }

  fun updateBatteryStatusToCluster(progress: Int) {
    Timber.d("progress:$progress")
    // ===================================================================================
    // [CODELAB] Get cluster value : WindowCovering
    // Triggered by the "Battery" seekbar in the [WindowCoveringFragment]
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

data class WindowCoveringStatus(val currentPosition: Int, val operationalStatus: Int)
