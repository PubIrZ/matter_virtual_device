package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.RelativeHumidityMeasurementManager
import com.matter.virtual.device.app.core.common.MatterConstants
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class RelativeHumidityMeasurementManagerStub @Inject constructor(private val deviceApp: DeviceApp) :
  RelativeHumidityMeasurementManager {

  private val _measuredValue = MutableStateFlow(DEFAULT_HUMIDITY)
  val measuredValue: StateFlow<Int>
    get() = _measuredValue

  fun setHumidity(value: Int) {
    Timber.d("value:$value")
    deviceApp.setMeasuredHumidityValue(MatterConstants.DEFAULT_ENDPOINT, value)
  }

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("RelativeHumidityMeasurementManagerStub endpoint:$endpoint")
    deviceApp.setMeasuredHumidityValue(endpoint, DEFAULT_HUMIDITY)
  }

  companion object {
    private const val DEFAULT_HUMIDITY = 5500 // Val * 100
  }
}
