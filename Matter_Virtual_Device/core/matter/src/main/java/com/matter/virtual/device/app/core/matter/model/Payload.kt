package com.matter.virtual.device.app.core.matter.model

import chip.setuppayload.DiscoveryCapability
import chip.setuppayload.SetupPayload
import com.matter.virtual.device.app.core.common.MatterConstants
import com.matter.virtual.device.app.core.model.matter.Payload
import timber.log.Timber

fun Payload.asSetupPayload(): SetupPayload {
  val discoveryCapabilities = HashSet<DiscoveryCapability>()
  when (this.onboardingType) {
    com.matter.virtual.device.app.core.model.matter.OnboardingType.WIFI ->
      discoveryCapabilities.add(DiscoveryCapability.ON_NETWORK)
    com.matter.virtual.device.app.core.model.matter.OnboardingType.BLE ->
      discoveryCapabilities.add(DiscoveryCapability.BLE)
    com.matter.virtual.device.app.core.model.matter.OnboardingType.WIFI_BLE -> {
      discoveryCapabilities.add(DiscoveryCapability.ON_NETWORK)
      discoveryCapabilities.add(DiscoveryCapability.BLE)
    }
    else -> {
      Timber.e("Unknown Type")
    }
  }

  return SetupPayload(
    MatterConstants.DEFAULT_VERSION,
    MatterConstants.DEFAULT_VENDOR_ID,
    MatterConstants.DEFAULT_PRODUCT_ID,
    MatterConstants.DEFAULT_COMMISSIONING_FLOW,
    discoveryCapabilities,
    discriminator,
    MatterConstants.DEFAULT_SETUP_PINCODE
  )
}
