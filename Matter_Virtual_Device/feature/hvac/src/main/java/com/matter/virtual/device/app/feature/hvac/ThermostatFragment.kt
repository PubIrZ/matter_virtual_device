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
    // [CODELAB] Observe cluster value : Thermostat
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new temperature state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    binding.thermostatTemperatureSeekbar.setOnSeekBarChangeListener(
      object : SeekBar.OnSeekBarChangeListener {
        override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
          viewModel.updateTemperatureSeekbarProgress(progress)
        }

        override fun onStartTrackingTouch(seekBar: SeekBar) {}

        override fun onStopTrackingTouch(seekBar: SeekBar) {
          viewModel.updateTemperatureToCluster(seekBar.progress)
        }
      }
    )
    // ===================================================================================

    /** Fan mode layout */
    binding.fanControlFanModeLayout.titleText.text = getString(R.string.fan_control_fan_mode)
    binding.fanControlFanModeLayout.button.setImageResource(R.drawable.more_tab_settings)
    binding.fanControlFanModeLayout.button.setOnClickListener { showFanModePopup() }

    /** Humidity Sensor layout */
    // ===================================================================================
    // [CODELAB] Observe cluster value : Thermostat
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new humidity state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    binding.humiditySensorHumiditySeekbar.setOnSeekBarChangeListener(
      object : SeekBar.OnSeekBarChangeListener {
        override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
          viewModel.updateHumiditySeekbarProgress(progress)
        }

        override fun onStartTrackingTouch(seekBar: SeekBar) {}

        override fun onStopTrackingTouch(seekBar: SeekBar) {
          viewModel.updateHumidityToCluster(seekBar.progress)
        }
      }
    )
    // ===================================================================================

    /** Battery layout */
    // ===================================================================================
    // [CODELAB] Observe cluster value : Thermostat
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new battery state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    binding.thermostatBatteryLayout.titleText.text = getString(R.string.battery)
    binding.thermostatBatteryLayout.seekbarData = SeekbarData(progress = viewModel.batteryStatus)
    binding.thermostatBatteryLayout.seekbar.setOnSeekBarChangeListener(
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
    // [CODELAB] Observe cluster value : Thermostat
    // Observer on the current temperature status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.temperature.observe(viewLifecycleOwner) {
      val celsiusTemp: Float = it.toFloat() / 100

      val celsiusText: String = getString(R.string.temperature_celsius_format, celsiusTemp)
      binding.thermostatTemperatureCelsiusValueText.text =
        Html.fromHtml(celsiusText, Html.FROM_HTML_MODE_LEGACY)

      val fahrenheitTemp: Float = it.toFloat() / 100 * 9 / 5 + 32
      val fahrenheitText: String = getString(R.string.temperature_fahrenheit_format, fahrenheitTemp)
      binding.thermostatTemperatureFahrenheitValueText.text =
        Html.fromHtml(fahrenheitText, Html.FROM_HTML_MODE_LEGACY)

      binding.thermostatTemperatureSeekbar.progress = celsiusTemp.toInt()
    }
    // ==========================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : Thermostat
    // Observer on the current fan mode status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.fanMode.observe(viewLifecycleOwner) {
      Timber.d("fanMode:$it")
      this.fanMode = it
      binding.fanControlFanModeLayout.valueText.text = convertFanModeToString(it)
    }
    // ==========================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : Thermostat
    // Observer on the current heating setpoint and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.occupiedHeatingSetpoint.observe(viewLifecycleOwner) {
      val celsiusTemp: Float = it.toFloat() / 100

      val celsiusText: String = getString(R.string.temperature_celsius_format, celsiusTemp)
      binding.thermostatSetTemperatureHeatingCelsiusValueText.text =
        Html.fromHtml(celsiusText, Html.FROM_HTML_MODE_LEGACY)

      val fahrenheitTemp: Float = it.toFloat() / 100 * 9 / 5 + 32
      val fahrenheitText: String = getString(R.string.temperature_fahrenheit_format, fahrenheitTemp)
      binding.thermostatSetTemperatureHeatingFahrenheitValueText.text =
        Html.fromHtml(fahrenheitText, Html.FROM_HTML_MODE_LEGACY)
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : Thermostat
    // Observer on the current cooling setpoint and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.occupiedCoolingSetpoint.observe(viewLifecycleOwner) {
      val celsiusTemp: Float = it.toFloat() / 100

      val celsiusText: String = getString(R.string.temperature_celsius_format, celsiusTemp)
      binding.thermostatSetTemperatureCoolingCelsiusValueText.text =
        Html.fromHtml(celsiusText, Html.FROM_HTML_MODE_LEGACY)

      val fahrenheitTemp: Float = it.toFloat() / 100 * 9 / 5 + 32
      val fahrenheitText: String = getString(R.string.temperature_fahrenheit_format, fahrenheitTemp)
      binding.thermostatSetTemperatureCoolingFahrenheitValueText.text =
        Html.fromHtml(fahrenheitText, Html.FROM_HTML_MODE_LEGACY)
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : Thermostat
    // Observer on the current system mode status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.systemMode.observe(viewLifecycleOwner) {
      Timber.d("systemMode:$it")
      this.systemMode = it
      binding.thermostatSystemModeLayout.valueText.text = convertSystemModeToString(it)
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : Thermostat
    // Observer on the current humidity status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.humidity.observe(viewLifecycleOwner) {
      val humidity: Int = it / 100
      val humidityText: String = getString(R.string.humidity_format, humidity)
      binding.humiditySensorHumidityPercentageValueText.text =
        Html.fromHtml(humidityText, Html.FROM_HTML_MODE_LEGACY)
      binding.humiditySensorHumiditySeekbar.progress = humidity
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : Thermostat
    // Observer on the current battery status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.batteryStatus.observe(viewLifecycleOwner) {
      val text: String = getString(R.string.battery_format, it)
      binding.thermostatBatteryLayout.valueText.text =
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
    // [CODELAB] Observe cluster value : Thermostat
    // Trigger the processing for setting system mode.
    // -----------------------------------------------------------------------------------
    AlertDialog.Builder(requireContext())
      .setTitle(R.string.thermostat_mode)
      .setSingleChoiceItems(modeList, convertSystemModeToIndex(this.systemMode)) { dialog, which ->
        Timber.d("Thermostat mode set $which(${modeList[which]})")
        viewModel.setSystemMode(convertIndexToSystemMode(which))
        dialog.dismiss()
      }
      .setNegativeButton(R.string.cancel, null)
      .show()
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
    // [CODELAB] Observe cluster value : Thermostat
    // Trigger the processing for setting fan mode.
    // -----------------------------------------------------------------------------------
    AlertDialog.Builder(requireContext())
      .setTitle(R.string.fan_control_fan_mode)
      .setSingleChoiceItems(modeList, convertFanModeToIndex(this.fanMode)) { dialog, which ->
        Timber.d("Fan mode set $which(${modeList[which]})")
        viewModel.setFanMode(convertIndexToFanMode(which))
        dialog.dismiss()
      }
      .setNegativeButton(R.string.cancel, null)
      .show()
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
