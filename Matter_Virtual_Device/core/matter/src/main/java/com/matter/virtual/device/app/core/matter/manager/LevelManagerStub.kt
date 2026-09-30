package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.LevelManager
import com.matter.virtual.device.app.core.common.MatterConstants
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.roundToInt
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class LevelManagerStub @Inject constructor(private val deviceApp: DeviceApp) : LevelManager {

  private val _level = MutableStateFlow(0)
  val level: StateFlow<Int>
    get() = _level

  // This function is setting the value of current level from the app to the matter server
  fun setCurrentLevel(value: Int) {
    _level.value = value
    val valueToMatter = (value * 2.54).roundToInt()
    Timber.d("level current value to Matter $valueToMatter")
    deviceApp.setCurrentLevel(MatterConstants.DEFAULT_ENDPOINT, valueToMatter)
  }

  // This function setting the level from the matter sever to the app
  override fun handleLevelChanged(value: Int) {
    val valueForApp = (value / (2.54)).roundToInt()
    Timber.d("current level : $valueForApp")
    _level.value = valueForApp
  }
}
