package com.matter.virtual.device.app.core.data.repository

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.matter.virtual.device.app.core.common.Device
import com.matter.virtual.device.app.core.common.sharedpreferences.SharedPreferencesKey
import com.matter.virtual.device.app.core.common.sharedpreferences.SharedPreferencesManager
import java.lang.reflect.Type
import javax.inject.Inject
import timber.log.Timber

internal class SharedPreferencesRepositoryImpl
@Inject
constructor(private val sharedPreferencesManager: SharedPreferencesManager) :
  SharedPreferencesRepository {

  override suspend fun isCommissioningDeviceCompleted(): Boolean {
    return sharedPreferencesManager.getBoolean(SharedPreferencesKey.COMMISSIONING_DEVICE_COMPLETED)
  }

  override suspend fun setCommissioningDeviceCompleted(value: Boolean) {
    sharedPreferencesManager.setBoolean(SharedPreferencesKey.COMMISSIONING_DEVICE_COMPLETED, value)
  }

  override suspend fun getCommissionedDevice(): Device {
    return Device.map(sharedPreferencesManager.getString(SharedPreferencesKey.COMMISSIONED_DEVICE))
  }

  override suspend fun setCommissionedDevice(device: Device) {
    sharedPreferencesManager.setString(SharedPreferencesKey.COMMISSIONED_DEVICE, device.title)
  }

  override suspend fun deleteMatterSharedPreferences() {
    sharedPreferencesManager.deleteMatterSharedPreferences()
  }

  override suspend fun setCommissioningSequence(value: Boolean) {
    sharedPreferencesManager.setBoolean(SharedPreferencesKey.COMMISSIONING_SEQUENCE, value)
  }

  override suspend fun isCommissioningSequence(): Boolean {
    return sharedPreferencesManager.getBoolean(SharedPreferencesKey.COMMISSIONING_SEQUENCE)
  }

  override suspend fun checkLockPin(pin: String): Boolean {
    val credentialList = getCredentialMap()
    for (cred in credentialList) {
      if (cred.value == pin) {
        Timber.d("PIN Found")
        return true
      }
    }
    Timber.e("PIN Not Found")
    return false
  }

  private fun getCredentialMap(): HashMap<Int, String> {
    val gson = Gson()
    val credentialMapJson = sharedPreferencesManager.getString(SharedPreferencesKey.LOCK_CREDENTIAL)
    val type: Type = object : TypeToken<HashMap<Int, String>>() {}.type
    Timber.d("json string list $credentialMapJson")
    return gson.fromJson(credentialMapJson, type)
  }
}
