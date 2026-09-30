package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.mediaplayback

import com.matter.virtual.device.app.core.data.repository.cluster.MediaPlaybackManagerRepository
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetPlaybackStateFlowUseCase
@Inject
constructor(private val mediaPlaybackManagerRepository: MediaPlaybackManagerRepository) {

  operator fun invoke(): StateFlow<Int> = mediaPlaybackManagerRepository.getPlaybackStateFlow()
}
