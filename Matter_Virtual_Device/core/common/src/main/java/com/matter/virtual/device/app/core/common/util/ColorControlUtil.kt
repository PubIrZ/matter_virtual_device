package com.matter.virtual.device.app.core.common.util

import android.graphics.*
import kotlin.math.ln
import kotlin.math.pow
import kotlin.math.roundToInt
import timber.log.Timber

object ColorControlUtil {

  fun colorBoard(rgbColor: Int): Bitmap {
    val bitmap = Bitmap.createBitmap(400, 400, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val pnt = Paint()

    pnt.shader = RadialGradient(200f, 200f, 600f, rgbColor, Color.WHITE, Shader.TileMode.CLAMP)
    canvas.drawCircle(200f, 200f, 200f, pnt)

    return bitmap
  }

  fun hue2rgb(hue: Float?, saturation: Float?): Int {
    val h = hue?.div(254f) ?: 0f
    val s = saturation?.div(254f) ?: 0f

    if (s <= 0) {
      return Color.argb(255, 255, 255, 255)
    }

    val region = (h * 6).toInt()
    var remainder = h * 6f - region

    // There's no this process in Edge driver.
    // But if hue value is Max(254), calculated RGB value is incorrect.
    if (h == 1f) remainder += 1f

    val p = 1 - s
    val q = 1 - s * remainder
    val t = 1 - s * (1 - remainder)

    return when (region) {
      0 -> Color.argb(255, 255, (t * 255).roundToInt(), (p * 255).roundToInt())
      1 -> Color.argb(255, (q * 255).roundToInt(), 255, (p * 255).roundToInt())
      2 -> Color.argb(255, (p * 255).roundToInt(), 255, (t * 255).roundToInt())
      3 -> Color.argb(255, (p * 255).roundToInt(), (q * 255).roundToInt(), 255)
      4 -> Color.argb(255, (t * 255).roundToInt(), (p * 255).roundToInt(), 255)
      else -> Color.argb(255, 255, (p * 255).roundToInt(), (q * 255).roundToInt())
    }
  }

  fun kelvin2rgb(temp: Int): Int {
    if (temp < 0) return Color.RED

    var red = 0f
    var green = 0f
    var blue = 0f

    // Red
    red = if (temp < 6600) 255f else 329.69873f * (temp.toFloat() / 100 - 60).pow(-0.13332048f)

    // Green
    green =
      if (temp < 6600) 99.4708f * ln(temp.toFloat() / 100) - 161.11957f
      else 288.12216f * (temp.toFloat() / 100 - 60).pow(-0.075514846f)

    // Blue
    blue =
      if (temp < 2000) 0f
      else if (temp > 6500) 255f else 138.51776f * ln(temp.toFloat() / 100 - 10) - 305.0448f

    Timber.i("temp: $temp, red: $red, green: $green, blue: $blue")

    return Color.argb(255, red.toInt(), green.toInt(), blue.toInt())
  }
}
