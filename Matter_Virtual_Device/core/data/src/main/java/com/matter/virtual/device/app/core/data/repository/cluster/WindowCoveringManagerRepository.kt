package com.matter.virtual.device.app.core.data.repository.cluster

import kotlinx.coroutines.flow.StateFlow

interface WindowCoveringManagerRepository {
  fun getTargetPositionFlow(): StateFlow<Int>

  fun getCurrentPositionFlow(): StateFlow<Int>

  fun getOperationalStatusFlow(): StateFlow<Int>

  suspend fun setTargetPosition(value: Int)
}
