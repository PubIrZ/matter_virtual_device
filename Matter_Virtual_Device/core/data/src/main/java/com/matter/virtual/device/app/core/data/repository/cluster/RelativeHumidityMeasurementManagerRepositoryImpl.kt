package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.RelativeHumidityMeasurementManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class RelativeHumidityMeasurementManagerRepositoryImpl
@Inject
constructor(
  private val relativeHumidityMeasurementManagerStub: RelativeHumidityMeasurementManagerStub
) : RelativeHumidityMeasurementManagerRepository {

  override suspend fun setHumidity(value: Int) {
    Timber.d("value:$value")
    relativeHumidityMeasurementManagerStub.setHumidity(value)
  }

  override fun getHumidity(): StateFlow<Int> {
    return relativeHumidityMeasurementManagerStub.measuredValue
  }
}
