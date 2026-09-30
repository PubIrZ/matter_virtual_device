package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.relativehumiditymeasurement

import com.matter.virtual.device.app.core.data.repository.cluster.RelativeHumidityMeasurementManagerRepository
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetRelativeHumidityUseCase
@Inject
constructor(
  private val relativeHumidityMeasurementManagerRepository:
    RelativeHumidityMeasurementManagerRepository,
) {
  operator fun invoke(): StateFlow<Int> = relativeHumidityMeasurementManagerRepository.getHumidity()
}
