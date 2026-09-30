package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.MediaPlaybackManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class MediaPlaybackManagerRepositoryImpl
@Inject
constructor(private val mediaPlaybackManagerStub: MediaPlaybackManagerStub) :
  MediaPlaybackManagerRepository {

  override fun getPlaybackStateFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return mediaPlaybackManagerStub.playbackState
  }

  override fun getPlaybackSpeedFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return mediaPlaybackManagerStub.playbackSpeed
  }
}
