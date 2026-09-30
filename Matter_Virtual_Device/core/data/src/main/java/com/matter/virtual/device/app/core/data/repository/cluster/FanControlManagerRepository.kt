package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.model.matter.FanControlFanMode
import kotlinx.coroutines.flow.StateFlow

interface FanControlManagerRepository {
  fun getFanModeFlow(): StateFlow<FanControlFanMode>

  suspend fun setFanMode(mode: FanControlFanMode)
}
