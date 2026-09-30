package com.matter.virtual.device.app.core.domain.usecase.matter.cluster.keypadinput

import com.matter.virtual.device.app.core.data.repository.cluster.KeypadInputManagerRepository
import com.matter.virtual.device.app.core.model.matter.KeyCode
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

class GetKeyCodeFlowUseCase
@Inject
constructor(private val keypadInputManagerRepository: KeypadInputManagerRepository) {

  operator fun invoke(): StateFlow<KeyCode> = keypadInputManagerRepository.getKeyCodeFlow()
}
