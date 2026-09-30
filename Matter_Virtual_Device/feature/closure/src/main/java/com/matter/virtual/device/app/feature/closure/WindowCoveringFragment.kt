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
    // [CODELAB] Observe cluster value : WindowCovering
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new WindowShade state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    binding.windowCoveringWindowShadeSeekbar.setOnSeekBarChangeListener(
      object : SeekBar.OnSeekBarChangeListener {
        override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
          val targetPercentage = seekBar.progress
          val text: String =
            getString(R.string.window_covering_window_shade_format, targetPercentage)
          val percentageTextView = binding.windowCoveringWindowShadeValueText
          percentageTextView.text = Html.fromHtml(text, Html.FROM_HTML_MODE_LEGACY)
        }

        override fun onStartTrackingTouch(seekBar: SeekBar) {}

        override fun onStopTrackingTouch(seekBar: SeekBar) {
          viewModel.stopMotion(seekBar.progress)
        }
      }
    )
    // =======================================================================================================

    /** Battery layout */
    // ===================================================================================
    // [CODELAB] Observe cluster value : WindowCovering
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new battery state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    binding.windowCoveringBatteryLayout.titleText.text = getString(R.string.battery)
    binding.windowCoveringBatteryLayout.seekbarData =
      SeekbarData(progress = viewModel.batteryStatus)
    binding.windowCoveringBatteryLayout.seekbar.setOnSeekBarChangeListener(
      object : SeekBar.OnSeekBarChangeListener {
        override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
          viewModel.updateBatterySeekbarProgress(progress)
        }

        override fun onStartTrackingTouch(seekBar: SeekBar) {}

        override fun onStopTrackingTouch(seekBar: SeekBar) {
          viewModel.updateBatteryStatusToCluster(seekBar.progress)
        }
      }
    )
    // =======================================================================================================
  }

  override fun setupObservers() {
    // ===================================================================================
    // [CODELAB] Observe cluster value : WindowCovering
    // Observer on the current position/operation status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.windowCoveringStatus.observe(viewLifecycleOwner) { status ->
      Timber.d(
        "currentPosition:${status.currentPosition},operationalStatus:${status.operationalStatus}"
      )
      binding.windowCoveringWindowShadeSeekbar.progress = status.currentPosition

      val text: String =
        getString(R.string.window_covering_window_shade_format, status.currentPosition)
      binding.windowCoveringWindowShadeValueText.text =
        Html.fromHtml(text, Html.FROM_HTML_MODE_LEGACY)

      when (status.operationalStatus) {
        0 -> {
          when (status.currentPosition) {
            0 -> {
              binding.windowCoveringOperationalStatusText.setText(R.string.window_covering_closed)
            }
            100 -> {
              binding.windowCoveringOperationalStatusText.setText(R.string.window_covering_open)
            }
            else -> {
              binding.windowCoveringOperationalStatusText.setText(
                R.string.window_covering_partially_open
              )
            }
          }
        }
        1 -> {
          binding.windowCoveringOperationalStatusText.setText(R.string.window_covering_opening)
        }
        2 -> {
          binding.windowCoveringOperationalStatusText.setText(R.string.window_covering_closing)
        }
        else -> {}
      }
    }
    // =======================================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : WindowCovering
    // Observer on the current battery status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.batteryStatus.observe(viewLifecycleOwner) {
      val text: String = getString(R.string.battery_format, it)
      binding.windowCoveringBatteryLayout.valueText.text =
        Html.fromHtml(text, Html.FROM_HTML_MODE_LEGACY)
    }
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
