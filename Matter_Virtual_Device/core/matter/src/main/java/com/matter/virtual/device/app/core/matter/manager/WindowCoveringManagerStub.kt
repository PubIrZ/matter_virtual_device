package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.WindowCoveringManager
import com.matter.virtual.device.app.core.common.MatterConstants
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class WindowCoveringManagerStub @Inject constructor(private val deviceApp: DeviceApp) :
  WindowCoveringManager {

  private val _targetPosition = MutableStateFlow(0)
  val targetPosition: StateFlow<Int>
    get() = _targetPosition

  private var _currentPosition = MutableStateFlow(0)
  val currentPosition: StateFlow<Int>
    get() = _currentPosition

  private var _operationalStatus = MutableStateFlow(0)
  val operationalStatus: StateFlow<Int>
    get() = _operationalStatus

  fun setTargetPosition(value: Int) {
    val valueForMatterStack = convertPositionFromAppToMatterStack(value)

    _targetPosition.value = valueForMatterStack
    deviceApp.setTargetPosition(MatterConstants.DEFAULT_ENDPOINT, valueForMatterStack)
  }

  private fun convertPositionFromAppToMatterStack(value: Int): Int {
    // Convert unit of value as well because Percent100ths is used internally.
    return 10000 -
      when (value) {
        in 0..100 -> value * 100
        else -> value
      }
  }

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("WindowCoveringManagerStub endpoint:$endpoint")
    deviceApp.setFeatureMap(endpoint, 5) // lift up/down and position aware lift
    deviceApp.setType(endpoint, WindowCoveringManager.Type_kRollerShade)
    deviceApp.setEndProductType(endpoint, WindowCoveringManager.EndProductType_kRollerShade)
    deviceApp.setMode(endpoint, WindowCoveringManager.Mode_kMotorDirectionReversed)
    deviceApp.setConfigStatus(endpoint, WindowCoveringManager.ConfigStatus_kOperational)
    deviceApp.setOperationalStatus(endpoint, WindowCoveringManager.OperationalStatus_kLift)
    val valueForMatterStack = convertPositionFromAppToMatterStack(_targetPosition.value)
    deviceApp.setCurrentPosition(endpoint, valueForMatterStack)
    deviceApp.setTargetPosition(endpoint, valueForMatterStack)
  }

  override fun handleTargetPositionChanged(value: Int) {
    val valueForApp = convertPositionFromMatterStackToApp(value)
    _targetPosition.value = valueForApp
  }

  private fun convertPositionFromMatterStackToApp(value: Int): Int {
    // Convert unit of value as well because 0..100 range is used in UI.
    return 100 -
      when (value) {
        in 0..100 -> value
        else -> value / 100
      }
  }

  override fun handleCurrentPositionChanged(value: Int) {
    val valueForApp = convertPositionFromMatterStackToApp(value)
    _currentPosition.value = valueForApp
  }

  override fun handleOperationalStatusChanged(value: Int) {
    _operationalStatus.value = value
  }
}
