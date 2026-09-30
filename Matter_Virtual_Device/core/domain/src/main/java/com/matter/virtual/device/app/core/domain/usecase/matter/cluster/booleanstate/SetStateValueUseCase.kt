package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.booleanstate

import com.matter.virtual.device.app.core.common.di.IoDispatcher
import com.matter.virtual.device.app.core.data.repository.cluster.BooleanStateManagerRepository
import com.matter.virtual.device.app.core.domain.CoroutineUseCase
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher

class SetStateValueUseCase
@Inject
constructor(
  private val booleanStateManagerRepository: BooleanStateManagerRepository,
  @IoDispatcher dispatcher: CoroutineDispatcher
) : CoroutineUseCase<Boolean, Unit>(dispatcher) {

  override suspend fun execute(param: Boolean) {
    booleanStateManagerRepository.setStateValue(param)
  }
}
