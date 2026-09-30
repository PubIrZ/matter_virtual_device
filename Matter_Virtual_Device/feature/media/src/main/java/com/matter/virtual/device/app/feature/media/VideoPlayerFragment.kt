package com.matter.virtual.device.app.feature.media

import androidx.fragment.app.viewModels
import androidx.navigation.fragment.navArgs
import com.matter.virtual.device.app.core.model.databinding.ButtonData
import com.matter.virtual.device.app.core.ui.BaseFragment
import com.matter.virtual.device.app.core.ui.databinding.LayoutAppbarBinding
import com.matter.virtual.device.app.feature.media.databinding.FragmentVideoPlayerBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import timber.log.Timber

@AndroidEntryPoint
class VideoPlayerFragment :
  BaseFragment<FragmentVideoPlayerBinding, VideoPlayerViewModel>(R.layout.fragment_video_player) {

  override val viewModel: VideoPlayerViewModel by viewModels()

  @OptIn(ExperimentalSerializationApi::class)
  override fun setupNavArgs() {
    val args: VideoPlayerFragmentArgs by navArgs()
    matterSettings = Json.decodeFromString(args.setting)
  }

  override fun setupAppbar(): LayoutAppbarBinding = binding.appbar

  override fun setupUi() {
    binding.viewModel = viewModel

    /** title text */
    binding.appbar.toolbarTitle.text = getString(R.string.matter_basic_video_player)

    /** OnOff layout */
    // ===================================================================================
    // [CODELAB] Observe cluster value : VideoPlayer
    // [ButtonData] Observer on the current on/off status and react on the fragment's UI.
    // [OnClickListener] Trigger the processing for updating new on/off state of the virtual device.
    // -----------------------------------------------------------------------------------
    binding.videoPlayerOnOffLayout.buttonData =
      ButtonData(
        onOff = viewModel.onOff,
        onText = R.string.on_off_switch_power_on,
        offText = R.string.on_off_switch_power_off
      )
    binding.videoPlayerOnOffLayout.button.setOnClickListener { viewModel.onClickButton() }
    // ===================================================================================

    /** State layout */
    binding.videoPlayerStateLayout.titleText.text = getString(R.string.media)

    /** Speed layout */
    binding.videoPlayerSpeedLayout.titleText.text = getString(R.string.speed)

    /** Keypad layout */
    binding.videoPlayerKeypadLayout.titleText.text = getString(R.string.keypad)
  }

  override fun setupObservers() {
    // ===================================================================================
    // [CODELAB] Observe cluster value : VideoPlayer
    // Observer on the current playback status and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.playbackState.observe(viewLifecycleOwner) { state ->
      val stateText = convertPlaybackStateToString(state)
      Timber.d("playbackState:$state($stateText)")
      binding.videoPlayerStateLayout.valueText.text = stateText
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : VideoPlayer
    // Observer on the current playback speed and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.playbackSpeed.observe(viewLifecycleOwner) { speed ->
      binding.videoPlayerSpeedLayout.valueText.text = speed.toString()
    }
    // ===================================================================================

    // ===================================================================================
    // [CODELAB] Observe cluster value : VideoPlayer
    // Observer on the current key code and react on the fragment's UI.
    // -----------------------------------------------------------------------------------
    viewModel.keyCode.observe(viewLifecycleOwner) { keyCode ->
      binding.videoPlayerKeypadLayout.valueText.text = keyCode.value
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

  private fun convertPlaybackStateToString(state: Int): String {
    Timber.d("state:$state")
    return when (state) {
      0 -> getString(R.string.video_player_state_playing)
      1 -> getString(R.string.video_player_state_paused)
      2 -> getString(R.string.video_player_state_not_playing)
      3 -> getString(R.string.video_player_state_buffering)
      else -> getString(R.string.video_player_state_unknown)
    }
  }
}
