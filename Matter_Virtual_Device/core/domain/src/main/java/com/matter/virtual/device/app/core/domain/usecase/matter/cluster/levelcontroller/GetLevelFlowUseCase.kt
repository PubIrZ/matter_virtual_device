package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.levelcontroller

import com.matter.virtual.device.app.core.data.repository.cluster.LevelManagerRepository
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetLevelFlowUseCase
@Inject
constructor(private val levelManagerRepository: LevelManagerRepository) {
  operator fun invoke(): StateFlow<Int> = levelManagerRepository.getLevelFlow()
}
