package com.matter.virtual.device.app.core.matter.manager

import com.matter.virtual.device.app.DeviceApp
import com.matter.virtual.device.app.MediaPlaybackManager
import com.matter.virtual.device.app.MediaPlaybackPosition
import com.matter.virtual.device.app.core.common.MatterConstants
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.max
import kotlin.math.min
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

@Singleton
class MediaPlaybackManagerStub @Inject constructor(private val deviceApp: DeviceApp) :
  MediaPlaybackManager {

  private val _playbackState = MutableStateFlow(MediaPlaybackManager.PLAYBACK_STATE_NOT_PLAYING)
  val playbackState: StateFlow<Int>
    get() = _playbackState

  private val _playbackSpeed = MutableStateFlow(0)
  val playbackSpeed: StateFlow<Int>
    get() = _playbackSpeed

  private var playbackPosition: Long = 0
  private val playbackDuration: Long = 80000
  private val startTime: Long = 0

  override fun getAttributes(attributesId: Int): Long {
    when (attributesId) {
      MediaPlaybackManager.ATTRIBUTE_PLAYBACK_STATE -> {
        Timber.d("CurrentState")
        return _playbackState.value.toLong()
      }
      MediaPlaybackManager.ATTRIBUTE_PLAYBACK_START_TIME -> {
        Timber.d("StartTime")
        return startTime
      }
      MediaPlaybackManager.ATTRIBUTE_PLAYBACK_DURATION -> {
        Timber.d("Duration")
        return playbackDuration
      }
      MediaPlaybackManager.ATTRIBUTE_PLAYBACK_SPEED -> {
        Timber.d("SampledPosition PlaybackSpeed")
        return playbackSpeed.value.toLong()
      }
      MediaPlaybackManager.ATTRIBUTE_PLAYBACK_SEEK_RANGE_END -> {
        Timber.d("SampledPosition SeekRangeEnd")
        return playbackDuration
      }
      MediaPlaybackManager.ATTRIBUTE_PLAYBACK_SEEK_RANGE_START -> {
        Timber.d("SampledPosition SeekRangeStart")
        return startTime
      }
    }
    return -1
  }

  override fun handleMediaRequest(cmd: Int, parameter: Long): Int {
    val newPosition: Long
    when (cmd) {
      MediaPlaybackManager.REQUEST_PLAY -> {
        Timber.d("request Play")
        deviceApp.setCurrentState(MatterConstants.DEFAULT_ENDPOINT, 0)
        _playbackState.value = MediaPlaybackManager.PLAYBACK_STATE_PLAYING
        _playbackSpeed.value = 1
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_PAUSE -> {
        Timber.d("request pause")
        deviceApp.setCurrentState(MatterConstants.DEFAULT_ENDPOINT, 1)
        _playbackState.value = MediaPlaybackManager.PLAYBACK_STATE_PAUSED
        _playbackSpeed.value = 0
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_STOP -> {
        Timber.d("request stop")
        deviceApp.setCurrentState(MatterConstants.DEFAULT_ENDPOINT, 2)
        _playbackState.value = MediaPlaybackManager.PLAYBACK_STATE_NOT_PLAYING
        _playbackSpeed.value = 0
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_START_OVER -> {
        Timber.d("request start over")
        playbackPosition = 0
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_PREVIOUS -> {
        Timber.d("request previous")
        deviceApp.setCurrentState(MatterConstants.DEFAULT_ENDPOINT, 0)
        _playbackState.value = MediaPlaybackManager.PLAYBACK_STATE_PLAYING
        _playbackSpeed.value = 1
        playbackPosition = 0
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_NEXT -> {
        Timber.d("request next")
        deviceApp.setCurrentState(MatterConstants.DEFAULT_ENDPOINT, 0)
        _playbackState.value = MediaPlaybackManager.PLAYBACK_STATE_PLAYING
        _playbackSpeed.value = 1
        playbackPosition = 0
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_REWIND -> {
        Timber.d("request rewind")
        deviceApp.setCurrentState(MatterConstants.DEFAULT_ENDPOINT, 0)
        if (_playbackSpeed.value == PLAYBACK_MAX_REWIND_SPEED) {
          return MediaPlaybackManager.RESPONSE_STATUS_SPEED_OUT_OF_RANGE
        }
        _playbackState.value = MediaPlaybackManager.PLAYBACK_STATE_PLAYING

        val oldValue = _playbackSpeed.value
        Timber.d("oldValue:$oldValue")
        val newValue =
          if (oldValue >= 0) {
            -1
          } else {
            max(oldValue * 2, PLAYBACK_MAX_REWIND_SPEED)
          }
        Timber.d("newValue:$newValue")
        _playbackSpeed.value = newValue
        Timber.d("Now:${_playbackSpeed.value}")
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_FAST_FORWARD -> {
        Timber.d("request fast forward")
        deviceApp.setCurrentState(MatterConstants.DEFAULT_ENDPOINT, 0)
        if (_playbackSpeed.value == PLAYBACK_MAX_FORWARD_SPEED) {
          return MediaPlaybackManager.RESPONSE_STATUS_SPEED_OUT_OF_RANGE
        }
        _playbackState.value = MediaPlaybackManager.PLAYBACK_STATE_PLAYING

        val oldValue = _playbackSpeed.value
        Timber.d("oldValue:$oldValue")
        val newValue =
          if (oldValue <= 0) {
            1
          } else {
            min(oldValue * 2, PLAYBACK_MAX_FORWARD_SPEED)
          }
        Timber.d("newValue:$newValue")
        _playbackSpeed.value = newValue
        Timber.d("Now:${_playbackSpeed.value}")
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_SKIP_FORWARD -> {
        Timber.d("request skip forward $parameter milliseconds")
        newPosition = playbackPosition + parameter
        playbackPosition =
          when {
            newPosition > playbackDuration -> {
              playbackDuration
            }
            newPosition >= 0 -> {
              newPosition
            }
            else -> {
              0
            }
          }
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_SKIP_BACKWARD -> {
        Timber.d("request skip backward $parameter milliseconds")
        newPosition = playbackPosition - parameter
        playbackPosition =
          when {
            newPosition > playbackDuration -> {
              playbackDuration
            }
            newPosition >= 0 -> {
              newPosition
            }
            else -> {
              0
            }
          }
        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
      MediaPlaybackManager.REQUEST_SEEK -> {
        Timber.d("request seek to $parameter milliseconds")
        if (parameter > playbackDuration) {
          return MediaPlaybackManager.RESPONSE_STATUS_SEEK_OUT_OF_RANGE
        } else {
          playbackPosition = parameter
        }

        return MediaPlaybackManager.RESPONSE_STATUS_SUCCESS
      }
    }

    return MediaPlaybackManager.RESPONSE_STATUS_NOT_ALLOWED
  }

  override fun getPosition(): MediaPlaybackPosition {
    return MediaPlaybackPosition(playbackPosition)
  }

  companion object {
    private const val PLAYBACK_MAX_FORWARD_SPEED: Int = 10
    private const val PLAYBACK_MAX_REWIND_SPEED: Int = -10
  }
}
