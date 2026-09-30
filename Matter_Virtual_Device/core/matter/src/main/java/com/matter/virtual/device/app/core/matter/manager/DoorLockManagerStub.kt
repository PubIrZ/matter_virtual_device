package com.matter.virtual.device.app.core.matter.manager

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.DoorLockManager
import com.matter.virtual.device.app.core.common.MatterConstants
import com.matter.virtual.device.app.core.common.sharedpreferences.SharedPreferencesKey
import com.matter.virtual.device.app.core.common.sharedpreferences.SharedPreferencesManager
import java.lang.reflect.Type
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class DoorLockManagerStub
@Inject
constructor(
  private val deviceApp: DeviceApp,
  private val sharedPreferencesManager: SharedPreferencesManager
) : DoorLockManager {

  private val _lockState = MutableStateFlow(false)
  val lockState: StateFlow<Boolean>
    get() = _lockState

  override fun initAttributeValue(endpoint: Int) {
    Timber.d("initAttributeValue():endpoint:$endpoint")
    deviceApp.setLockType(endpoint, DoorLockManager.DlLockType_kMagnetic)
    deviceApp.setLockState(endpoint, lockState.value.asLockState())
    deviceApp.setActuatorEnabled(endpoint, true)
    deviceApp.setOperatingMode(endpoint, DoorLockManager.DlOperatingMode_kNormal)
    deviceApp.setSupportedOperatingModes(
      endpoint,
      DoorLockManager.DlSupportedOperatingModes_kNormal
    )
  }

  override fun handleLockStateChanged(value: Int) {
    Timber.d("value:$value")
    _lockState.value = value.asBooleanLockState()
  }

  override fun handleLockCredential(index: Int, pin: String?) {
    Timber.d("Hit")
    setLockPin(index, pin!!)
  }

  override fun readLockCredential(index: Int): String {
    Timber.e("Hit")
    return getLockPin(index)
  }

  override fun isIndexFree(index: Int): Boolean {
    val pin = getLockPin(index)
    return pin == "" || pin.isEmpty() || pin == "null"
  }

  fun setLockState(value: Boolean) {
    Timber.d("setLockState():$value")
    deviceApp.setLockState(MatterConstants.DEFAULT_ENDPOINT, value.asLockState())
  }

  fun getRequirePINforRemoteOperation(): Boolean {
    val requirePinForRemoteOperation =
      deviceApp.getRequirePINforRemoteOperation(MatterConstants.DEFAULT_ENDPOINT)
    Timber.d("Hit : requirePINforRemoteOperation --> :${requirePinForRemoteOperation}")
    return requirePinForRemoteOperation
  }

  fun setRequirePINforRemoteOperation(value: Boolean) {
    Timber.d("Hit")
    deviceApp.setRequirePINforRemoteOperation(MatterConstants.DEFAULT_ENDPOINT, value)
  }

  fun sendLockAlarmEvent() {
    Timber.d("Hit")
    deviceApp.sendLockAlarmEvent(MatterConstants.DEFAULT_ENDPOINT)
  }

  private fun setLockPin(index: Int, pin: String) {
    try {
      val gson = Gson()
      val credentialMap = getCredentialMap()

      // removing current set pin by setting it to empty string
      if (pin == "remove") {
        credentialMap[index] = ""
        Timber.d("removed pin ${credentialMap[index]}")
      } else {
        // add new pin
        credentialMap[index] = pin
        Timber.d("added new pin ${credentialMap[index]}")
      }

      val json = gson.toJson(credentialMap)
      Timber.d("json string list after : $json")
      sharedPreferencesManager.setString(SharedPreferencesKey.LOCK_CREDENTIAL, json)
    } catch (e: Exception) {
      Timber.e("${e.message}")
    }
  }

  private fun getLockPin(index: Int): String {
    return try {
      val credentialList = getCredentialMap()
      credentialList[index].toString()
    } catch (e: Exception) {
      Timber.e("${e.message}")
      ""
    }
  }

  private fun getCredentialMap(): HashMap<Int, String> {
    val gson = Gson()
    val credentialMapJson = sharedPreferencesManager.getString(SharedPreferencesKey.LOCK_CREDENTIAL)
    val type: Type = object : TypeToken<HashMap<Int, String>>() {}.type
    Timber.d("json string list before : $credentialMapJson")
    return if (credentialMapJson.isEmpty()) {
      HashMap()
    } else {
      gson.fromJson(credentialMapJson, type)
    }
  }

  private fun Boolean.asLockState() =
    when (this) {
      true -> DoorLockManager.DlLockState_kUnlocked
      false -> DoorLockManager.DlLockState_kLocked
    }

  private fun Int.asBooleanLockState() =
    when (this) {
      DoorLockManager.DlLockState_kUnlocked -> true
      DoorLockManager.DlLockState_kLocked -> false
      else -> false
    }
}
