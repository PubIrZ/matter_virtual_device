package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.OccupancySensingManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class OccupancySensingManagerRepositoryImpl
@Inject
constructor(private val occupancySensingManagerStub: OccupancySensingManagerStub) :
  OccupancySensingManagerRepository {

  override fun getOccupancyFlow(): StateFlow<Boolean> {
    Timber.d("Hit")
    return occupancySensingManagerStub.occupancy
  }

  override suspend fun setOccupancy(value: Boolean) {
    Timber.d("value:$value")
    occupancySensingManagerStub.setOccupancy(value)
  }
}
