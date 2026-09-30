package com.matter.virtual.device.app.core.data.repository

import android.content.Context
import android.net.wifi.SupplicantState
import android.net.wifi.WifiManager
import dagger.hilt.android.qualifiers.ApplicationContext
import java.net.Inet4Address
import java.net.InetAddress
import java.net.NetworkInterface
import java.net.UnknownHostException
import javax.inject.Inject
import timber.log.Timber

internal class NetworkRepositoryImpl
@Inject
constructor(@ApplicationContext private val context: Context) : NetworkRepository {

  override suspend fun getSSID(): String {
    Timber.d("Hit")
    return try {
      val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager?
      wifiManager?.let {
        val wifiInfo = wifiManager.connectionInfo
        var ssid = ""
        if (wifiInfo.supplicantState == SupplicantState.COMPLETED) {
          Timber.d("SSID:${wifiInfo.ssid}")
          ssid = wifiInfo.ssid.replace("\"", "")
        }

        ssid
      }
        ?: "Unknown"
    } catch (e: Exception) {
      Timber.e("Exception", e)
      "Unknown"
    }
  }

  override suspend fun getIpAddress(): String {
    Timber.d("Hit")
    var result = ""
    runCatching {
        NetworkInterface.getNetworkInterfaces().iterator().forEach { networkInterface ->
          networkInterface.inetAddresses.iterator().forEach { inetAddress ->
            inetAddress.hostAddress?.let {
              if (!inetAddress.isLoopbackAddress && isIPv4(it)) {
                result = it
              }
            }
          }
        }
      }
      .onFailure { Timber.e(it, "error") }

    return result
  }

  private fun isIPv4(address: String?): Boolean {
    return address?.let {
      if (it.isEmpty()) {
        false
      } else {
        try {
          InetAddress.getByName(address) is Inet4Address
        } catch (e: UnknownHostException) {
          false
        }
      }
    }
      ?: false
  }
}
