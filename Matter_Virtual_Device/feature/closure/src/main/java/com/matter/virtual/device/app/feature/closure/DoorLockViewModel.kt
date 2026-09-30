package com.matter.virtual.device.app.feature.closure

import androidx.lifecycle.*
import com.matter.virtual.device.app.core.common.result.successOr
import com.matter.virtual.device.app.core.domain.usecase.matter.IsFabricRemovedUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.StartMatterAppServiceUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.doorlock.GetLockStateFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.doorlock.SendLockAlarmEventUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.doorlock.SetLockStateUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.doorlock.SetRequirePINforRemoteOperationUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.powersource.GetBatPercentRemainingUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.powersource.SetBatPercentRemainingUseCase
import com.matter.virtual.device.app.core.ui.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.ExperimentalSerializationApi
import timber.log.Timber

@OptIn(ExperimentalSerializationApi::class)
@HiltViewModel
class DoorLockViewModel
@Inject
constructor(
  getLockStateFlowUseCase: GetLockStateFlowUseCase,
  getBatPercentRemainingUseCase: GetBatPercentRemainingUseCase,
  private val setLockStateUseCase: SetLockStateUseCase,
  private val startMatterAppServiceUseCase: StartMatterAppServiceUseCase,
  private val sendLockAlarmEventUseCase: SendLockAlarmEventUseCase,
  private val setBatPercentRemainingUseCase: SetBatPercentRemainingUseCase,
  private val isFabricRemovedUseCase: IsFabricRemovedUseCase,
  private val setRequirePINforRemoteOperationUseCase: SetRequirePINforRemoteOperationUseCase,
  savedStateHandle: SavedStateHandle
) : BaseViewModel(savedStateHandle) {

  init {
    viewModelScope.launch {
      // Disabling default pin generation from STApp
      setRequirePINforRemoteOperationUseCase(false)

      startMatterAppServiceUseCase(matterSettings)
    }

    viewModelScope.launch {
      val isFabricRemoved = isFabricRemovedUseCase().successOr(false)
      if (isFabricRemoved) {
        Timber.d("Fabric Removed")
        onFabricRemoved()
      }
    }
  }
  // ===================================================================================
  // [CODELAB] Get cluster value : DoorLock
  // The current status of the lock. The boolean value is used by the [DoorLockFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _lockState: StateFlow<Boolean> = getLockStateFlowUseCase()
  val lockState: LiveData<Boolean>
    get() = _lockState.asLiveData()
  // ==============================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : DoorLock
  // The current status of the battery. The int value is used by the [DoorLockFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _batteryStatus: MutableStateFlow<Int> =
    getBatPercentRemainingUseCase() as MutableStateFlow<Int>
  val batteryStatus: LiveData<Int>
    get() = _batteryStatus.asLiveData()
  // ==============================================================================

  override fun onCleared() {
    Timber.d("onCleared()")
    super.onCleared()
  }

  fun onClickButton() {
    // ===================================================================================
    // [CODELAB] Get cluster value : DoorLock
    // Triggered by the "Lock" button in the [DoorLockFragment]
    // [SetLockStateUseCase] will update the boolean value of the new lock status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      Timber.d("current lockState value = ${_lockState.value}")
      if (_lockState.value == LOCK_STATE_LOCKED) {
        Timber.d("set value = unlocked")
        setLockStateUseCase(LOCK_STATE_UNLOCKED)
      } else {
        Timber.d("set value = locked")
        setLockStateUseCase(LOCK_STATE_LOCKED)
      }
    }
    // ==============================================================================
  }

  fun onClickSendLockAlarmEventButton() {
    Timber.d("Hit")
    // ===================================================================================
    // [CODELAB] Get cluster value : DoorLock
    // Triggered by the "Send Alarm" button in the [DoorLockFragment]
    // [SendLockAlarmEventUseCase] will send alarm event.
    // [SetLockStateUseCase] will update the boolean value of the unlock status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      if (!_lockState.value) {
        // if lockState == locked, send alarm event and change the lockState to unlocked
        sendLockAlarmEventUseCase()
        setLockStateUseCase(LOCK_STATE_UNLOCKED)
      }
    }
    // ==============================================================================
  }

  fun updateBatterySeekbarProgress(progress: Int) {
    // ===================================================================================
    // [CODELAB] Get cluster value : DoorLock
    // Triggered by the "Battery" seekbar in the [DoorLockFragment]
    // [batteryStatus] store the current status of the battery to indicate the progress.
    // -----------------------------------------------------------------------------------
    _batteryStatus.value = progress
    // ==============================================================================
  }

  fun updateBatteryStatusToCluster(progress: Int) {
    Timber.d("progress:$progress")
    // ===================================================================================
    // [CODELAB] Get cluster value : DoorLock
    // Triggered by the "Battery" seekbar in the [DoorLockFragment]
    // [updateBatterySeekbarProgress] update the current status of the battery to indicate the
    // progress.
    // [SetBatPercentRemainingUseCase] will update the int value of the new battery status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      updateBatterySeekbarProgress(progress)
      setBatPercentRemainingUseCase(progress)
    }
    // ==============================================================================
  }

  companion object {
    const val LOCK_STATE_LOCKED = false
    const val LOCK_STATE_UNLOCKED = true
  }
}
