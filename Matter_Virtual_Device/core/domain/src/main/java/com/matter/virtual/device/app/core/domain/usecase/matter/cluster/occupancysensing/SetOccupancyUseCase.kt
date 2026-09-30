package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.occupancysensing

import com.matter.virtual.device.app.core.common.di.IoDispatcher
import com.matter.virtual.device.app.core.data.repository.cluster.OccupancySensingManagerRepository
import com.matter.virtual.device.app.core.domain.CoroutineUseCase
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher

class SetOccupancyUseCase
@Inject
constructor(
  private val occupancySensingManagerRepository: OccupancySensingManagerRepository,
  @IoDispatcher dispatcher: CoroutineDispatcher
) : CoroutineUseCase<Boolean, Unit>(dispatcher) {

  override suspend fun execute(param: Boolean) {
    occupancySensingManagerRepository.setOccupancy(param)
  }
}
