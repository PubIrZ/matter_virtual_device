package com.matter.virtual.device.app.core.data.repository.cluster

import kotlinx.coroutines.flow.StateFlow

interface BooleanStateManagerRepository {
  fun getStateValueFlow(): StateFlow<Boolean> // StateValue is an attribute of BooleanState Cluster

  suspend fun setStateValue(value: Boolean)
}
