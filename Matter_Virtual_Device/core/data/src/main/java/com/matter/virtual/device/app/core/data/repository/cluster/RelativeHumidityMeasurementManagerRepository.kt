package com.matter.virtual.device.app.core.data.repository.cluster

import kotlinx.coroutines.flow.StateFlow

interface RelativeHumidityMeasurementManagerRepository {
  suspend fun setHumidity(value: Int)

  fun getHumidity(): StateFlow<Int>
}
