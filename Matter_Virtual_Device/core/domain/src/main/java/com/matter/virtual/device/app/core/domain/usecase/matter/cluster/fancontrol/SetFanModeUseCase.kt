package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.fancontrol

import com.matter.virtual.device.app.core.common.di.IoDispatcher
import com.matter.virtual.device.app.core.data.repository.cluster.FanControlManagerRepository
import com.matter.virtual.device.app.core.domain.CoroutineUseCase
import com.matter.virtual.device.app.core.model.matter.FanControlFanMode
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher

class SetFanModeUseCase
@Inject
constructor(
  private val fanControlManagerRepository: FanControlManagerRepository,
  @IoDispatcher dispatcher: CoroutineDispatcher
) : CoroutineUseCase<FanControlFanMode, Unit>(dispatcher) {

  override suspend fun execute(param: FanControlFanMode) {
    fanControlManagerRepository.setFanMode(param)
  }
}
