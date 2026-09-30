package com.matter.virtual.device.app.core.common

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import kotlinx.serialization.Serializable

@Serializable
sealed class Device(
  val title: String,
  @StringRes val deviceNameResId: Int,
  @DrawableRes val deviceIconResId: Int,
  val deviceTypeId: Long,
  val discriminator: Int
) {
  @Serializable
  object OnOffSwitch :
    Device(
      "onoffswitch",
      R.string.matter_on_off_switch,
      R.drawable.round_toggle_on_24,
      0x0103,
      2048
    )

  @Serializable
  object DoorLock :
    Device("doorlock", R.string.matter_door_lock, R.drawable.round_lock_24, 0x000A, 2304)

  @Serializable
  object WindowCovering :
    Device(
      "windowcovering",
      R.string.matter_window_covering,
      R.drawable.round_blinds_24,
      0x0202,
      2560
    )

  @Serializable
  object Thermostat :
    Device("thermostat", R.string.matter_thermostat, R.drawable.round_thermostat_24, 0x0301, 2816)

  @Serializable
  object VideoPlayer :
    Device("videoplayer", R.string.matter_basic_video_player, R.drawable.round_tv_24, 0x0028, 3072)

  @Serializable
  object ExtendedColorLight :
    Device(
      "extendedcolorlight",
      R.string.matter_extended_color_light,
      R.drawable.round_lightbulb_24,
      0x010D,
      3328
    )

  @Serializable
  object OccupancySensor :
    Device(
      "occupancysensor",
      R.string.matter_occupancy_sensor,
      R.drawable.round_sensors_24,
      0x0107,
      3584
    )

  @Serializable
  object ContactSensor :
    Device(
      "contactsensor",
      R.string.matter_contact_sensor,
      R.drawable.round_sensors_24,
      0x0015,
      3840
    )

  @Serializable
  object Unknown :
    Device("unknown", R.string.matter_device, R.drawable.round_device_unknown_24, 65535, 256)

  companion object {
    fun map(title: String): Device {
      return Device::class
        .sealedSubclasses
        .firstOrNull { it.objectInstance?.title == title }
        ?.objectInstance
        ?: Unknown
    }
  }
}
