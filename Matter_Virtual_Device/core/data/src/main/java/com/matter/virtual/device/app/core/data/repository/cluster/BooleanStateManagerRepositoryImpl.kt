package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.BooleanStateManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class BooleanStateManagerRepositoryImpl
@Inject
constructor(private val booleanStateManagerStub: BooleanStateManagerStub) :
  BooleanStateManagerRepository {

  override fun getStateValueFlow(): StateFlow<Boolean> {
    Timber.d("Hit")
    return booleanStateManagerStub.stateValue
  }

  override suspend fun setStateValue(value: Boolean) {
    Timber.d("value:$value")
    booleanStateManagerStub.setStateValue(value)
  }
}
