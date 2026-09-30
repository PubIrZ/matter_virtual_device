package com.matter.virtual.device.app.core.data.repository.cluster

import kotlinx.coroutines.flow.StateFlow

interface PowerSourceManagerRepository {
  suspend fun setBatPercentRemaining(batteryPercentRemaining: Int)

  fun getBatPercent(): StateFlow<Int>
}
