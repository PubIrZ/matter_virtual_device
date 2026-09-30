package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.model.matter.ThermostatRunningMode
import com.matter.virtual.device.app.core.model.matter.ThermostatSystemMode
import kotlinx.coroutines.flow.StateFlow

interface ThermostatManagerRepository {
  fun getSystemModeFlow(): StateFlow<ThermostatSystemMode>

  fun getThermostatRunningStateFlow(): StateFlow<ThermostatRunningMode>

  fun getOccupiedCoolingSetpointFlow(): StateFlow<Int>

  fun getOccupiedHeatingSetpointFlow(): StateFlow<Int>

  fun getLocalTemperatureFlow(): StateFlow<Int>

  suspend fun setLocalTemperature(value: Int)

  suspend fun setSystemMode(mode: ThermostatSystemMode)

  suspend fun setThermostatRunningState(state: ThermostatRunningMode)

  suspend fun setOccupiedCoolingSetpoint(value: Int)

  suspend fun setOccupiedHeatingSetpoint(value: Int)
}
