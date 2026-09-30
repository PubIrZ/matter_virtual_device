package com.matter.virtual.device.app.core.data.repository.cluster

import kotlinx.coroutines.flow.StateFlow

interface TemperatureMeasurementManagerRepository {
  suspend fun setTemperature(value: Int)

  fun getTemperature(): StateFlow<Int>
}
