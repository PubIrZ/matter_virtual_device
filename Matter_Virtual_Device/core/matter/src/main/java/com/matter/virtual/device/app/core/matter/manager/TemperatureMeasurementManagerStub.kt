package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.TemperatureMeasurementManager
import com.matter.virtual.device.app.core.common.MatterConstants
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class TemperatureMeasurementManagerStub @Inject constructor(private val deviceApp: DeviceApp) :
  TemperatureMeasurementManager {
  private val _measuredValue = MutableStateFlow(DEFAULT_TEMPERATURE)
  val measuredValue: StateFlow<Int>
    get() = _measuredValue

  fun setTemperature(value: Int) {
    Timber.d("value:$value")
    deviceApp.setMeasuredValue(MatterConstants.DEFAULT_ENDPOINT, value)
  }

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("TemperatureMeasurementManagerStub endpoint:$endpoint")
    deviceApp.setMeasuredValue(endpoint, DEFAULT_TEMPERATURE)
  }

  companion object {
    private const val DEFAULT_TEMPERATURE = 2100 // Temp * 100
  }
}
