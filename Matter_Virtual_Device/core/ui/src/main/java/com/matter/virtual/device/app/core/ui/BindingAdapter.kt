package com.matter.virtual.device.app.core.ui

import android.graphics.drawable.Drawable
import androidx.annotation.DrawableRes
import androidx.appcompat.widget.AppCompatImageView
import androidx.databinding.BindingAdapter

object BindingAdapter {
  @BindingAdapter("imageSrc")
  @JvmStatic
  fun AppCompatImageView.bindImageSrc(@DrawableRes imgResId: Int) {
    this.setImageResource(imgResId)
  }

  @BindingAdapter("imageSrc")
  @JvmStatic
  fun AppCompatImageView.bindImageSrc(drawable: Drawable) {
    this.setImageDrawable(drawable)
  }
}
