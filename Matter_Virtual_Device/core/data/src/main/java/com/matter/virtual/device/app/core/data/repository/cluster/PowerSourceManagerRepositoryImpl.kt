package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.PowerSourceManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class PowerSourceManagerRepositoryImpl
@Inject
constructor(private val powerSourceManagerStub: PowerSourceManagerStub) :
  PowerSourceManagerRepository {

  override suspend fun setBatPercentRemaining(batteryPercentRemaining: Int) {
    Timber.d("Hit")
    return powerSourceManagerStub.setBatPercentRemaining(batteryPercentRemaining)
  }

  override fun getBatPercent(): StateFlow<Int> {
    Timber.d("Hit")
    return powerSourceManagerStub.batPercent
  }
}
