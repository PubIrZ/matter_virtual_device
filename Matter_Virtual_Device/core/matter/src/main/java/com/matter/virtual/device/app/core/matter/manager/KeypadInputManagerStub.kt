package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.KeypadInputManager
import com.matter.virtual.device.app.core.model.matter.KeyCode
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class KeypadInputManagerStub @Inject constructor() : KeypadInputManager {

  private val _keyCode = MutableStateFlow(KeyCode.KEY_CODE_UNKNOWN)
  val keyCode: StateFlow<KeyCode>
    get() = _keyCode

  override fun sendKey(keyCode: Int): Int {
    Timber.d("keyCode:$keyCode")
    _keyCode.value = keyCode.asKeyCode()
    return KeypadInputManager.KEY_STATUS_SUCCESS
  }
}

fun Int.asKeyCode() =
  when (this) {
    KeypadInputManager.KEY_CODE_SELECT -> KeyCode.KEY_CODE_SELECT
    KeypadInputManager.KEY_CODE_UP -> KeyCode.KEY_CODE_UP
    KeypadInputManager.KEY_CODE_DOWN -> KeyCode.KEY_CODE_DOWN
    KeypadInputManager.KEY_CODE_LEFT -> KeyCode.KEY_CODE_LEFT
    KeypadInputManager.KEY_CODE_RIGHT -> KeyCode.KEY_CODE_RIGHT
    KeypadInputManager.KEY_CODE_ROOT_MENU -> KeyCode.KEY_CODE_ROOT_MENU
    KeypadInputManager.KEY_CODE_SETUP_MENU -> KeyCode.KEY_CODE_SETUP_MENU
    KeypadInputManager.KEY_CODE_CONTENTS_MENU -> KeyCode.KEY_CODE_CONTENTS_MENU
    KeypadInputManager.KEY_CODE_EXIT -> KeyCode.KEY_CODE_EXIT
    KeypadInputManager.KEY_CODE_NUMBER0_OR_NUMBER10 -> KeyCode.KEY_CODE_NUMBER0_OR_NUMBER10
    KeypadInputManager.KEY_CODE_NUMBERS1 -> KeyCode.KEY_CODE_NUMBERS1
    KeypadInputManager.KEY_CODE_NUMBERS2 -> KeyCode.KEY_CODE_NUMBERS2
    KeypadInputManager.KEY_CODE_NUMBERS3 -> KeyCode.KEY_CODE_NUMBERS3
    KeypadInputManager.KEY_CODE_NUMBERS4 -> KeyCode.KEY_CODE_NUMBERS4
    KeypadInputManager.KEY_CODE_NUMBERS5 -> KeyCode.KEY_CODE_NUMBERS5
    KeypadInputManager.KEY_CODE_NUMBERS6 -> KeyCode.KEY_CODE_NUMBERS6
    KeypadInputManager.KEY_CODE_NUMBERS7 -> KeyCode.KEY_CODE_NUMBERS7
    KeypadInputManager.KEY_CODE_NUMBERS8 -> KeyCode.KEY_CODE_NUMBERS8
    KeypadInputManager.KEY_CODE_NUMBERS9 -> KeyCode.KEY_CODE_NUMBERS9
    KeypadInputManager.KEY_CODE_BACKWARD -> KeyCode.KEY_CODE_BACKWARD
    KeypadInputManager.KEY_CODE_UNKNOWN -> KeyCode.KEY_CODE_UNKNOWN
    else -> KeyCode.KEY_CODE_UNKNOWN
  }
