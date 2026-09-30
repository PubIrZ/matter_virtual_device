package com.matter.virtual.device.app.core.data.repository.cluster

import kotlinx.coroutines.flow.StateFlow

interface OccupancySensingManagerRepository {
  fun getOccupancyFlow(): StateFlow<Boolean>

  suspend fun setOccupancy(value: Boolean)
}
