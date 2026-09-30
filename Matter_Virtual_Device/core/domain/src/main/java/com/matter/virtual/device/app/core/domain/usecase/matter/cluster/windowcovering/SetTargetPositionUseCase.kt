package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.windowcovering

import com.matter.virtual.device.app.core.common.di.IoDispatcher
import com.matter.virtual.device.app.core.data.repository.cluster.WindowCoveringManagerRepository
import com.matter.virtual.device.app.core.domain.CoroutineUseCase
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher

class SetTargetPositionUseCase
@Inject
constructor(
  private val windowCoveringManagerRepository: WindowCoveringManagerRepository,
  @IoDispatcher dispatcher: CoroutineDispatcher
) : CoroutineUseCase<Int, Unit>(dispatcher) {

  override suspend fun execute(param: Int) {
    windowCoveringManagerRepository.setTargetPosition(param)
  }
}
