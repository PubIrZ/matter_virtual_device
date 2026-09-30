package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.WindowCoveringManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class WindowCoveringManagerRepositoryImpl
@Inject
constructor(private val windowCoveringManagerStub: WindowCoveringManagerStub) :
  WindowCoveringManagerRepository {

  override fun getTargetPositionFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return windowCoveringManagerStub.targetPosition
  }

  override fun getCurrentPositionFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return windowCoveringManagerStub.currentPosition
  }

  override fun getOperationalStatusFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return windowCoveringManagerStub.operationalStatus
  }

  override suspend fun setTargetPosition(value: Int) {
    Timber.d("value: $value")
    windowCoveringManagerStub.setTargetPosition(value)
  }
}
