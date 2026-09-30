package com.matter.virtual.device.app

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.*
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.*
import androidx.activity.viewModels
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.matter.virtual.device.app.core.common.event.EventObserver
import com.matter.virtual.device.app.core.ui.SharedViewModel
import com.matter.virtual.device.app.core.ui.UiState
import com.matter.virtual.device.app.databinding.ActivityMainBinding
import dagger.hilt.android.AndroidEntryPoint
import java.lang.Runnable
import java.util.*
import kotlin.concurrent.timer
import kotlin.system.exitProcess
import kotlinx.coroutines.*
import timber.log.Timber

@AndroidEntryPoint
class MainActivity : AppCompatActivity() {

  private lateinit var binding: ActivityMainBinding
  private val viewModel by viewModels<SharedViewModel>()
  private var powerManager: PowerManager? = null
  private var wakeLock: PowerManager.WakeLock? = null
  private var wakeLockTimer: Timer? = null
  private var wifiManager: WifiManager? = null
  private var wifiLock: WifiManager.WifiLock? = null
  private var wifiLockTimer: Timer? = null
  private val permissions =
    arrayOf(
      Manifest.permission.BLUETOOTH,
      Manifest.permission.BLUETOOTH_ADMIN,
      Manifest.permission.BLUETOOTH_SCAN,
      Manifest.permission.BLUETOOTH_ADVERTISE,
      Manifest.permission.BLUETOOTH_CONNECT,
      Manifest.permission.INTERNET,
      Manifest.permission.ACCESS_NETWORK_STATE,
      Manifest.permission.ACCESS_WIFI_STATE,
      Manifest.permission.CHANGE_WIFI_STATE,
      Manifest.permission.CHANGE_WIFI_MULTICAST_STATE,
      Manifest.permission.ACCESS_FINE_LOCATION,
      Manifest.permission.ACCESS_COARSE_LOCATION,
      Manifest.permission.CHANGE_NETWORK_STATE,
      Manifest.permission.WAKE_LOCK,
      Manifest.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
    )

  @SuppressLint("BatteryLife")
  override fun onCreate(savedInstanceState: Bundle?) {
    Timber.d("Hit")
    super.onCreate(savedInstanceState)
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

    binding = ActivityMainBinding.inflate(layoutInflater)
    setContentView(binding.root)

    val isPermissionGranted =
      permissions.all {
        ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
      }
    if (!isPermissionGranted) {
      requestPermissions(permissions, REQUEST_CODE_PERMISSION)
    }

    powerManager = applicationContext.getSystemService(POWER_SERVICE) as PowerManager?
    powerManager?.let { manager ->
      if (!manager.isIgnoringBatteryOptimizations(packageName)) {
        Timber.d("not in battery optimization whitelist")
        val intent =
          Intent().apply {
            action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            data = Uri.parse("package:$packageName")
          }
        startActivity(intent)
      }

      this.wakeLockTimer =
        timer(period = 90 * 1000L, initialDelay = 1000) {
          Timber.d("wakelock timer hit")
          wakeLock?.let {
            if (it.isHeld) {
              Timber.d("wakelock release")
              it.release()
              wakeLock = null
            }
          }

          wakeLock =
            powerManager?.newWakeLock(
              PowerManager.PARTIAL_WAKE_LOCK,
              MainActivity::class.java.simpleName
            )

          Timber.d("wakelock acquire")
          wakeLock?.setReferenceCounted(false)
          wakeLock?.acquire(10 * 60 * 1000L /*10 minutes*/)
        }
    }

    wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager?
    wifiManager?.let {
      this.wifiLockTimer =
        timer(period = 90 * 1000L, initialDelay = 1000) {
          Timber.d("wifiLock timer hit")
          wifiLock?.let {
            if (it.isHeld) {
              Timber.d("wifiLock release")
              it.release()
              wifiLock = null
            }
          }

          wifiLock =
            wifiManager?.createWifiLock(
              WifiManager.WIFI_MODE_FULL_HIGH_PERF,
              MainActivity::class.java.simpleName
            )

          Timber.d("wifiLock acquire")
          wifiLock?.setReferenceCounted(false)
          wifiLock?.acquire()
        }
    }

    val bluetoothManager =
      applicationContext.getSystemService(BLUETOOTH_SERVICE) as BluetoothManager?
    val bluetoothAdapter = bluetoothManager?.adapter
    bluetoothAdapter?.let {
      if (!it.isEnabled) {
        Timber.i("onCreate:activate BT")
        it.enable()
      } else {
        Timber.i("onCreate:deactivate BT")
        it.disable()
        Thread.sleep(300)

        Timber.i("onCreate:activate BT")
        it.enable()
      }
      Thread.sleep(700)
    }

    viewModel.uiState.observe(
      this,
      EventObserver { uiState ->
        when (uiState) {
          UiState.Waiting -> {
            binding.progress.visibility = View.VISIBLE
          }
          UiState.Exit -> {
            binding.progress.visibility = View.GONE
            finishAffinity()
          }
          is UiState.Reset -> {
            showFactoryResetPopup(getString(uiState.messageResId), uiState.isCancelable)
          }
          else -> {}
        }
      }
    )

    // Make the Matter Device App busy during BLE commissioning.
    // Because android phone fails to process BLE packets on time due to context switching
    // that occurs to share BT resources in multiple processes.
    // Therefore, to reduce this context switching, Matter Device App is made busy as follows.
    val job =
      CoroutineScope(Dispatchers.Default).launch {
        try {
          var i = 1
          while (isActive) {
            if (i % 100000 == 0) // Timber.d("Ble keep Busyloop:$i")
             i += 1
          }
        } catch (_: Exception) {}
      }

    val cancelJob = Runnable { CoroutineScope(Dispatchers.Default).launch { job.cancelAndJoin() } }

    Handler(Looper.getMainLooper()).postDelayed(cancelJob, 3 * 60 * 1000)

    viewModel.closeBusyLoop.observe(this) {
      if (it) {
        Timber.d("closeBusyLoop event observed")
        Handler(Looper.getMainLooper()).removeCallbacks(cancelJob)
        cancelJob.run()
      }
    }
  }

