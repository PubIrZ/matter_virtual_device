package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.ThermostatManagerStub
import com.matter.virtual.device.app.core.model.matter.ThermostatRunningMode
import com.matter.virtual.device.app.core.model.matter.ThermostatSystemMode
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class ThermostatManagerRepositoryImpl
@Inject
constructor(private val thermostatManagerStub: ThermostatManagerStub) :
  ThermostatManagerRepository {

  override fun getSystemModeFlow(): StateFlow<ThermostatSystemMode> {
    Timber.d("Hit")
    return thermostatManagerStub.systemMode
  }

  override fun getThermostatRunningStateFlow(): StateFlow<ThermostatRunningMode> {
    Timber.d("Hit")
    return thermostatManagerStub.thermostatRunningState
  }

  override fun getOccupiedCoolingSetpointFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return thermostatManagerStub.occupiedCoolingSetpoint
  }

  override fun getOccupiedHeatingSetpointFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return thermostatManagerStub.occupiedHeatingSetpoint
  }

  override fun getLocalTemperatureFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return thermostatManagerStub.localTemperature
  }

  override suspend fun setLocalTemperature(value: Int) {
    Timber.d("value:$value")
    thermostatManagerStub.setLocalTemperature(value)
  }

  override suspend fun setSystemMode(mode: ThermostatSystemMode) {
    Timber.d("mode:$mode")
    thermostatManagerStub.setSystemMode(mode)
  }

  override suspend fun setThermostatRunningState(state: ThermostatRunningMode) {
    Timber.d("state:$state")
    thermostatManagerStub.setThermostatRunningState(state)
  }

  override suspend fun setOccupiedCoolingSetpoint(value: Int) {
    Timber.d("value:$value")
    thermostatManagerStub.setOccupiedCoolingSetpoint(value)
  }

  override suspend fun setOccupiedHeatingSetpoint(value: Int) {
    Timber.d("value:$value")
    thermostatManagerStub.setOccupiedHeatingSetpoint(value)
  }
}
