package com.matter.virtual.device.app.core.data.repository.cluster

import kotlinx.coroutines.flow.StateFlow

interface LevelManagerRepository {
  fun getLevelFlow(): StateFlow<Int>

  suspend fun setCurrentLevel(value: Int)
}
