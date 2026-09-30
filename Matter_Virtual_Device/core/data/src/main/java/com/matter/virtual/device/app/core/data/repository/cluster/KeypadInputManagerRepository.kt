package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.model.matter.KeyCode
import kotlinx.coroutines.flow.StateFlow

interface KeypadInputManagerRepository {
  fun getKeyCodeFlow(): StateFlow<KeyCode>
}
