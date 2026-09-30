package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.fancontrol

import com.matter.virtual.device.app.core.data.repository.cluster.FanControlManagerRepository
import com.matter.virtual.device.app.core.model.matter.FanControlFanMode
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetFanModeFlowUseCase
@Inject
constructor(private val fanControlManagerRepository: FanControlManagerRepository) {
  operator fun invoke(): StateFlow<FanControlFanMode> = fanControlManagerRepository.getFanModeFlow()
}
