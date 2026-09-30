package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat

import com.matter.virtual.device.app.core.common.di.IoDispatcher
import com.matter.virtual.device.app.core.data.repository.cluster.ThermostatManagerRepository
import com.matter.virtual.device.app.core.domain.CoroutineUseCase
import com.matter.virtual.device.app.core.model.matter.ThermostatSystemMode
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher

class SetSystemModeUseCase
@Inject
constructor(
  private val thermostatManagerRepository: ThermostatManagerRepository,
  @IoDispatcher dispatcher: CoroutineDispatcher
) : CoroutineUseCase<ThermostatSystemMode, Unit>(dispatcher) {

  override suspend fun execute(param: ThermostatSystemMode) {
    thermostatManagerRepository.setSystemMode(param)
  }
}
