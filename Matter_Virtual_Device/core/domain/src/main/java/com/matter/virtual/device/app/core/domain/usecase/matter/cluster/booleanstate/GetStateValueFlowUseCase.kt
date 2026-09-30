package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.booleanstate

import com.matter.virtual.device.app.core.data.repository.cluster.BooleanStateManagerRepository
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetStateValueFlowUseCase
@Inject
constructor(private val booleanStateManagerRepository: BooleanStateManagerRepository) {
  operator fun invoke(): StateFlow<Boolean> = booleanStateManagerRepository.getStateValueFlow()
}
