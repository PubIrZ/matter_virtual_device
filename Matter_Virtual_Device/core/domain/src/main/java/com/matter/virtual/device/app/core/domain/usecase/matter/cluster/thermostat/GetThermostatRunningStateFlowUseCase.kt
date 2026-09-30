package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.thermostat

import com.matter.virtual.device.app.core.data.repository.cluster.ThermostatManagerRepository
import com.matter.virtual.device.app.core.model.matter.ThermostatRunningMode
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetThermostatRunningStateFlowUseCase
@Inject
constructor(private val thermostatManagerRepository: ThermostatManagerRepository) {

  operator fun invoke(): StateFlow<ThermostatRunningMode> =
    thermostatManagerRepository.getThermostatRunningStateFlow()
}
