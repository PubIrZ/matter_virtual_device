package com.matter.virtual.device.app.feature.sensor

import android.text.Html
import android.widget.SeekBar
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.navArgs
import com.matter.virtual.device.app.core.model.databinding.SeekbarData
import com.matter.virtual.device.app.core.ui.BaseFragment
import com.matter.virtual.device.app.core.ui.databinding.LayoutAppbarBinding
import com.matter.virtual.device.app.feature.sensor.databinding.FragmentOccupancySensorBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import timber.log.Timber

@AndroidEntryPoint
class OccupancySensorFragment :
  BaseFragment<FragmentOccupancySensorBinding, OccupancySensorViewModel>(
    R.layout.fragment_occupancy_sensor
  ) {

  override val viewModel: OccupancySensorViewModel by viewModels()

  @OptIn(ExperimentalSerializationApi::class)
  override fun setupNavArgs() {
    val args: OccupancySensorFragmentArgs by navArgs()
    matterSettings = Json.decodeFromString(args.setting)
  }

  override fun setupAppbar(): LayoutAppbarBinding = binding.appbar

  override fun setupUi() {
    /** title text */
    binding.appbar.toolbarTitle.text = getString(R.string.matter_occupancy_sensor)

    /** Occupancy layout */
    // ===================================================================================
    // [CODELAB] Observe cluster value : OccupancySensor
    // Trigger the processing for updating new occupancy state of the virtual device.
    // -----------------------------------------------------------------------------------
    binding.occupancyButton.setOnClickListener { viewModel.onClickButton() }
    // ===================================================================================

    /** Battery layout */
    // ===================================================================================
    // [CODELAB] Observe cluster value : OccupancySensor
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new battery state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    binding.occupancySensorBatteryLayout.titleText.text = getString(R.string.battery)
    binding.occupancySensorBatteryLayout.seekbarData =
      SeekbarData(progress = viewModel.batteryStatus)
    binding.occupancySensorBatteryLayout.seekbar.setOnSeekBarChangeListener(
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
    // ===================================================================================
  }

  override fun setupObservers() {
    // ===================================================================================
    // [CODELAB] Observe cluster value : OccupancySensor
    // Observer on the current occupancy status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.occupancy.observe(viewLifecycleOwner) {
      if (it) {
        binding.occupancyValueText.text = getString(R.string.occupancy_state_occupied)
        binding.occupancyButton.setImageResource(R.drawable.ic_occupied)
      } else {
        binding.occupancyValueText.text = getString(R.string.occupancy_state_unoccupied)
        binding.occupancyButton.setImageResource(R.drawable.ic_unoccupied)
      }
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : OccupancySensor
    // Observer on the current battery status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.batteryStatus.observe(viewLifecycleOwner) {
      val text: String = getString(R.string.battery_format, it)
      binding.occupancySensorBatteryLayout.valueText.text =
        Html.fromHtml(text, Html.FROM_HTML_MODE_LEGACY)
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
