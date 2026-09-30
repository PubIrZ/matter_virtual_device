package com.matter.virtual.device.app.core.data.repository.cluster

import kotlinx.coroutines.flow.StateFlow

interface ColorControlManagerRepository {
  fun getEnhancedColorModeFlow(): StateFlow<Int>

  fun getColorModeFlow(): StateFlow<Int>

  fun getCurrentHueFlow(): StateFlow<Int>

  fun getCurrentSaturationFlow(): StateFlow<Int>

  fun getColorTemperatureFlow(): StateFlow<Int>
}
