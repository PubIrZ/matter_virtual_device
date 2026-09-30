package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.DoorLockManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class DoorLockManagerRepositoryImpl
@Inject
constructor(private val doorLockManagerStub: DoorLockManagerStub) : DoorLockManagerRepository {

  override fun getLockStateFlow(): StateFlow<Boolean> {
    Timber.d("Hit")
    return doorLockManagerStub.lockState
  }

  override suspend fun setLockState(value: Boolean) {
    Timber.d("value:$value")
    doorLockManagerStub.setLockState(value)
  }

  override suspend fun sendLockAlarmEvent() {
    Timber.d("Hit")
    doorLockManagerStub.sendLockAlarmEvent()
  }

  override suspend fun getRequirePINforRemoteOperation(): Boolean {
    Timber.d("Hit")
    return doorLockManagerStub.getRequirePINforRemoteOperation()
  }

  override suspend fun setRequirePINforRemoteOperation(value: Boolean) {
    Timber.d("Hit")
    doorLockManagerStub.setRequirePINforRemoteOperation(value)
  }
}
