package com.matter.virtual.device.app.feature.sensor

import android.text.Html
import android.widget.SeekBar
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.navArgs
import com.matter.virtual.device.app.core.model.databinding.SeekbarData
import com.matter.virtual.device.app.core.ui.BaseFragment
import com.matter.virtual.device.app.core.ui.databinding.LayoutAppbarBinding
import com.matter.virtual.device.app.feature.sensor.databinding.FragmentContactSensorBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import timber.log.Timber

@AndroidEntryPoint
class ContactSensorFragment :
  BaseFragment<FragmentContactSensorBinding, ContactSensorViewModel>(
    R.layout.fragment_contact_sensor
  ) {

  override val viewModel: ContactSensorViewModel by viewModels()

  @OptIn(ExperimentalSerializationApi::class)
  override fun setupNavArgs() {
    val args: ContactSensorFragmentArgs by navArgs()
    matterSettings = Json.decodeFromString(args.setting)
  }

  override fun setupAppbar(): LayoutAppbarBinding = binding.appbar

  override fun setupUi() {
    /** title text */
    binding.appbar.toolbarTitle.text = getString(R.string.matter_contact_sensor)

    /** Occupancy layout */
    // ===================================================================================
    // [CODELAB] Observe cluster value : ContactSensor
    // Trigger the processing for updating new contact state of the virtual device.
    // -----------------------------------------------------------------------------------
    binding.contactButton.setOnClickListener { viewModel.onClickButton() }
    // ===================================================================================

    /** Battery layout */
    // ===================================================================================
    // [CODELAB] Observe cluster value : ContactSensor
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new battery state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    binding.contactSensorBatteryLayout.titleText.text = getString(R.string.battery)
    binding.contactSensorBatteryLayout.seekbarData = SeekbarData(progress = viewModel.batteryStatus)
    binding.contactSensorBatteryLayout.seekbar.setOnSeekBarChangeListener(
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
    // [CODELAB] Observe cluster value : ContactSensor
    // Observer on the current contact status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.stateValue.observe(viewLifecycleOwner) {
      if (it) {
        binding.contactValueText.text = getString(R.string.contact_state_close)
        binding.contactButton.setImageResource(R.drawable.ic_unoccupied)
      } else {
        binding.contactValueText.text = getString(R.string.contact_state_open)
        binding.contactButton.setImageResource(R.drawable.ic_occupied)
      }
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : ContactSensor
    // Observer on the current battery status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.batteryStatus.observe(viewLifecycleOwner) {
      val text: String = getString(R.string.battery_format, it)
      binding.contactSensorBatteryLayout.valueText.text =
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
