package com.matter.virtual.device.app.core.data.repository

interface BluetoothRepository {
  suspend fun resetGattServer()
}
