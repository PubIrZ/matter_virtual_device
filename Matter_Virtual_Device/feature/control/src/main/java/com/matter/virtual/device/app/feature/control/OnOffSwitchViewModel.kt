package com.matter.virtual.device.app.feature.control

import androidx.lifecycle.LiveData
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.asLiveData
import androidx.lifecycle.viewModelScope
import com.matter.virtual.device.app.core.common.result.successOr
import com.matter.virtual.device.app.core.domain.usecase.matter.IsFabricRemovedUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.StartMatterAppServiceUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.onoff.GetOnOffFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.onoff.SetOnOffUseCase
import com.matter.virtual.device.app.core.ui.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import timber.log.Timber

@HiltViewModel
class OnOffSwitchViewModel
@Inject
constructor(
  getOnOffFlowUseCase: GetOnOffFlowUseCase,
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

  // The current status of the on/off. The boolean value is used by the [OnOffSwitchFragment]
  // to react to update fragment's UI.
  private val _onOff: StateFlow<Boolean> = getOnOffFlowUseCase()
  val onOff: LiveData<Boolean>
    get() = _onOff.asLiveData()

  override fun onCleared() {
    Timber.d("onCleared()")
    super.onCleared()
  }

  fun onClickButton() {
    // Triggered by the "On/Off" button in the [OnOffSwitchFragment]
    // [SetOnOffUseCase] will update the boolean value of the new on/off status.
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
  }
}
