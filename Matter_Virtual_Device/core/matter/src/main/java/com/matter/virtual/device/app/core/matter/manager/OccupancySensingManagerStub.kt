package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.OccupancySensingManager
import com.matter.virtual.device.app.core.common.MatterConstants
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class OccupancySensingManagerStub @Inject constructor(private val deviceApp: DeviceApp) :
  OccupancySensingManager {

  private val _occupancy = MutableStateFlow(false)
  val occupancy: StateFlow<Boolean>
    get() = _occupancy

  // This function is setting the value of current occupancy from the app to the matter server
  fun setOccupancy(value: Boolean) {
    _occupancy.value = value
    Timber.d("occupancy current value to Matter $value")
    deviceApp.setOccupancy(MatterConstants.DEFAULT_ENDPOINT, value)
  }

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("endpoint:$endpoint")
    deviceApp.setOccupancy(endpoint, occupancy.value)
  }
}
