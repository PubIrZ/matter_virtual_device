package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.BooleanStateManager
import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.core.common.MatterConstants
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class BooleanStateManagerStub @Inject constructor(private val deviceApp: DeviceApp) :
  BooleanStateManager {

  private val _stateValue = MutableStateFlow(false)
  val stateValue: StateFlow<Boolean>
    get() = _stateValue

  // This function is setting the value of current StateValue from the app to the matter server
  fun setStateValue(value: Boolean) {
    _stateValue.value = value
    Timber.d("stateValue current value to Matter $value")
    deviceApp.setStateValue(MatterConstants.DEFAULT_ENDPOINT, value)
  }

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("endpoint:$endpoint")
    deviceApp.setStateValue(endpoint, stateValue.value)
  }
}
