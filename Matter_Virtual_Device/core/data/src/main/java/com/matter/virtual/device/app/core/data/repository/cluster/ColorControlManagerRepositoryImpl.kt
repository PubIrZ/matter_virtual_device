package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.ColorControlManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class ColorControlManagerRepositoryImpl
@Inject
constructor(private val colorControlManagerStub: ColorControlManagerStub) :
  ColorControlManagerRepository {

  override fun getEnhancedColorModeFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return colorControlManagerStub.enhancedColorMode
  }

  override fun getColorModeFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return colorControlManagerStub.colorMode
  }

  override fun getCurrentHueFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return colorControlManagerStub.currentHue
  }

  override fun getCurrentSaturationFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return colorControlManagerStub.currentSaturation
  }

  override fun getColorTemperatureFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return colorControlManagerStub.colorTemperature
  }
}
