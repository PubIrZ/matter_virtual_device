package com.matter.virtual.device.app.feature.hvac

import android.text.Html
import android.widget.SeekBar
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.navArgs
import com.matter.virtual.device.app.core.model.databinding.SeekbarData
import com.matter.virtual.device.app.core.model.matter.FanControlFanMode
import com.matter.virtual.device.app.core.model.matter.ThermostatSystemMode
import com.matter.virtual.device.app.core.ui.BaseFragment
import com.matter.virtual.device.app.core.ui.databinding.LayoutAppbarBinding
import com.matter.virtual.device.app.feature.hvac.databinding.FragmentThermostatBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import timber.log.Timber

@AndroidEntryPoint
class ThermostatFragment :
  BaseFragment<FragmentThermostatBinding, ThermostatViewModel>(R.layout.fragment_thermostat) {

  override val viewModel: ThermostatViewModel by viewModels()

  private var systemMode: ThermostatSystemMode = ThermostatSystemMode.HEAT
  private var fanMode: FanControlFanMode = FanControlFanMode.OFF

  @OptIn(ExperimentalSerializationApi::class)
  override fun setupNavArgs() {
    val args: ThermostatFragmentArgs by navArgs()
    matterSettings = Json.decodeFromString(args.setting)
  }

  override fun setupAppbar(): LayoutAppbarBinding = binding.appbar

  override fun setupUi() {
    binding.viewModel = viewModel
    binding.fragment = this

    /** title text */
    binding.appbar.toolbarTitle.text = getString(R.string.matter_thermostat)

    /** System mode layout */
    binding.thermostatSystemModeLayout.titleText.text = getString(R.string.thermostat_mode)
    binding.thermostatSystemModeLayout.button.setImageResource(R.drawable.more_tab_settings)
    binding.thermostatSystemModeLayout.button.setOnClickListener { showSystemModePopup() }

    // ===================================================================================
    // CODELAB Level 5
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new temperature state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    
    // TODO 1: Paste or write code below

    // ===================================================================================

    /** Fan mode layout */
    binding.fanControlFanModeLayout.titleText.text = getString(R.string.fan_control_fan_mode)
    binding.fanControlFanModeLayout.button.setImageResource(R.drawable.more_tab_settings)
    binding.fanControlFanModeLayout.button.setOnClickListener { showFanModePopup() }

    /** Humidity Sensor layout */
    // ===================================================================================
    // CODELAB Level 5
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new humidity state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    
    // TODO 2: Paste or write code below

    // ===================================================================================

    /** Battery layout */
    // ===================================================================================
    // CODELAB Level 5
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new battery state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    
    // TODO 3: Paste or write code below

    // ===================================================================================
  }

  override fun setupObservers() {
    // ===================================================================================
    // CODELAB Level 5
    // Observer on the current temperature status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 4: Paste or write code below

    // ==========================================================================================

    // ===================================================================================
    // CODELAB Level 5
    // Observer on the current fan mode status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 5: Paste or write code below

    // ==========================================================================================

    // ===================================================================================
    // CODELAB Level 5
    // Observer on the current heating setpoint and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 6: Paste or write code below

    // ===================================================================================

    // ===================================================================================
    // CODELAB Level 5
    // Observer on the current cooling setpoint and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 7: Paste or write code below

    // ===================================================================================

    // ===================================================================================
    // CODELAB Level 5
    // Observer on the current system mode status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 8: Paste or write code below

    // ===================================================================================

    // ===================================================================================
    // CODELAB Level 5
    // Observer on the current humidity status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 9: Paste or write code below

    // ===================================================================================

    // ===================================================================================
    // CODELAB Level 5
    // Observer on the current battery status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 10: Paste or write code below

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

  private fun showSystemModePopup() {
    /**
     * ThermostatSystemMode_kOff = 0 ThermostatSystemMode_kAuto = 1 ThermostatSystemMode_kCool = 3
     * ThermostatSystemMode_kHeat = 4
     */
    val modeList =
      arrayOf(
        getString(R.string.thermostat_mode_off),
        getString(R.string.thermostat_mode_cool),
        getString(R.string.thermostat_mode_heat),
        getString(R.string.thermostat_mode_auto)
      )

    // ===================================================================================
    // CODELAB Level 5
    // Trigger the processing for setting system mode.
    // -----------------------------------------------------------------------------------
    
    // TODO 11: Paste or write code below

    // ===================================================================================
  }

  private fun showFanModePopup() {
    /** FanControlFanMode_kOn = 4 FanControlFanMode_kAuto = 5 */
    val modeList =
      arrayOf(
        getString(R.string.fan_control_fan_mode_on),
        getString(R.string.fan_control_fan_mode_auto)
      )

    // ===================================================================================
    // CODELAB Level 5
    // Trigger the processing for setting fan mode.
    // -----------------------------------------------------------------------------------
    
    // TODO 12: Paste or write code below
    
    // ===================================================================================
  }

  private fun convertSystemModeToIndex(mode: ThermostatSystemMode): Int {
    Timber.d("mode:$mode")
    return when (mode) {
      ThermostatSystemMode.OFF -> 0
      ThermostatSystemMode.COOL -> 1
      ThermostatSystemMode.HEAT -> 2
      ThermostatSystemMode.AUTO -> 3
      else -> 3
    }
  }

  private fun convertIndexToSystemMode(index: Int): ThermostatSystemMode {
    Timber.d("index:$index")
    return when (index) {
      0 -> ThermostatSystemMode.OFF
      1 -> ThermostatSystemMode.COOL
      2 -> ThermostatSystemMode.HEAT
      3 -> ThermostatSystemMode.AUTO
      else -> ThermostatSystemMode.AUTO
    }
  }

  private fun convertSystemModeToString(mode: ThermostatSystemMode): String {
    Timber.d("mode:$mode")
    return when (mode) {
      ThermostatSystemMode.OFF -> getString(R.string.thermostat_mode_off)
      ThermostatSystemMode.COOL -> getString(R.string.thermostat_mode_cool)
      ThermostatSystemMode.HEAT -> getString(R.string.thermostat_mode_heat)
      ThermostatSystemMode.AUTO -> getString(R.string.thermostat_mode_auto)
      else -> getString(R.string.thermostat_mode_auto)
    }
  }

  private fun convertFanModeToIndex(mode: FanControlFanMode): Int {
    Timber.d("mode:$mode")
    return when (mode) {
      FanControlFanMode.ON -> 0
      FanControlFanMode.AUTO -> 1
      else -> 2
    }
  }

  private fun convertIndexToFanMode(index: Int): FanControlFanMode {
    Timber.d("index:$index")
    return when (index) {
      0 -> FanControlFanMode.ON
      1 -> FanControlFanMode.AUTO
      else -> FanControlFanMode.AUTO
    }
  }

  private fun convertFanModeToString(mode: FanControlFanMode): String {
    Timber.d("mode:$mode")
    return when (mode) {
      FanControlFanMode.ON -> getString(R.string.fan_control_fan_mode_on)
      FanControlFanMode.AUTO -> getString(R.string.fan_control_fan_mode_auto)
      else -> getString(R.string.fan_control_fan_mode_auto)
    }
  }
}