  override fun onDestroy() {
    Timber.d("Hit")

    if (wakeLock?.isHeld == true) {
      Timber.d("wakelock release")
      wakeLock?.release()
      wakeLock = null
    }

    if (wifiLock?.isHeld == true) {
      Timber.d("wifiLock release")
      wifiLock?.release()
      wifiLock = null
    }

    wakeLockTimer?.let {
      Timber.d("wakeLockTimer cancel")
      it.cancel()
      wakeLockTimer = null
    }

    wifiLockTimer?.let {
      Timber.d("wifiLockTimer cancel")
      it.cancel()
      wifiLockTimer = null
    }

    val bluetoothManager =
      applicationContext.getSystemService(BLUETOOTH_SERVICE) as BluetoothManager?
    val bluetoothAdapter = bluetoothManager?.adapter
    bluetoothAdapter?.let {
      if (it.isEnabled) {
        Timber.i("onDestroy:deactivate BT")
        it.disable()
        Thread.sleep(200)
      }
    }

    super.onDestroy()

    Handler(Looper.getMainLooper())
      .postDelayed(
        {
          Timber.d("Exit process")
          exitProcess(0)
        },
        100
      )
  }

  override fun onOptionsItemSelected(item: MenuItem): Boolean {
    when (item.itemId) {
      android.R.id.home -> {
        onBackPressed()
        return true
      }
    }

    return super.onOptionsItemSelected(item)
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ) {
    Timber.d("RequestCode:$requestCode")
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
  }

  private fun showFactoryResetPopup(message: String, isCancelable: Boolean) {
    val builder =
      AlertDialog.Builder(this)
        .setTitle("Factory Reset")
        .setMessage(message)
        .setPositiveButton("Ok") { dialog, _ ->
          Timber.d("Ok")
          dialog.dismiss()
          viewModel.resetMatterAppServer()
        }
        .setCancelable(false)

    if (isCancelable) {
      builder.setNegativeButton("Cancel") { dialog, _ ->
        Timber.d("Cancel")
        dialog.dismiss()
      }
    }

    val dialog = builder.create()
    dialog.window?.setGravity(Gravity.BOTTOM)
    dialog.show()
  }

  companion object {
    private const val REQUEST_CODE_PERMISSION = 1100
  }
}
