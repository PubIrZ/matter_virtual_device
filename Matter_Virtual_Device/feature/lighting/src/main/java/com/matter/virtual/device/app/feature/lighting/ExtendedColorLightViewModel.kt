package com.matter.virtual.device.app.feature.lighting

import androidx.lifecycle.LiveData
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.asLiveData
import androidx.lifecycle.viewModelScope
import com.matter.virtual.device.app.core.common.result.successOr
import com.matter.virtual.device.app.core.domain.usecase.matter.IsFabricRemovedUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.StartMatterAppServiceUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.colorcontrol.GetColorTemperatureFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.colorcontrol.GetCurrentHueFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.colorcontrol.GetCurrentSaturationFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.levelcontroller.GetLevelFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.onoff.GetOnOffFlowUseCase
import com.matter.virtual.device.app.core.domain.usecase.matter.cluster.onoff.SetOnOffUseCase
import com.matter.virtual.device.app.core.model.HsvColor
import com.matter.virtual.device.app.core.ui.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import timber.log.Timber

@HiltViewModel
class ExtendedColorLightViewModel
@Inject
constructor(
  getOnOffFlowUseCase: GetOnOffFlowUseCase,
  getLevelFlowUseCase: GetLevelFlowUseCase,
  getCurrentHueFlowUseCase: GetCurrentHueFlowUseCase,
  getCurrentSaturationFlowUseCase: GetCurrentSaturationFlowUseCase,
  getColorTemperatureFlowUseCase: GetColorTemperatureFlowUseCase,
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
  // CODELAB Level 3
  // The current status of the on/off. The boolean value is used by the [ExtendedColorLightFragment]
  // to react to update ui.
  // -----------------------------------------------------------------------------------
  
  // TODO 1: Paste or write code below

  // ===================================================================================

  // ===================================================================================
  // CODELAB Level 3
  // The current status of the color level. The int value is used by the
  // [ExtendedColorLightFragment]
  // to react to update ui.
  // -----------------------------------------------------------------------------------
  
  // TODO 2: Paste or write code below

  // ===================================================================================

  // ===================================================================================
  // CODELAB Level 3
  // The current status of the color. The enum value is used by the [ExtendedColorLightFragment]
  // to react to update ui.
  // -----------------------------------------------------------------------------------
  
  // TODO 3: Paste or write code below

  // ===================================================================================

  // ===================================================================================
  // CODELAB Level 3
  // The current status of the color temperature. The int value is used by the
  // [ExtendedColorLightFragment]
  // to react to update ui.
  // -----------------------------------------------------------------------------------
  
  // TODO 4: Paste or write code below

  // ===================================================================================

  override fun onCleared() {
    Timber.d("Hit")
    super.onCleared()
  }

  fun onClickButton() {
    // ===================================================================================
    // CODELAB Level 3
    // Triggered by the "On/Off" button in the [ExtendedColorLightFragment]
    // [SetOnOffUseCase] will update the boolean value of the new on/off status.
    // -----------------------------------------------------------------------------------
    
    // TODO 5: Paste or write code below
    
    // ===================================================================================
  }
}
