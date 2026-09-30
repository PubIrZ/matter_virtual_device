package com.matter.virtual.device.app.core.data.repository.cluster

import kotlinx.coroutines.flow.StateFlow

interface MediaPlaybackManagerRepository {
  fun getPlaybackStateFlow(): StateFlow<Int>

  fun getPlaybackSpeedFlow(): StateFlow<Int>
}
