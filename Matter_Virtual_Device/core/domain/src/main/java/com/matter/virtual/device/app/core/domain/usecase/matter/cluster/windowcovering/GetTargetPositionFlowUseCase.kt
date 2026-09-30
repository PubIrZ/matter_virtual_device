package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.windowcovering

import com.matter.virtual.device.app.core.data.repository.cluster.WindowCoveringManagerRepository
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetTargetPositionFlowUseCase
@Inject
constructor(private val windowCoveringManagerRepository: WindowCoveringManagerRepository) {

  operator fun invoke(): StateFlow<Int> = windowCoveringManagerRepository.getTargetPositionFlow()
}
