package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.colorcontrol

import com.matter.virtual.device.app.core.data.repository.cluster.ColorControlManagerRepository
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetCurrentSaturationFlowUseCase
@Inject
constructor(private val colorControlManagerRepository: ColorControlManagerRepository) {
  operator fun invoke(): StateFlow<Int> = colorControlManagerRepository.getCurrentSaturationFlow()
}
