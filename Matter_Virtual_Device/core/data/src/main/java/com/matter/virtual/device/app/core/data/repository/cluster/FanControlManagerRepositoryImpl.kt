package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.FanControlManagerStub
import com.matter.virtual.device.app.core.model.matter.FanControlFanMode
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class FanControlManagerRepositoryImpl
@Inject
constructor(private val fanControlManagerStub: FanControlManagerStub) :
  FanControlManagerRepository {

  override fun getFanModeFlow(): StateFlow<FanControlFanMode> {
    Timber.d("Hit")
    return fanControlManagerStub.fanMode
  }

  override suspend fun setFanMode(mode: FanControlFanMode) {
    Timber.d("mode:$mode")
    fanControlManagerStub.setFanMode(mode)
  }
}
