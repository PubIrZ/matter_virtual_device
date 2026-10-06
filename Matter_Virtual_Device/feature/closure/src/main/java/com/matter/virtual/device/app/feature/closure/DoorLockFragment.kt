package com.matter.virtual.device.app.feature.closure

import android.text.Html
import android.widget.SeekBar
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.navArgs
import com.matter.virtual.device.app.core.model.databinding.ButtonData
import com.matter.virtual.device.app.core.model.databinding.SeekbarData
import com.matter.virtual.device.app.core.ui.BaseFragment
import com.matter.virtual.device.app.core.ui.databinding.LayoutAppbarBinding
import com.matter.virtual.device.app.feature.closure.databinding.FragmentDoorLockBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import timber.log.Timber

@AndroidEntryPoint
class DoorLockFragment :
  BaseFragment<FragmentDoorLockBinding, DoorLockViewModel>(R.layout.fragment_door_lock) {

  override val viewModel: DoorLockViewModel by viewModels()

  @OptIn(ExperimentalSerializationApi::class)
  override fun setupNavArgs() {
    val args: DoorLockFragmentArgs by navArgs()
    matterSettings = Json.decodeFromString(args.setting)
  }

  override fun setupAppbar(): LayoutAppbarBinding = binding.appbar

  override fun setupUi() {
    /** title text */
    binding.appbar.toolbarTitle.text = getString(R.string.matter_door_lock)

    /** OnOff layout */
    // ===================================================================================
    // CODELAB Level 3
    // [ButtonData] Observer on the current lock status and react on the fragment's UI.
    // [OnClickListener] Trigger the processing for updating new lock state of the virtual device.
    // -----------------------------------------------------------------------------------
    
    // TODO 1: Paste or write code below

    // ===================================================================================

    /** Send alarm layout */
    binding.doorLockSendAlarmLayout.valueText.text =
      getString(R.string.door_lock_send_lock_alarm_event)

    // ===================================================================================
    // CODELAB Level 3
    // Trigger the processing for sending alarm event.
    // -----------------------------------------------------------------------------------
    
    // TODO 2: Paste or write code below

    // ===================================================================================

    /** Battery layout */
    // ===================================================================================
    // CODELAB Level 3
    // [onProgressChanged] will update the fragment's UI via viewmodel livedata
    // [onStopTrackingTouch] will trigger the processing for updating new battery state of the
    // virtual device.
    // -----------------------------------------------------------------------------------
    
    // TODO 3: Paste or write code below

    // ===================================================================================
  }

  override fun setupObservers() {
    // ===================================================================================
    // CODELAB Level 3
    // Observer on the current battery status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    
    // TODO 4: Paste or write code below
    
    // ===================================================================================
  }

  override fun onResume() {
    Timber.d("onResume()")
    super.onResume()
  }

  override fun onDestroy() {
    Timber.d("onDestroy()")
    super.onDestroy()
  }
}
