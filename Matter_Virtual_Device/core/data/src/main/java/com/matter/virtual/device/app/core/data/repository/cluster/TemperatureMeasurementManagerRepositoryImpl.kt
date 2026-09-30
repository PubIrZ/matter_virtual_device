package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.TemperatureMeasurementManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class TemperatureMeasurementManagerRepositoryImpl
@Inject
constructor(private val temperatureMeasurementManagerStub: TemperatureMeasurementManagerStub) :
  TemperatureMeasurementManagerRepository {

  override suspend fun setTemperature(value: Int) {
    Timber.d("value:$value")
    temperatureMeasurementManagerStub.setTemperature(value)
  }

  override fun getTemperature(): StateFlow<Int> {
    Timber.d("Hit")
    return temperatureMeasurementManagerStub.measuredValue
  }
}
