package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.relativehumiditymeasurement

import com.matter.virtual.device.app.core.common.di.IoDispatcher
import com.matter.virtual.device.app.core.data.repository.cluster.RelativeHumidityMeasurementManagerRepository
import com.matter.virtual.device.app.core.domain.CoroutineUseCase
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher

class SetRelativeHumidityUseCase
@Inject
constructor(
  private val relativeHumidityMeasurementManagerRepository:
    RelativeHumidityMeasurementManagerRepository,
  @IoDispatcher dispatcher: CoroutineDispatcher
) : CoroutineUseCase<Int, Unit>(dispatcher) {

  override suspend fun execute(param: Int) {
    relativeHumidityMeasurementManagerRepository.setHumidity(param)
  }
}
