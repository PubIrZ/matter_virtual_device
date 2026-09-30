package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.KeypadInputManagerStub
import com.matter.virtual.device.app.core.model.matter.KeyCode
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class KeypadInputManagerRepositoryImpl
@Inject
constructor(private val keypadInputManagerStub: KeypadInputManagerStub) :
  KeypadInputManagerRepository {

  override fun getKeyCodeFlow(): StateFlow<KeyCode> {
    Timber.d("Hit")
    return keypadInputManagerStub.keyCode
  }
}
