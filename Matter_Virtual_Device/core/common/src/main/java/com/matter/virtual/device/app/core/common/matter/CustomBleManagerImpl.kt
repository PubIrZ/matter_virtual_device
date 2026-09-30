package com.matter.virtual.device.app.core.common.matter

import android.Manifest
import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import androidx.core.app.ActivityCompat
import chip.platform.AndroidChipPlatform
import chip.platform.BleCallback
import chip.platform.BleManager
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.*
import javax.inject.Inject
import timber.log.Timber

class CustomBleManagerImpl
@Inject
constructor(@ApplicationContext private val context: Context, private val isEnabled: Boolean) :
  BleManager {

  private val connections = ArrayList<BluetoothGatt?>(INITIAL_CONNECTIONS)
  private val subscribedDevices = ArrayList<BluetoothDevice?>(INITIAL_CONNECTIONS)
  private var bleCallback: BleCallback? = null
  private var androidChipPlatform: AndroidChipPlatform? = null
  private var bluetoothManager: BluetoothManager? = null
  private var bluetoothGattServer: BluetoothGattServer? = null
  private var notifyingService: BluetoothGattService? = null
  private var notifyingCharacteristic: BluetoothGattCharacteristic? = null
  private var flag: Long = 0
  private val advertiseCallback =
    object : AdvertiseCallback() {
      override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
        super.onStartSuccess(settingsInEffect)
        Timber.i("onStartSuccess()")
      }

      override fun onStartFailure(errorCode: Int) {
        super.onStartFailure(errorCode)
        Timber.e("onStartFailure():errorCode:$errorCode")
      }
    }
  private val bluetoothGattServerCallback =
    object : BluetoothGattServerCallback() {
      override fun onConnectionStateChange(device: BluetoothDevice?, status: Int, newState: Int) {
        Timber.d("status:$status,newState:$newState")
        val isSuccess = (status == BluetoothGatt.GATT_SUCCESS)
        val isConnected = (newState == BluetoothProfile.STATE_CONNECTED)
        if (isSuccess && isConnected) {
          val connId: Int = subscribeDevice(device)
          Timber.i("BLE connection established connId: $connId,${device?.address}")
        } else {
          val connId: Int = getConnId(device)
          unsubscribeDevice(connId)
          Timber.i("BLE connection terminated connId: $connId,${device?.address}")
        }
      }

      override fun onServiceAdded(status: Int, service: BluetoothGattService?) {
        super.onServiceAdded(status, service)
        Timber.i("onServiceAdded():${service?.uuid}")
      }

      override fun onCharacteristicWriteRequest(
        device: BluetoothDevice?,
        requestId: Int,
        characteristic: BluetoothGattCharacteristic?,
        preparedWrite: Boolean,
        responseNeeded: Boolean,
        offset: Int,
        value: ByteArray?
      ) {
        super.onCharacteristicWriteRequest(
          device,
          requestId,
          characteristic,
          preparedWrite,
          responseNeeded,
          offset,
          value
        )
        val connId: Int = getConnId(device)
        val uuid = characteristic!!.uuid
        Timber.i(
          "Characteristic write request received" +
            " connId: " +
            connId +
            " uuid: " +
            uuid.toString() +
            " value: " +
            convertBytesToHexString(value!!)
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          if (
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
              PackageManager.PERMISSION_GRANTED
          ) {
            Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
            return
          }
        }

        if (uuid.equals(CHAR_1_UUID)) {
          characteristic.value = value
          val svcIdBytes: ByteArray = convertUUIDToBytes(SERVICE_UUID)
          val charIdBytes: ByteArray = convertUUIDToBytes(uuid)
          androidChipPlatform?.handleWriteReceived(
            connId,
            svcIdBytes,
            charIdBytes,
            characteristic.value
          )
          bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
        } else {
          bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, 0, null)
        }
      }

      override fun onDescriptorWriteRequest(
        device: BluetoothDevice?,
        requestId: Int,
        descriptor: BluetoothGattDescriptor?,
        preparedWrite: Boolean,
        responseNeeded: Boolean,
        offset: Int,
        value: ByteArray?
      ) {
        super.onDescriptorWriteRequest(
          device,
          requestId,
          descriptor,
          preparedWrite,
          responseNeeded,
          offset,
          value
        )
        val connId: Int = getConnId(device)
        val uuid = descriptor!!.uuid
        Timber.i(
          "Descriptor write request received" +
            " connId: " +
            connId +
            " uuid: " +
            uuid.toString() +
            " value: " +
            convertBluetoothGattDescriptorValueToString(value!!)
        )
        val svcIdBytes: ByteArray = convertUUIDToBytes(SERVICE_UUID)
        val charIdBytes: ByteArray = convertUUIDToBytes(CHAR_2_UUID)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          if (
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
              PackageManager.PERMISSION_GRANTED
          ) {
            Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
            return
          }
        }

        if (
          Arrays.equals(value, BluetoothGattDescriptor.ENABLE_INDICATION_VALUE) ||
            Arrays.equals(value, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
        ) {
          descriptor.value = value
          androidChipPlatform?.handleSubscribeReceived(connId, svcIdBytes, charIdBytes)
          bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
        } else if (Arrays.equals(value, BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE)) {
          descriptor.value = value
          androidChipPlatform?.handleUnsubscribeReceived(connId, svcIdBytes, charIdBytes)
          bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
        } else {
          Timber.e("Unexpected onDescriptorWriteRequest().")
          bluetoothGattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, 0, null)
        }
      }

      override fun onNotificationSent(device: BluetoothDevice?, status: Int) {
        val connId: Int = getConnId(device)
        val isSuccess = (status == BluetoothGatt.GATT_SUCCESS)
        Timber.i("Notification sent connId: $connId isSuccess: $isSuccess")
        if (isSuccess) {
          val serviceUuid: UUID? = notifyingService?.uuid
          val characteristicUuid: UUID? = notifyingCharacteristic?.uuid
          val svcIdBytes: ByteArray = convertUUIDToBytes(serviceUuid!!)
          val charIdBytes: ByteArray = convertUUIDToBytes(characteristicUuid!!)
          androidChipPlatform?.handleIndicationConfirmation(connId, svcIdBytes, charIdBytes)
        }
      }
    }

  private val bluetoothGattCallback =
    object : BluetoothGattCallback() {
      override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
        var connId = 0

        if (newState == BluetoothProfile.STATE_DISCONNECTED) {
          connId = getConnId(gatt)
          if (connId > 0) {
            Timber.d("onConnectionStateChange Disconnected")
            androidChipPlatform?.handleConnectionError(connId)
          } else {
            Timber.e("onConnectionStateChange disconnected: no active connection")
          }
        }
      }

      override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
        super.onServicesDiscovered(gatt, status)
      }

      override fun onCharacteristicRead(
        gatt: BluetoothGatt?,
        characteristic: BluetoothGattCharacteristic?,
        status: Int
      ) {
        super.onCharacteristicRead(gatt, characteristic, status)
      }

      override fun onCharacteristicWrite(
        gatt: BluetoothGatt?,
        characteristic: BluetoothGattCharacteristic?,
        status: Int
      ) {
        val svcIdBytes: ByteArray = convertUUIDToBytes(characteristic!!.service.uuid)
        val charIdBytes: ByteArray = convertUUIDToBytes(characteristic.uuid)

        if (status != BluetoothGatt.GATT_SUCCESS) {
          Timber.e(
            "onCharacteristicWrite for " +
              characteristic.uuid.toString() +
              " failed with status: " +
              status
          )
          return
        }

        val connId: Int = getConnId(gatt)
        if (connId > 0) {
          androidChipPlatform?.handleWriteConfirmation(
            connId,
            svcIdBytes,
            charIdBytes,
            status == BluetoothGatt.GATT_SUCCESS
          )
        } else {
          Timber.e("onCharacteristicWrite no active connection")
          return
        }
      }

      override fun onCharacteristicChanged(
        gatt: BluetoothGatt?,
        characteristic: BluetoothGattCharacteristic?
      ) {
        val svcIdBytes: ByteArray = convertUUIDToBytes(characteristic!!.service.uuid)
        val charIdBytes: ByteArray = convertUUIDToBytes(characteristic.uuid)
        val connId: Int = getConnId(gatt)
        if (connId > 0) {
          androidChipPlatform?.handleIndicationReceived(
            connId,
            svcIdBytes,
            charIdBytes,
            characteristic.value
          )
        } else {
          Timber.e("onCharacteristicChanged no active connection")
          return
        }
      }

      override fun onDescriptorWrite(
        gatt: BluetoothGatt?,
        descriptor: BluetoothGattDescriptor?,
        status: Int
      ) {
        val characteristic: BluetoothGattCharacteristic? = descriptor?.characteristic

        val svcIdBytes: ByteArray = convertUUIDToBytes(characteristic?.service?.uuid!!)
        val charIdBytes: ByteArray = convertUUIDToBytes(characteristic.uuid!!)

        if (status != BluetoothGatt.GATT_SUCCESS) {
          Timber.e(
            "onDescriptorWrite for " + descriptor.uuid.toString() + " failed with status: " + status
          )
        }

        val connId: Int = getConnId(gatt)
        if (connId == 0) {
          Timber.e("onDescriptorWrite no active connection")
          return
        }

        if (descriptor.value.contentEquals(BluetoothGattDescriptor.ENABLE_INDICATION_VALUE)) {
          androidChipPlatform?.handleSubscribeComplete(
            connId,
            svcIdBytes,
            charIdBytes,
            status == BluetoothGatt.GATT_SUCCESS
          )
        } else if (
          descriptor.value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
        ) {
          androidChipPlatform?.handleSubscribeComplete(
            connId,
            svcIdBytes,
            charIdBytes,
            status == BluetoothGatt.GATT_SUCCESS
          )
        } else if (
          descriptor.value.contentEquals(BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE)
        ) {
          androidChipPlatform?.handleUnsubscribeComplete(
            connId,
            svcIdBytes,
            charIdBytes,
            status == BluetoothGatt.GATT_SUCCESS
          )
        } else {
          Timber.d("Unexpected onDescriptorWrite().")
        }
      }

      override fun onDescriptorRead(
        gatt: BluetoothGatt?,
        descriptor: BluetoothGattDescriptor?,
        status: Int
      ) {
        super.onDescriptorRead(gatt, descriptor, status)
      }
    }

  @Synchronized
  fun subscribeDevice(device: BluetoothDevice?): Int {
    var connIndex = 0
    while (connIndex < subscribedDevices.size) {
      if (subscribedDevices[connIndex] == null) {
        subscribedDevices[connIndex] = device
        return connIndex + 1
      }
      connIndex++
    }
    subscribedDevices.add(connIndex, device)
    return connIndex + 1
  }

  @Synchronized
  fun unsubscribeDevice(connId: Int): BluetoothDevice? {
    val connIndex = connId - 1
    return if (connIndex >= 0 && connIndex < subscribedDevices.size) {
      // Set to null, rather than remove, so that other indexes are unchanged.
      subscribedDevices.set(connIndex, null)
    } else {
      Timber.e("Trying to remove unknown connId $connId")
      null
    }
  }

  @Synchronized
  private fun getConnId(bluetoothGatt: BluetoothGatt?): Int {
    // Find callback given gatt
    var connIndex = 0
    while (connIndex < connections.size) {
      val inGatt: BluetoothGatt? = connections[connIndex]
      if (inGatt == bluetoothGatt && bluetoothGatt != null) {
        return connIndex + 1
      }
      connIndex++
    }
    return 0
  }

  @Synchronized
  private fun getConnId(bluetoothDevice: BluetoothDevice?): Int {
    // Find callback given device
    var connIndex = 0
    while (connIndex < subscribedDevices.size) {
      val inDevice: BluetoothDevice? = subscribedDevices[connIndex]
      if (bluetoothDevice?.equals(inDevice) == true) {
        return connIndex + 1
      }
      connIndex++
    }
    return 0
  }

  @Synchronized
  fun getSubscribedDevice(connId: Int): BluetoothDevice? {
    val connIndex = connId - 1
    return if (connIndex >= 0 && connIndex < subscribedDevices.size) {
      subscribedDevices[connIndex]
    } else {
      Timber.e("Unknown connId $connId")
      null
    }
  }

  @Synchronized
  override fun addConnection(bluetoothGatt: BluetoothGatt?): Int {
    var connIndex = 0
    while (connIndex < connections.size) {
      if (connections[connIndex] == null) {
        connections[connIndex] = bluetoothGatt
        return connIndex + 1
      }
      connIndex++
    }
    connections.add(connIndex, bluetoothGatt)
    return connIndex + 1
  }

  @Synchronized
  override fun removeConnection(connId: Int): BluetoothGatt? {
    val connIndex = connId - 1
    return if (connIndex >= 0 && connIndex < connections.size) {
      // Set to null, rather than remove, so that other indexes are unchanged.
      connections.set(connIndex, null)
    } else {
      Timber.e("Trying to remove unknown connId $connId")
      null
    }
  }

  @Synchronized
  override fun getConnection(connId: Int): BluetoothGatt? {
    val connIndex = connId - 1
    return if (connIndex >= 0 && connIndex < connections.size) {
      connections[connIndex]
    } else {
      Timber.e("Unknown connId $connId")
      null
    }
  }

  override fun setBleCallback(bleCallback: BleCallback?) {
    this.bleCallback = bleCallback
  }

  override fun getCallback(): BluetoothGattCallback {
    return this.bluetoothGattCallback
  }

  override fun setAndroidChipPlatform(androidChipPlatform: AndroidChipPlatform?) {
    this.androidChipPlatform = androidChipPlatform
  }

  override fun init(): Int {
    Timber.d("init()")
    if (isEnabled) {
      try {
        this.bluetoothManager =
          context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        setupGattServer()
      } catch (e: RuntimeException) {
        Timber.e("get bluetoothManager exception", e)
      }
    } else {
      Timber.e("No action")
    }

    return 0
  }

  private fun setupGattServer() {
    Timber.i("setupGattServer()")

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (
        ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
          PackageManager.PERMISSION_GRANTED
      ) {
        Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
        return
      }
    }

    this.bluetoothManager?.adapter?.name = "Matter Device"
    this.bluetoothGattServer =
      this.bluetoothManager?.openGattServer(context, bluetoothGattServerCallback)

    val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
    val char1 =
      BluetoothGattCharacteristic(
        CHAR_1_UUID,
        BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
        BluetoothGattCharacteristic.PERMISSION_WRITE
      )
    service.addCharacteristic(char1)
    val char2 =
      BluetoothGattCharacteristic(
        CHAR_2_UUID,
        BluetoothGattCharacteristic.PROPERTY_INDICATE,
        BluetoothGattCharacteristic.PERMISSION_READ
      )
    val desc =
      BluetoothGattDescriptor(
        CLIENT_CHARACTERISTIC_UUID,
        BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
      )
    char2.addDescriptor(desc)
    service.addCharacteristic(char2)
    // TODO optional
    val char3 =
      BluetoothGattCharacteristic(
        CHAR_3_UUID,
        BluetoothGattCharacteristic.PROPERTY_READ,
        BluetoothGattCharacteristic.PERMISSION_READ
      )
    service.addCharacteristic(char3)
    this.bluetoothGattServer?.addService(service)
  }

  private fun startAdvertising(isFastMode: Boolean) {
    Timber.i("startAdvertising isFastMode $isFastMode")
    if (isEnabled) {
      val bluetoothLeAdvertiser: BluetoothLeAdvertiser? =
        this.bluetoothManager?.adapter?.bluetoothLeAdvertiser
      bluetoothLeAdvertiser?.let { advertiser ->
        //            val advertiseMode = if (isFastMode) {
        //                AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY
        //            } else {
        //                AdvertiseSettings.ADVERTISE_MODE_LOW_POWER
        //            }
        val advertiseSettings =
          AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            // .setAdvertiseMode(advertiseMode)
            .setTimeout(0)
            .build()

        val pUuid = ParcelUuid(SERVICE_UUID)

        Timber.e("Advertise uuid:${pUuid}")
        val advertiseData =
          AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(pUuid)
            .addServiceData(pUuid, makeAdvertiseServiceData())
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          if (
            ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_ADVERTISE) !=
              PackageManager.PERMISSION_GRANTED
          ) {
            Timber.e("Need Manifest.permission.BLUETOOTH_ADVERTISE")
            return
          }
        }

        advertiser.startAdvertising(advertiseSettings, advertiseData, advertiseCallback)
      }
    } else {
      Timber.e("No action")
    }
  }

  private fun stopAdvertising() {
    Timber.i("stopAdvertising()")
    if (isEnabled) {
      val bluetoothLeAdvertiser: BluetoothLeAdvertiser? =
        this.bluetoothManager?.adapter?.bluetoothLeAdvertiser

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        if (
          ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_ADVERTISE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
          Timber.e("Need Manifest.permission.BLUETOOTH_ADVERTISE")
          return
        }
      }

      bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
    } else {
      Timber.e("No action")
    }
  }

  private fun makeAdvertiseServiceData(): ByteArray {
    // 5.4.2.5.6. Advertising Data
    // Android sets 0-6 bytes.
    val data = ByteArray(8)
    data[0] = 0x00.toByte() // Matter BLE OpCode == 0x00 (Commissionable)
    // Values 0x01 - 0xFF are reserved

    this.androidChipPlatform?.let {
      val version = 0
      val discriminator: Int = it.discriminator

      val vd = ((version and 0xF) shl 12) or (discriminator and 0xFFF)
      data[1] = (vd and 0xFF).toByte() // Bits[11:0] == 12-bit Discriminator
      data[2] = ((vd shr 8) and 0xFF).toByte() // Bits[15:12] == 0x0 (Advertisement version)

      val vendorId: Int = it.vendorId
      data[3] =
        (vendorId and 0xFF).toByte() // 16-bit Vendor ID (see Section 5.4.2.4.2, “Vendor ID”)
      data[4] = ((vendorId shr 8) and 0xFF).toByte() // Set to 0, if elided

      val productId: Int = it.productId
      data[5] =
        (productId and 0xFF).toByte() // 16-bit Product ID (see Section 5.4.2.4.3, “Product ID”)
      data[6] = ((productId shr 8) and 0xFF).toByte() // Set to 0, if elided
      data[7] =
        0x00
          .toByte() // Bit[0] == Additional Data Flag (see Section 5.4.2.5.7, “GATT-based Additional
      // Data”)
      // Bits[7:1] are reserved for future use and SHALL be clear (set to 0)
    }
      ?: Timber.e("AndroidChipPlatform is null")

    return data
  }

  override fun setFlag(flag: Long, isSet: Boolean): Long {
    if (isSet) {
      return setFlag(flag)
    }
    return unsetFlag(flag)
  }

  private fun setFlag(flag: Long): Long {
    val lastFlag: Long = this.flag
    this.flag = this.flag or flag
    Timber.d(
      "Set " +
        convertFlagToString(flag) +
        " 0x" +
        convertLongToHexString(flag) +
        " on mFlag 0x" +
        convertLongToHexString(this.flag)
    )

    if (lastFlag == this.flag) {
      Timber.e("this.flag is not changed")
      return this.flag
    }

    if (flag == BleManager.kAdvertisingEnabled) {
      val isFastMode = (this.flag and BleManager.kFastAdvertisingEnabled) != 0L
      startAdvertising(isFastMode)
    }

    return this.flag
  }

  private fun unsetFlag(flag: Long): Long {
    val lastFlag: Long = this.flag
    this.flag = (this.flag and flag.inv())
    Timber.d(
      "Unset " +
        convertFlagToString(flag) +
        " 0x" +
        convertLongToHexString(flag) +
        " on mFlag 0x" +
        convertLongToHexString(this.flag)
    )
    if (lastFlag == this.flag) {
      Timber.e("this.flag is not changed")
      return this.flag
    }

    if (flag == BleManager.kAdvertisingEnabled) {
      stopAdvertising()
    }

    return this.flag
  }

  override fun hasFlag(flag: Long): Boolean {
    val has = (this.flag and flag) != 0L
    val hasStr =
      if (has) {
        " has "
      } else {
        " has not "
      }

    Timber.d(
      "this.flag 0x" + convertLongToHexString(this.flag) + hasStr + convertFlagToString(flag)
    )

    return has
  }

  private fun convertFlagToString(flag: Long): String {
    return when (flag) {
      BleManager.kAsyncInitCompleted -> {
        "kAsyncInitCompleted"
      }
      BleManager.kBluezBLELayerInitialized -> {
        "kBluezBLELayerInitialized"
      }
      BleManager.kAppRegistered -> {
        "kAppRegistered"
      }
      BleManager.kAdvertisingConfigured -> {
        "kAdvertisingConfigured"
      }
      BleManager.kAdvertising -> {
        "kAdvertising"
      }
      BleManager.kControlOpInProgress -> {
        "kControlOpInProgress"
      }
      BleManager.kAdvertisingEnabled -> {
        "kAdvertisingEnabled"
      }
      BleManager.kFastAdvertisingEnabled -> {
        "kFastAdvertisingEnabled"
      }
      BleManager.kUseCustomDeviceName -> {
        "kUseCustomDeviceName"
      }
      BleManager.kAdvertisingRefreshNeeded -> {
        "kAdvertisingRefreshNeeded"
      }
      BleManager.kServiceModeEnabled -> {
        "kServiceModeEnabled"
      }
      else -> {
        "Unknown ($flag)"
      }
    }
  }

  private fun convertLongToHexString(l: Long): String {
    return String.format("%04X", l)
  }

  override fun onSubscribeCharacteristic(
    connId: Int,
    svcId: ByteArray?,
    charId: ByteArray?
  ): Boolean {
    val bluetoothGatt = getConnection(connId)
    if (bluetoothGatt == null) {
      Timber.i("Tried to send characteristic, but BLE connection was not found.")
      return false
    }

    val svcUUID: UUID = convertBytesToUUID(svcId!!)
    val subscribeSvc = bluetoothGatt.getService(svcUUID)
    if (subscribeSvc == null) {
      Timber.e("Bad service")
      return false
    }

    val charUUID: UUID = convertBytesToUUID(charId!!)
    val subscribeChar = subscribeSvc.getCharacteristic(charUUID)
    if (subscribeChar == null) {
      Timber.e("Bad characteristic")
      return false
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (
        ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
          PackageManager.PERMISSION_GRANTED
      ) {
        Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
        return false
      }
    }

    if (!bluetoothGatt.setCharacteristicNotification(subscribeChar, true)) {
      Timber.e("Failed to subscribe to characteristic.")
      return false
    }

    val descriptor = subscribeChar.getDescriptor(CLIENT_CHARACTERISTIC_UUID)
    if ((subscribeChar.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0) {
      Timber.d("Enable INDICATION")
      descriptor.value = BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
      if (!bluetoothGatt.writeDescriptor(descriptor)) {
        Timber.e("writeDescriptor failed")
        return false
      }
    } else if ((subscribeChar.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY) != 0) {
      Timber.d("Enable NOTIFICATION")
      descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
      if (!bluetoothGatt.writeDescriptor(descriptor)) {
        Timber.e("writeDescriptor failed")
        return false
      }
    }

    return true
  }

  override fun onUnsubscribeCharacteristic(
    connId: Int,
    svcId: ByteArray?,
    charId: ByteArray?
  ): Boolean {
    val bluetoothGatt = getConnection(connId)
    if (bluetoothGatt == null) {
      Timber.i("Tried to unsubscribe characteristic, but BLE connection was not found.")
      return false
    }

    val svcUUID: UUID = convertBytesToUUID(svcId!!)
    val subscribeSvc = bluetoothGatt.getService(svcUUID)
    if (subscribeSvc == null) {
      Timber.e("Bad service")
      return false
    }

    val charUUID: UUID = convertBytesToUUID(charId!!)
    val subscribeChar = subscribeSvc.getCharacteristic(charUUID)
    if (subscribeChar == null) {
      Timber.e("Bad characteristic")
      return false
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (
        ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
          PackageManager.PERMISSION_GRANTED
      ) {
        Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
        return false
      }
    }

    if (!bluetoothGatt.setCharacteristicNotification(subscribeChar, false)) {
      Timber.e("Failed to unsubscribe to characteristic.")
      return false
    }

    val descriptor = subscribeChar.getDescriptor(CLIENT_CHARACTERISTIC_UUID)
    descriptor.value = BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
    if (!bluetoothGatt.writeDescriptor(descriptor)) {
      Timber.e("writeDescriptor failed")
      return false
    }

    return true
  }

  override fun onCloseConnection(connId: Int): Boolean {
    val device = getSubscribedDevice(connId)
    if (device == null) {
      Timber.i("Tried to close BLE connection, but connection was not found.")
      return true
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (
        ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
          PackageManager.PERMISSION_GRANTED
      ) {
        Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
        return false
      }
    }

    this.bluetoothGattServer?.cancelConnection(device)
    Timber.i("onCloseConnection:deactivate BT")
    this.bluetoothManager?.getAdapter()?.disable()
    // Do not activate BT as the actual Matter device also closes the BLE after commissioning is
    // complete
    // this.bluetoothManager?.getAdapter()?.enable()

    unsubscribeDevice(connId)
    this.bleCallback?.onCloseBleComplete(connId)

    return true
  }

  override fun onGetMTU(connId: Int): Int {
    Timber.d("Android Manufacturer: (" + Build.MANUFACTURER.toString() + ")")
    Timber.d("Android Model: (" + Build.MODEL.toString() + ")")

    return 0
  }

  override fun onSendIndication(
    connId: Int,
    svcId: ByteArray?,
    charId: ByteArray?,
    characteristicData: ByteArray?
  ): Boolean {
    val device = getSubscribedDevice(connId)
    if (device == null) {
      Timber.e("Tried to notify characteristic, but BLE connection was not found.")
      return false
    }

    val svcUUID: UUID = convertBytesToUUID(svcId!!)
    val notifySvc: BluetoothGattService? = this.bluetoothGattServer?.getService(svcUUID)
    if (notifySvc == null) {
      Timber.e("Bad service")
      return false
    }

    val charUUID: UUID = convertBytesToUUID(charId!!)
    val notifyChar = notifySvc.getCharacteristic(charUUID)
    if (!notifyChar.setValue(characteristicData)) {
      Timber.e("Failed to notify characteristic")
      return false
    }

    notifyChar.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (
        ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
          PackageManager.PERMISSION_GRANTED
      ) {
        Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
        return false
      }
    }

    if (this.bluetoothGattServer?.notifyCharacteristicChanged(device, notifyChar, false) == false) {
      Timber.e("Failed notifying char")
      return false
    }

    this.notifyingService = notifySvc
    this.notifyingCharacteristic = notifyChar
    return true
  }

  override fun onSendWriteRequest(
    connId: Int,
    svcId: ByteArray?,
    charId: ByteArray?,
    characteristicData: ByteArray?
  ): Boolean {
    val bluetoothGatt = getConnection(connId)
    if (bluetoothGatt == null) {
      Timber.i("Tried to send characteristic, but BLE connection was not found.")
      return false
    }

    val svcUUID: UUID = convertBytesToUUID(svcId!!)
    val sendSvc = bluetoothGatt.getService(svcUUID)
    if (sendSvc == null) {
      Timber.e("Bad service")
      return false
    }

    val charUUID: UUID = convertBytesToUUID(charId!!)
    val sendChar = sendSvc.getCharacteristic(charUUID)
    if (!sendChar.setValue(characteristicData)) {
      Timber.e("Failed to set characteristic")
      return false
    }

    // Request acknowledgement (use ATT Write Request).
    sendChar.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (
        ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
          PackageManager.PERMISSION_GRANTED
      ) {
        Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
        return false
      }
    }

    if (!bluetoothGatt.writeCharacteristic(sendChar)) {
      Timber.e("Failed writing char")
      return false
    }
    return true
  }

  override fun onNotifyChipConnectionClosed(connId: Int) {
    val device = getSubscribedDevice(connId)
    if (device == null) {
      Timber.i("Tried to close BLE connection, but connection was not found.")
      return
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (
        ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) !=
          PackageManager.PERMISSION_GRANTED
      ) {
        Timber.e("Need Manifest.permission.BLUETOOTH_CONNECT")
        return
      }
    }

    this.bluetoothGattServer?.cancelConnection(device)
    this.bluetoothGattServer?.close() // Close the BTGattServer as connection is closed
    this.bluetoothGattServer = null
    Timber.i("onNotifyChipConnectionClosed:deactivate BT")
    this.bluetoothManager?.getAdapter()?.disable()
    // do not activate BT as connection is closed
    // this.bluetoothManager?.getAdapter()?.enable()

    unsubscribeDevice(connId)
    this.bleCallback?.onNotifyChipConnectionClosed(connId)
  }

  override fun onNewConnection(discriminator: Int) {}

  private fun convertUUIDToBytes(uuid: UUID): ByteArray {
    val idBytes = ByteArray(16)
    var idBits: Long
    idBits = uuid.leastSignificantBits
    for (i in 0..7) {
      idBytes[15 - i] = (idBits and 0xff).toByte()
      idBits = idBits shr 8
    }
    idBits = uuid.mostSignificantBits
    for (i in 0..7) {
      idBytes[7 - i] = (idBits and 0xff).toByte()
      idBits = idBits shr 8
    }
    return idBytes
  }

  private fun convertBytesToUUID(id: ByteArray): UUID {
    var mostSigBits: Long = 0
    var leastSigBits: Long = 0
    if (id.size == 16) {
      for (i in 0..7) {
        mostSigBits = (mostSigBits shl 8) or ((0xff and id[i].toInt()).toLong())
      }
      for (i in 0..7) {
        leastSigBits = (leastSigBits shl 8) or ((0xff and id[i + 8].toInt()).toLong())
      }
    }
    return UUID(mostSigBits, leastSigBits)
  }

  private fun convertByteToHex(num: Byte): String {
    val hexDigits = CharArray(2)
    hexDigits[0] = Character.forDigit(((num.toInt() shr 4) and 0xF), 16)
    hexDigits[1] = Character.forDigit((num.toInt() and 0xF), 16)
    return String(hexDigits)
  }

  private fun convertBytesToHexString(byteArray: ByteArray): String {
    val hexStringBuffer = StringBuffer()
    for (i in byteArray.indices) {
      hexStringBuffer.append(convertByteToHex(byteArray[i]))
    }
    return hexStringBuffer.toString()
  }

  private fun convertBluetoothGattDescriptorValueToString(value: ByteArray): String {
    return if (Arrays.equals(value, BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE)) {
      "DISABLE_NOTIFICATION_VALUE"
    } else if (Arrays.equals(value, BluetoothGattDescriptor.ENABLE_INDICATION_VALUE)) {
      "ENABLE_INDICATION_VALUE"
    } else if (Arrays.equals(value, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) {
      "ENABLE_NOTIFICATION_VALUE"
    } else {
      "Unknown"
    }
  }

  companion object {
    private val SERVICE_UUID: UUID = UUID.fromString("0000FFF6-0000-1000-8000-00805F9B34FB")
    private val CHAR_1_UUID: UUID = UUID.fromString("18EE2EF5-263D-4559-959F-4F9C429F9D11")
    private val CHAR_2_UUID: UUID = UUID.fromString("18EE2EF5-263D-4559-959F-4F9C429F9D12")

    // TODO optional
    private val CHAR_3_UUID: UUID = UUID.fromString("64630238-8772-45F2-B87D-748A83218F04")

    // CLIENT_CHARACTERISTIC_CONFIG is the well-known UUID of the client characteristic descriptor
    // that has the flags for enabling and disabling notifications and indications.
    // c.f. https://www.bluetooth.org/en-us/specification/assigned-numbers/generic-attribute-profile
    private const val CLIENT_CHARACTERISTIC_CONFIG = "00002902-0000-1000-8000-00805f9b34fb"
    private val CLIENT_CHARACTERISTIC_UUID: UUID = UUID.fromString(CLIENT_CHARACTERISTIC_CONFIG)
    private const val INITIAL_CONNECTIONS = 4
  }
}
