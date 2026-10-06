package com.matter.virtual.device.app.feature.sensor

import androidx.lifecycle.LiveData
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.asLiveData
import androidx.lifecycle.viewModelScope
import com.matter.virtual.device.app.core.common.result.successOr
import com.matter.virtual.device.app.core.domain.usecase.matter.IsFabricRemovedUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.StartMatterAppServiceUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.occupancysensing.GetOccupancyFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.occupancysensing.SetOccupancyUseCase
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
class OccupancySensorViewModel
@Inject
constructor(
  getOccupancyFlowUseCase: GetOccupancyFlowUseCase,
  getBatPercentRemainingUseCase: GetBatPercentRemainingUseCase,
  private val setOccupancyUseCase: SetOccupancyUseCase,
  private val startMatterAppServiceUseCase: StartMatterAppServiceUseCase,
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
  // CODELAB Level 1
  // The current status of the occupancy. The boolean value is used by the [OccupancyFragment]
  // to react to update ui.
  // TODO 1 : Uncomment the following code blocks
  // -----------------------------------------------------------------------------------
  //private val _occupancy: StateFlow<Boolean> = getOccupancyFlowUseCase()
  //val occupancy: LiveData<Boolean>
  //  get() = _occupancy.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // CODELAB Level 1
  // The current status of the battery. The int value is used by the [OccupancyFragment]
  // to react to update fragment's UI.
  // TODO 2 : Uncomment the following code blocks
  // -----------------------------------------------------------------------------------
  //private val _batteryStatus: MutableStateFlow<Int> =
  //  getBatPercentRemainingUseCase() as MutableStateFlow<Int>
  //val batteryStatus: LiveData<Int>
  //  get() = _batteryStatus.asLiveData()
  // ===================================================================================

  override fun onCleared() {
    Timber.d("Hit")
    super.onCleared()
  }

  fun onClickButton() {
    // ===================================================================================
    // CODELAB Level 1
    // Triggered by the "Occupancy" button in the [OccupancyFragment]
    // [SetOccupancyUseCase] will update the boolean value of the new occupancy status.
    // TODO 3 : Uncomment the following code blocks
    // -----------------------------------------------------------------------------------
    //viewModelScope.launch {
    //  Timber.d("current value = ${_occupancy.value}")
    //  if (_occupancy.value) {
    //    Timber.d("set value = false")
    //    setOccupancyUseCase(false)
    //  } else {
    //    Timber.d("set value = true")
    //    setOccupancyUseCase(true)
    //  }
    //}
    // ===================================================================================
  }

  fun updateBatterySeekbarProgress(progress: Int) {
    // ===================================================================================
    // CODELAB Level 1
    // Triggered by the "Battery" seekbar in the [OccupancyFragment]
    // [batteryStatus] store the current status of the battery to indicate the progress.
    // TODO 4 : Uncomment the following code blocks
    // -----------------------------------------------------------------------------------
    //_batteryStatus.value = progress
    // ===================================================================================
  }

  fun updateBatteryStatusToCluster(progress: Int) {
    Timber.d("progress:$progress")
    // ===================================================================================
    // CODELAB Level 1
    // Triggered by the "Battery" seekbar in the [OccupancyFragment]
    // [updateBatterySeekbarProgress] update the current status of the battery to indicate the
    // progress.
    // [SetBatPercentRemainingUseCase] will update the int value of the new battery status.
    // TODO 5 : Uncomment the following code blocks
    // -----------------------------------------------------------------------------------
    //viewModelScope.launch {
    //  updateBatterySeekbarProgress(progress)
    //  setBatPercentRemainingUseCase(progress)
    //}
    // ===================================================================================
  }
}
