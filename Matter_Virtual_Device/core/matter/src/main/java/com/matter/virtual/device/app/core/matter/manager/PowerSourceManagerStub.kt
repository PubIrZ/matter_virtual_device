package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.PowerSourceManager
import com.matter.virtual.device.app.core.common.MatterConstants
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class PowerSourceManagerStub
@Inject
constructor(
  private val deviceApp: DeviceApp,
) : PowerSourceManager {
  private val _batPercent = MutableStateFlow(DEFAULT_BATTERY_STATUS)
  val batPercent: StateFlow<Int>
    get() = _batPercent

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("endpoint:$endpoint")
    deviceApp.setBatPercentRemaining(endpoint, DEFAULT_BATTERY_STATUS)
  }

  fun setBatPercentRemaining(batteryPercentRemaining: Int) {
    Timber.d("batteryPercentRemaining:$batteryPercentRemaining")
    _batPercent.value = batteryPercentRemaining
    deviceApp.setBatPercentRemaining(MatterConstants.DEFAULT_ENDPOINT, batteryPercentRemaining)
  }

  companion object {
    private const val DEFAULT_BATTERY_STATUS = 70
  }
}
