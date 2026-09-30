package com.matter.virtual.device.app.feature.media

import androidx.lifecycle.*
import com.matter.virtual.device.app.core.common.result.successOr
import com.matter.virtual.device.app.core.domain.usecase.matter.IsFabricRemovedUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.StartMatterAppServiceUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.keypadinput.GetKeyCodeFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.mediaplayback.GetPlaybackSpeedFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.mediaplayback.GetPlaybackStateFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.onoff.GetOnOffFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.onoff.SetOnOffUseCase
import com.matter.virtual.device.app.core.model.matter.KeyCode
import com.matter.virtual.device.app.core.ui.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import timber.log.Timber

@HiltViewModel
class VideoPlayerViewModel
@Inject
constructor(
  getOnOffFlowUseCase: GetOnOffFlowUseCase,
  getPlaybackStateFlowUseCase: GetPlaybackStateFlowUseCase,
  getPlaybackSpeedFlowUseCase: GetPlaybackSpeedFlowUseCase,
  getKeyCodeStateFlowUseCase: GetKeyCodeFlowUseCase,
  private val setOnOffUseCase: SetOnOffUseCase,
  private val startMatterAppServiceUseCase: StartMatterAppServiceUseCase,
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
  // [CODELAB] Get cluster value : VideoPlayer
  // The current status of the on/off. The boolean value is used by the [VideoPlayerFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _onOff: StateFlow<Boolean> = getOnOffFlowUseCase()
  val onOff: LiveData<Boolean>
    get() = _onOff.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : VideoPlayer
  // The current status of the playback state. The int value is used by the [VideoPlayerFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _playbackState: StateFlow<Int> = getPlaybackStateFlowUseCase()
  val playbackState: LiveData<Int>
    get() = _playbackState.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : VideoPlayer
  // The current status of the playback speed. The int value is used by the [VideoPlayerFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _playbackSpeed: StateFlow<Int> = getPlaybackSpeedFlowUseCase()
  val playbackSpeed: LiveData<Int>
    get() = _playbackSpeed.asLiveData()
  // ===================================================================================

  // ===================================================================================
  // [CODELAB] Get cluster value : VideoPlayer
  // The current status of the key code. The enum value is used by the [VideoPlayerFragment]
  // to react to update fragment's UI.
  // -----------------------------------------------------------------------------------
  private val _keyCode: StateFlow<KeyCode> = getKeyCodeStateFlowUseCase()
  val keyCode: LiveData<KeyCode>
    get() = _keyCode.asLiveData()
  // ===================================================================================

  override fun onCleared() {
    Timber.d("Hit")
    super.onCleared()
  }

  fun onClickButton() {
    // ===================================================================================
    // [CODELAB] Get cluster value : VideoPlayer
    // Triggered by the "On/Off" button in the [VideoPlayerFragment]
    // [SetOnOffUseCase] will update the boolean value of the new on/off status.
    // -----------------------------------------------------------------------------------
    viewModelScope.launch {
      Timber.d("current value = ${_onOff.value}")
      if (_onOff.value) {
        Timber.d("set value = false")
        setOnOffUseCase(false)
      } else {
        Timber.d("set value = true")
        setOnOffUseCase(true)
      }
    }
    // ===================================================================================
  }
}
