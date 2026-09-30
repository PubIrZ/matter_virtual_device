package com.matter.virtual.device.app.core.model.matter

enum class ThermostatSystemMode(val value: Int) {
  OFF(0),
  AUTO(1),
  COOL(3),
  HEAT(4),
  EMERGENCY_HEATING(5),
  PRECOOLING(6),
  FAN_ONLY(7)
}
