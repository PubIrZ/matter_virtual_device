package com.matter.virtual.device.app.feature.closure

import android.text.Html
import android.widget.SeekBar
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.navArgs
import com.matter.virtual.device.app.core.model.databinding.SeekbarData
import com.matter.virtual.device.app.core.ui.BaseFragment
import com.matter.virtual.device.app.core.ui.databinding.LayoutAppbarBinding
import com.matter.virtual.device.app.feature.closure.databinding.FragmentWindowCoveringBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import timber.log.Timber

@AndroidEntryPoint
class WindowCoveringFragment :
  BaseFragment<FragmentWindowCoveringBinding, WindowCoveringViewModel>(
    R.layout.fragment_window_covering
  ) {

  override val viewModel: WindowCoveringViewModel by viewModels()

  @OptIn(ExperimentalSerializationApi::class)
  override fun setupNavArgs() {
    val args: WindowCoveringFragmentArgs by navArgs()
    matterSettings = Json.decodeFromString(args.setting)
  }

  override fun setupAppbar(): LayoutAppbarBinding = binding.appbar

  override fun setupUi() {

    binding.viewModel = viewModel
    /** title text */
    binding.appbar.toolbarTitle.text = getString(R.string.matter_window_covering)

    /** Window shade layout */
    // ===================================================================================
    // CODELAB Level 4
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new WindowShade state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    
    // TODO 1: Paste or write code below

    // =======================================================================================================

    /** Battery layout */
    // ===================================================================================
    // CODELAB Level 4
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new battery state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    
    // TODO 2: Paste or write code below

    // =======================================================================================================
  }

  override fun setupObservers() {
    // ===================================================================================
    // CODELAB Level 4
    // Observer on the current position/operation status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 3: Paste or write code below

    // =======================================================================================================

    // ===================================================================================
    // CODELAB Level 4
    // Observer on the current battery status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 4: Paste or write code below
    
    // =======================================================================================================
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
