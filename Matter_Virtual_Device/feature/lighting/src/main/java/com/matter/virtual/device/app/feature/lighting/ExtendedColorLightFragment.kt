package com.matter.virtual.device.app.feature.lighting

import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.navArgs
import com.matter.virtual.device.app.core.common.util.ColorControlUtil
import com.matter.virtual.device.app.core.model.databinding.ButtonData
import com.matter.virtual.device.app.core.ui.BaseFragment
import com.matter.virtual.device.app.core.ui.databinding.LayoutAppbarBinding
import com.matter.virtual.device.app.feature.lighting.databinding.FragmentExtendedColorLightBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import timber.log.Timber

@AndroidEntryPoint
class ExtendedColorLightFragment :
  BaseFragment<FragmentExtendedColorLightBinding, ExtendedColorLightViewModel>(
    R.layout.fragment_extended_color_light
  ) {

  override val viewModel: ExtendedColorLightViewModel by viewModels()

  @OptIn(ExperimentalSerializationApi::class)
  override fun setupNavArgs() {
    val args: ExtendedColorLightFragmentArgs by navArgs()
    matterSettings = Json.decodeFromString(args.setting)
  }

  override fun setupAppbar(): LayoutAppbarBinding = binding.appbar

  override fun setupUi() {
    binding.viewModel = viewModel
    binding.extendedColorLightColorLayout.colorBoard.setImageDrawable(
      BitmapDrawable(resources, ColorControlUtil.colorBoard(Color.WHITE))
    )

    /** title text */
    binding.appbar.toolbarTitle.text = getString(R.string.matter_extended_color_light)

    /** OnOff layout */
    // ===================================================================================
    // [CODELAB] Observe cluster value : ExtendedColorLight
    // [ButtonData] Observer on the current on/off status and react on the fragment's UI.
    // [OnClickListener] Trigger the processing for updating new on/off state of the virtual device.
    // -----------------------------------------------------------------------------------
    binding.extendedColorLightOnOffLayout.buttonData =
      ButtonData(
        onOff = viewModel.onOff,
        onText = R.string.on_off_switch_power_on,
        offText = R.string.on_off_switch_power_off
      )
    binding.extendedColorLightOnOffLayout.button.setOnClickListener { viewModel.onClickButton() }
    // ===================================================================================

    /** Color layout */
    binding.extendedColorLightColorLayout.titleText.text =
      getString(R.string.extended_color_light_color)
    binding.extendedColorLightColorLayout.titleText.textSize = 20f
  }

  override fun setupObservers() {
    // ===================================================================================
    // [CODELAB] Observe cluster value : ExtendedColorLight
    // Observer on the current color level status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.level.observe(viewLifecycleOwner) {
      // Min: 2(1%), Max: 255(100%)
      val level: Int = (it.toFloat() / 100 * 255).toInt()
      Timber.d("Level: $it")

      // If level value is 0, user can't distinguish the color.
      // So, set it to half value + half of Max.
      binding.extendedColorLightColorLayout.colorBoard.drawable?.alpha = level / 2 + 127
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : ExtendedColorLight
    // Observer on the current color status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.currentColor.observe(viewLifecycleOwner) { hsvColor ->
      val rgbColor: Int =
        ColorControlUtil.hue2rgb(
          hsvColor.currentHue.toFloat(),
          hsvColor.currentSaturation.toFloat()
        )

      Timber.d("currentHue:${hsvColor.currentHue},currentSaturation:${hsvColor.currentSaturation}")
      Timber.d("Color: #${Integer.toHexString(rgbColor)}")

      var level: Int? = binding.extendedColorLightColorLayout.colorBoard.drawable?.alpha
      if (level == null) level = 255
      Timber.d("level: $level")

      binding.extendedColorLightColorLayout.colorBoard.setImageDrawable(
        BitmapDrawable(resources, ColorControlUtil.colorBoard(rgbColor))
      )
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : ExtendedColorLight
    // Observer on the current color temperature status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.colorTemperature.observe(viewLifecycleOwner) {
      // Min: 2580k(2577k), Max: 7050k(7042k)
      val colorTemperature: Int = 1000000 / it
      val rgbColor: Int = ColorControlUtil.kelvin2rgb(colorTemperature)

      Timber.d("Color Temperature: $colorTemperature $it")
      Timber.d("Color: #${Integer.toHexString(rgbColor)}")

      binding.extendedColorLightColorLayout.colorBoard.setImageDrawable(
        BitmapDrawable(resources, ColorControlUtil.colorBoard(rgbColor))
      )
    }
    // ===================================================================================
  }

  override fun onResume() {
    Timber.d("Hit")
    super.onResume()
  }

  override fun onDestroy() {
    Timber.d("Hit")
    super.onDestroy()
  }
}
