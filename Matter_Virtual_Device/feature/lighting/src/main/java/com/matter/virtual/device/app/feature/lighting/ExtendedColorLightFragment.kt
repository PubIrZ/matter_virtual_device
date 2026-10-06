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
    // CODELAB Level 3
    // [ButtonData] Observer on the current on/off status and react on the fragment's UI.
    // [OnClickListener] Trigger the processing for updating new on/off state of the virtual device.
    // -----------------------------------------------------------------------------------
    
    // TODO 1: Paste or write code below

    // ===================================================================================

    /** Color layout */
    binding.extendedColorLightColorLayout.titleText.text =
      getString(R.string.extended_color_light_color)
    binding.extendedColorLightColorLayout.titleText.textSize = 20f
  }

  override fun setupObservers() {
    // ===================================================================================
    // CODELAB Level 3
    // Observer on the current color level status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 2: Paste or write code below

    // ===================================================================================

    // ===================================================================================
    // CODELAB Level 3
    // Observer on the current color status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 3: Paste or write code below

    // ===================================================================================

    // ===================================================================================
    // CODELAB Level 3
    // Observer on the current color temperature status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 4: Paste or write code below
    
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
