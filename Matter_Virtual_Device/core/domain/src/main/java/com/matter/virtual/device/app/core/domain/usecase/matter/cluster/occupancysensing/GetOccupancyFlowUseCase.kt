package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.occupancysensing

import com.matter.virtual.device.app.core.data.repository.cluster.OccupancySensingManagerRepository
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetOccupancyFlowUseCase
@Inject
constructor(private val occupancySensingManagerRepository: OccupancySensingManagerRepository) {
  operator fun invoke(): StateFlow<Boolean> = occupancySensingManagerRepository.getOccupancyFlow()
}
