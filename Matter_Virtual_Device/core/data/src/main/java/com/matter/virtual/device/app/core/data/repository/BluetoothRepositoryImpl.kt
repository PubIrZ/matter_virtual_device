package com.matter.virtual.device.app.core.data.repository

import android.Manifest
import android.bluetooth.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeout
import timber.log.Timber

internal class BluetoothRepositoryImpl
@Inject
constructor(@ApplicationContext private val context: Context) : BluetoothRepository {

  private var bluetoothGattServer: BluetoothGattServer? = null

  override suspend fun resetGattServer() {
    Timber.d("Hit")
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (
        ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
          PackageManager.PERMISSION_GRANTED
      ) {
        Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
        return
      }
    }

    return withTimeout(300) {
      suspendCancellableCoroutine {
        try {
          val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
          bluetoothGattServer =
            bluetoothManager?.openGattServer(
              context,
              object : BluetoothGattServerCallback() {
                override fun onConnectionStateChange(
                  device: BluetoothDevice?,
                  status: Int,
                  newState: Int
                ) {
                  Timber.d("status:$status,newState:$newState")
                  val isSuccess = (status == BluetoothGatt.GATT_SUCCESS)
                  val isConnected = (newState == BluetoothProfile.STATE_CONNECTED)

                  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (
                      ActivityCompat.checkSelfPermission(
                        context,
                        Manifest.permission.BLUETOOTH_CONNECT
                      ) != PackageManager.PERMISSION_GRANTED
                    ) {
                      Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
                      return
                    }
                  }

                  if (isSuccess && isConnected) {
                    Timber.i("cancelConnection:${device?.address}")
                    bluetoothGattServer?.cancelConnection(device)
                    bluetoothGattServer?.close() // close GattServer
                    bluetoothGattServer = null
                    Timber.i("resetGattServer:deactivate BT")
                    bluetoothManager?.getAdapter()?.disable()
                    Thread.sleep(100)
                    // do not activate BT
                    // bluetoothManager?.getAdapter()?.enable()
                  }
                }
              }
            )
        } catch (e: Exception) {
          Timber.e("Exception", e)
        }
      }
    }
  }
}
