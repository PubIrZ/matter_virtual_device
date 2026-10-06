package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.ColorControlManager
import com.matter.virtual.device.app.DeviceApp
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class ColorControlManagerStub @Inject constructor(private val deviceApp: DeviceApp) :
  ColorControlManager {
  private val _enhancedColorMode = MutableStateFlow(0)
  val enhancedColorMode: StateFlow<Int>
    get() = _enhancedColorMode

  private val _colorMode = MutableStateFlow(0)
  val colorMode: StateFlow<Int>
    get() = _colorMode

  private val _currentHue = MutableStateFlow(0)
  val currentHue: StateFlow<Int>
    get() = _currentHue

  private val _currentSaturation = MutableStateFlow(0)
  val currentSaturation: StateFlow<Int>
    get() = _currentSaturation

  private val _colorTemperature = MutableStateFlow(0xfa)
  val colorTemperature: StateFlow<Int>
    get() = _colorTemperature

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("endpoint:$endpoint")
    deviceApp.setCurrentHue(endpoint, 0)
    deviceApp.setCurrentSaturation(endpoint, 0)
  }

  override fun handleEnhancedColorModeChanged(value: Int) {
    Timber.d("value:$value")
    _enhancedColorMode.value = value
  }

  override fun handleColorModeChanged(value: Int) {
    Timber.d("value:$value")
    _colorMode.value = value
  }

  override fun handleCurrentHueChanged(value: Int) {
    Timber.d("value:$value")
    _currentHue.value = value
  }

  override fun handleCurrentSaturationChanged(value: Int) {
    Timber.d("value:$value")
    _currentSaturation.value = value
  }

  override fun handleColorTemperatureChanged(value: Int) {
    Timber.d("value:$value")
    _colorTemperature.value = value
  }
}
