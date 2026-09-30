package com.matter.virtual.device.app.core.common.matter

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.*
import android.os.Build
import androidx.annotation.RequiresApi
import chip.platform.AndroidWiFiManager
import chip.platform.AndroidWiFiScanResult
import chip.platform.ChipWiFiCallback
import java.util.Collections.sort
import kotlinx.coroutines.*
import timber.log.Timber

class CustomWiFiManagerImpl(
  context: Context,
  private val customWifiManagerCallback: CustomWifiManagerCallback
) : AndroidWiFiManager {

  private var mContext: Context = context
  private var mWifiManager: WifiManager
  private var mWifiConnectReceiver: BroadcastReceiver? = null
  private var mWifiStateChangedReceiver: BroadcastReceiver? = null
  private var mIsConnectRequested = false
  private var mConnectRequestedSSID: String? = null
  private var mScanNetworkCallback: ChipWiFiCallback? = null
  private var mConnectNetworkCallback: ChipWiFiCallback? = null

  init {
    mWifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
    val wifiScanReceiver =
      object : BroadcastReceiver() {
        override fun onReceive(c: Context?, intent: Intent?) {
          if (mScanNetworkCallback != null) {
            mScanNetworkCallback!!.onScanDone()
          }
        }
      }
    val intentFilter = IntentFilter()
    intentFilter.addAction(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
    mContext.registerReceiver(wifiScanReceiver, intentFilter)
  }

  fun getConnectedNetworkName(): String {
    Timber.i("Get connected network name")
    if (!mWifiManager.isWifiEnabled) {
      Timber.e("Wi-Fi is not enabled")
      return ""
    }
    val info = mWifiManager.connectionInfo
    if (info == null) {
      Timber.e("Wi-Fi is not connected")
      return ""
    }
    val ssid = info.ssid.replace("^\"|\"$".toRegex(), "")
    Timber.i("Connected Wi-Fi AP is $ssid")
    return ssid
  }

  @DelicateCoroutinesApi
  override fun connectNetwork(ssid: String, password: String, callback: ChipWiFiCallback): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      connectNetworkNew(ssid, password, callback)
    } else {
      connectNetworkOld(ssid, password, callback)
    }
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  private fun connectNetworkNew(
    ssid: String,
    password: String,
    callback: ChipWiFiCallback
  ): Boolean {
    Timber.i("Connect network. ssid: $ssid")

    if (!mWifiManager.isWifiEnabled) {
      Timber.e("Wi-Fi is disabled")
      return false
    }

    val connectedSSID = getConnectedNetworkName()
    return if (connectedSSID == ssid) {
      Timber.i("It is already connected to AP")
      callback.onConnected()
      true
    } else {
      Timber.e("AP mismatch [request:$ssid][connected:$connectedSSID]")
      customWifiManagerCallback.onWifiNotConnected()
      false
    }

    val sr: ScanResult? = findScanResultBySSID(ssid)
    if (sr == null) {
      Timber.e("Not found AP. ssid: $ssid")
      return false
    }

    val networkSuggestionBuilder =
      WifiNetworkSuggestion.Builder().setSsid(ssid).setIsAppInteractionRequired(true)
    when (covertCapabilitiesToWiFiSecurity(sr.capabilities)) {
      WIFI_SECURITY_UNENCRYPTED -> {
        // Skip unencrypted AP
        // TODO it is not tested
      }
      WIFI_SECURITY_WPA,
      WIFI_SECURITY_WPA2 -> {
        networkSuggestionBuilder.setWpa2Passphrase(password)
      }
      WIFI_SECURITY_WPA3 -> {
        // TODO it is not tested
        networkSuggestionBuilder.setWpa3Passphrase(password)
      }
      else -> {
        Timber.e("Not supported security type. capabilities: " + sr.capabilities)
        return false
      }
    }
    val networkSuggestion = networkSuggestionBuilder.build()
    val status = mWifiManager.addNetworkSuggestions(listOf(networkSuggestion))
    if (status != WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS) {
      Timber.e("Can not add network suggestion. status: $status")
      return false
    }
    mConnectRequestedSSID = ssid
    mIsConnectRequested = true
    mConnectNetworkCallback = callback
    val intentFilter = IntentFilter(WifiManager.ACTION_WIFI_NETWORK_SUGGESTION_POST_CONNECTION)
    mWifiConnectReceiver =
      object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
          if (!intent.action.equals(WifiManager.ACTION_WIFI_NETWORK_SUGGESTION_POST_CONNECTION)) {
            return
          }
          Timber.i("Wi-Fi connected")
          if (!mIsConnectRequested) {
            return
          }
          Timber.i("Wi-Fi connection requested")
          val connectedNetworkName = getConnectedNetworkName()
          if (connectedNetworkName == mConnectRequestedSSID) {
            Timber.i("Wi-Fi connected by connectNetwork")
            mConnectNetworkCallback!!.onConnected()
          }
          mContext.unregisterReceiver(mWifiConnectReceiver)
          mWifiConnectReceiver = null
          mIsConnectRequested = false
          mConnectRequestedSSID = null
        }
      }
    mContext.registerReceiver(mWifiConnectReceiver, intentFilter)
    // For fast connection.
    // This method was deprecated in API level 28.
    // The ability for apps to trigger scan requests will be removed in a future release.
    // ref: https://developer.android.com/reference/android/net/wifi/WifiManager#startScan()
    @Suppress("DEPRECATION") mWifiManager.startScan()
    return mIsConnectRequested
  }

  // TODO it is not tested
  @Suppress("DEPRECATION")
  private fun connectNetworkOld(
    ssid: String,
    password: String,
    callback: ChipWiFiCallback
  ): Boolean {
    Timber.i("Connect network. ssid: $ssid")

    if (!mWifiManager.isWifiEnabled) {
      return setWifiEnabled(
        object : AndroidWiFiEnabledCallback {
          override fun onWiFiEnabled() {
            Timber.i("Wi-Fi is enabled")
            connectNetworkOld(ssid, password, callback)
          }
        }
      )
    }

    val connectedSSID = getConnectedNetworkName()
    return if (connectedSSID == ssid) {
      Timber.i("It is already connected to AP")
      callback.onConnected()
      true
    } else {
      Timber.e("AP mismatch [request:$ssid][connected:$connectedSSID]")
      customWifiManagerCallback.onWifiNotConnected()
      false
    }

    val ssidWithQuotes = "\"$ssid\""
    val foundConf = findConfiguredNetworkBySSID(ssidWithQuotes)
    if (foundConf != null) {
      Timber.i("It already has WifiConfiguration")
      mConnectRequestedSSID = ssid
      mWifiManager.disconnect()
      mIsConnectRequested = mWifiManager.enableNetwork(foundConf.networkId, true)
      mWifiManager.reconnect()
      return mIsConnectRequested
    }

    val conf = WifiConfiguration()
    val sr: ScanResult? = findScanResultBySSID(ssid)
    if (sr == null) {
      Timber.e("Not found AP. ssid: $ssid")
      return false
    }
    val passwordWithQuotes = "\"$password\""
    conf.SSID = ssidWithQuotes
    when (covertCapabilitiesToWiFiSecurity(sr.capabilities)) {
      WIFI_SECURITY_UNENCRYPTED -> {
        // Skip unencrypted AP
      }
      WIFI_SECURITY_WEP -> {
        conf.wepKeys[0] = passwordWithQuotes
      }
      WIFI_SECURITY_WPA,
      WIFI_SECURITY_WPA2,
      WIFI_SECURITY_WPA3 -> {
        conf.preSharedKey = passwordWithQuotes
      }
      else -> {
        Timber.e("Not supported security type. capabilities: " + sr.capabilities)
        return false
      }
    }

    mConnectRequestedSSID = ssid
    val netId = mWifiManager.addNetwork(conf)
    mIsConnectRequested = mWifiManager.enableNetwork(netId, true)
    if (!mIsConnectRequested) {
      Timber.i("enableNetwork fails")
      return mIsConnectRequested
    }
    mConnectNetworkCallback = callback
    mWifiConnectReceiver =
      object : BroadcastReceiver() {
        override fun onReceive(c: Context?, intent: Intent) {
          if (!intent.getBooleanExtra(WifiManager.EXTRA_SUPPLICANT_CONNECTED, false)) {
            return
          }
          Timber.i("Wi-Fi connected")
          if (!mIsConnectRequested) {
            return
          }
          Timber.i("Wi-Fi connection requested")
          val connectedNetworkName = getConnectedNetworkName()
          if (connectedNetworkName == mConnectRequestedSSID) {
            Timber.i("Wi-Fi connected by connectNetwork")
            mConnectNetworkCallback!!.onConnected()
          }
          mContext.unregisterReceiver(mWifiConnectReceiver)
          mWifiConnectReceiver = null
          mIsConnectRequested = false
          mConnectRequestedSSID = null
        }
      }
    val intentFilter = IntentFilter()
    intentFilter.addAction(WifiManager.SUPPLICANT_CONNECTION_CHANGE_ACTION)
    mContext.registerReceiver(mWifiConnectReceiver, intentFilter)
    return mIsConnectRequested
  }

  // TODO it is not tested
  @Suppress("DEPRECATION")
  private fun setWifiEnabled(callback: AndroidWiFiEnabledCallback): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      Timber.e("${Build.VERSION.SDK_INT} version doesn't support to set Wi-Fi enabled")
      return false
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      Timber.e(
        "${Build.VERSION.SDK_INT} version supports to set Wi-Fi enabled, but it doesn't support to register Wi-Fi state changed callback"
      )
      return false
    }
    if (!mWifiManager.setWifiEnabled(true)) {
      Timber.e("Can not set Wi-Fi enabled")
      return false
    }
    Timber.i("Set Wi-Fi enabled")
    mWifiStateChangedReceiver =
      object : BroadcastReceiver() {
        override fun onReceive(c: Context?, intent: Intent?) {
          val state =
            intent?.getIntExtra(WifiManager.EXTRA_WIFI_STATE, WifiManager.WIFI_STATE_UNKNOWN)
          if (state == WifiManager.WIFI_STATE_ENABLED) {
            mContext.unregisterReceiver(mWifiStateChangedReceiver)
            mWifiStateChangedReceiver = null
            callback.onWiFiEnabled()
          }
        }
      }
    val intentFilter = IntentFilter()
    intentFilter.addAction(WifiManager.WIFI_STATE_CHANGED_ACTION)
    mContext.registerReceiver(mWifiStateChangedReceiver, intentFilter)
    return true
  }

  private fun findScanResultBySSID(ssid: String): ScanResult? {
    val results: List<ScanResult> = mWifiManager.scanResults
    for (sr in results) {
      if (ssid == sr.SSID) {
        return sr
      }
    }
    return null
  }

  @Suppress("DEPRECATION")
  @SuppressLint("MissingPermission")
  private fun findConfiguredNetworkBySSID(ssid: String): WifiConfiguration? {
    val list = mWifiManager.configuredNetworks
    for (i in list) {
      if (ssid == i.SSID) {
        return i
      }
    }
    return null
  }

  override fun scanNetworks(ssid: String?, callback: ChipWiFiCallback): Boolean {
    // TODO handle ssid
    // It's fine for now because SmartThings app doesn't request ScanNetworks with SSID.
    Timber.i("Scan networks. ssid: $ssid")

    if (!mWifiManager.isWifiEnabled) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        Timber.e("Wi-Fi is disabled")
        return false
      }
      // TODO it is not tested
      return setWifiEnabled(
        object : AndroidWiFiEnabledCallback {
          override fun onWiFiEnabled() {
            Timber.i("Wi-Fi is enabled")
            scanNetworks(ssid, callback)
          }
        }
      )
    }

    // This method was deprecated in API level 28.
    // The ability for apps to trigger scan requests will be removed in a future release.
    // ref: https://developer.android.com/reference/android/net/wifi/WifiManager#startScan()
    @Suppress("DEPRECATION") val isSuccess = mWifiManager.startScan()
    if (isSuccess) {
      mScanNetworkCallback = callback
    } else {
      callback.onScanDone()
    }
    return isSuccess
  }

  override fun getScanResults(): List<AndroidWiFiScanResult> {
    Timber.i("Get scan results")
    val results: List<ScanResult> = mWifiManager.scanResults
    val awScanResults = convertScanResultsToAndroidWiFiScanResults(results)
    sort(awScanResults) { sr1, sr2 -> sr2.rssi - sr1.rssi }
    return awScanResults
  }

  private fun convertScanResultsToAndroidWiFiScanResults(
    results: List<ScanResult>
  ): List<AndroidWiFiScanResult> {
    val awScanResults: MutableList<AndroidWiFiScanResult> = ArrayList()
    for (sr in results) {
      val channel = convertFrequencyMhzToChannelIfSupported(sr.frequency)
      val band = covertFrequencyMhzToWiFiBandIfSupported(sr.frequency)
      val security = covertCapabilitiesToWiFiSecurity(sr.capabilities)
      val bssid: String = sr.BSSID.replace(":", "")
      // Skip unsupported AP
      if (sr.SSID.isEmpty() || channel == -1 || band == -1 || security == WIFI_SECURITY_EAP) {
        continue
      }
      // It seems that connection from Android Q to Wi-Fi WEP AP is not supported.
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && security == WIFI_SECURITY_WEP) {
        continue
      }
      val result = AndroidWiFiScanResult(security, sr.SSID, bssid, channel, band, sr.level)
      awScanResults.add(result)
    }
    return awScanResults
  }

  private fun covertCapabilitiesToWiFiSecurity(capabilities: String): Int {
    if (capabilities.contains("EAP")) {
      return WIFI_SECURITY_EAP
    } else if (capabilities.contains("WPA3")) {
      return WIFI_SECURITY_WPA3
    } else if (capabilities.contains("WPA2")) {
      return WIFI_SECURITY_WPA2
    } else if (capabilities.contains("WPA")) {
      return WIFI_SECURITY_WPA
    } else if (capabilities.contains("WEP")) {
      return WIFI_SECURITY_WEP
    }
    return WIFI_SECURITY_UNENCRYPTED
  }

  private fun convertFrequencyMhzToChannelIfSupported(freqMhz: Int): Int {
    if (freqMhz == 2484) {
      return 14
    } else if (is24GHz(freqMhz)) {
      return (freqMhz - BAND_24_GHZ_START_FREQ_MHZ) / 5 + BAND_24_GHZ_FIRST_CH_NUM
    } else if (is5GHz(freqMhz)) {
      return (freqMhz - BAND_5_GHZ_START_FREQ_MHZ) / 5 + BAND_5_GHZ_FIRST_CH_NUM
    } else if (is6GHz(freqMhz)) {
      return if (freqMhz == BAND_6_GHZ_OP_CLASS_136_CH_2_FREQ_MHZ) {
        2
      } else (freqMhz - BAND_6_GHZ_START_FREQ_MHZ) / 5 + BAND_6_GHZ_FIRST_CH_NUM
    } else if (is60GHz(freqMhz)) {
      return (freqMhz - BAND_60_GHZ_START_FREQ_MHZ) / 2160 + BAND_60_GHZ_FIRST_CH_NUM
    }
    return -1
  }

  private fun covertFrequencyMhzToWiFiBandIfSupported(freqMhz: Int): Int {
    if (is24GHz(freqMhz)) {
      return WIFI_BAND_2G4
    } else if (is5GHz(freqMhz)) {
      return WIFI_BAND_5G
    } else if (is6GHz(freqMhz)) {
      return WIFI_BAND_6G
    } else if (is60GHz(freqMhz)) {
      return WIFI_BAND_60G
    }
    return -1
  }

  private fun is24GHz(freqMhz: Int): Boolean {
    return freqMhz in BAND_24_GHZ_START_FREQ_MHZ..BAND_24_GHZ_END_FREQ_MHZ
  }

  private fun is5GHz(freqMhz: Int): Boolean {
    return freqMhz in BAND_5_GHZ_START_FREQ_MHZ..BAND_5_GHZ_END_FREQ_MHZ
  }

  private fun is6GHz(freqMhz: Int): Boolean {
    return if (freqMhz == BAND_6_GHZ_OP_CLASS_136_CH_2_FREQ_MHZ) {
      true
    } else freqMhz in BAND_6_GHZ_START_FREQ_MHZ..BAND_6_GHZ_END_FREQ_MHZ
  }

  @Suppress("unused")
  private fun is6GHzPsc(freqMhz: Int): Boolean {
    return if (!is6GHz(freqMhz)) {
      false
    } else (freqMhz - BAND_6_GHZ_PSC_START_MHZ) % BAND_6_GHZ_PSC_STEP_SIZE_MHZ == 0
  }

  private fun is60GHz(freqMhz: Int): Boolean {
    return freqMhz in BAND_60_GHZ_START_FREQ_MHZ..BAND_60_GHZ_END_FREQ_MHZ
  }

  override fun isConnectedNetwork(ssid: String): Boolean {
    Timber.i("Is connect network. ssid: $ssid")
    return getConnectedNetworkName() == ssid
  }

  @Suppress("unused")
  companion object {
    private const val BAND_24_GHZ_FIRST_CH_NUM = 1
    private const val BAND_24_GHZ_LAST_CH_NUM = 14
    private const val BAND_24_GHZ_START_FREQ_MHZ = 2412
    private const val BAND_24_GHZ_END_FREQ_MHZ = 2484
    private const val BAND_5_GHZ_FIRST_CH_NUM = 32
    private const val BAND_5_GHZ_LAST_CH_NUM = 177
    private const val BAND_5_GHZ_START_FREQ_MHZ = 5160
    private const val BAND_5_GHZ_END_FREQ_MHZ = 5885
    private const val BAND_6_GHZ_FIRST_CH_NUM = 1
    private const val BAND_6_GHZ_LAST_CH_NUM = 233
    private const val BAND_6_GHZ_START_FREQ_MHZ = 5955
    private const val BAND_6_GHZ_END_FREQ_MHZ = 7115
    private const val BAND_6_GHZ_PSC_START_MHZ = 5975
    private const val BAND_6_GHZ_PSC_STEP_SIZE_MHZ = 80
    private const val BAND_6_GHZ_OP_CLASS_136_CH_2_FREQ_MHZ = 5935
    private const val BAND_60_GHZ_FIRST_CH_NUM = 1
    private const val BAND_60_GHZ_LAST_CH_NUM = 6
    private const val BAND_60_GHZ_START_FREQ_MHZ = 58320
    private const val BAND_60_GHZ_END_FREQ_MHZ = 70200

    private const val WIFI_BAND_2G4 = 0x00
    private const val WIFI_BAND_5G = 0x02
    private const val WIFI_BAND_6G = 0x03
    private const val WIFI_BAND_60G = 0x04

    private const val WIFI_SECURITY_UNKNOWN = -1
    private const val WIFI_SECURITY_UNENCRYPTED = 1
    private const val WIFI_SECURITY_WEP = 2
    private const val WIFI_SECURITY_WPA = 3
    private const val WIFI_SECURITY_WPA2 = 4
    private const val WIFI_SECURITY_WPA3 = 5
    private const val WIFI_SECURITY_EAP = 6
  }
}

interface AndroidWiFiEnabledCallback {
  fun onWiFiEnabled()
}
