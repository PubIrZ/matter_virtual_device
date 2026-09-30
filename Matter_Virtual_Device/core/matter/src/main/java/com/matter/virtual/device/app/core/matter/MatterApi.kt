package com.matter.virtual.device.app.core.matter

import chip.setuppayload.SetupPayloadParser
import chip.setuppayload.SetupPayloadParser.SetupPayloadException
import com.matter.virtual.device.app.core.matter.model.asSetupPayload
import com.matter.virtual.device.app.core.model.matter.Payload
import javax.inject.Inject
import javax.inject.Singleton
import timber.log.Timber

@Singleton
class MatterApi @Inject constructor() {

  fun getQrcodeString(payload: Payload): String {
    val setupPayloadParser = SetupPayloadParser()
    var qrcode = ""
    try {
      qrcode = setupPayloadParser.getQrCodeFromPayload(payload.asSetupPayload())
    } catch (e: SetupPayloadException) {
      e.printStackTrace()
    }

    Timber.d("qrcode:$qrcode")
    return qrcode
  }

  fun getManualPairingCodeString(payload: Payload): String {
    val setupPayloadParser = SetupPayloadParser()
    var manualPairingCode = ""
    try {
      manualPairingCode = setupPayloadParser.getManualEntryCodeFromPayload(payload.asSetupPayload())
    } catch (e: SetupPayloadException) {
      e.printStackTrace()
    }

    Timber.d("manualPairingCode:$manualPairingCode")
    return manualPairingCode
  }
}
