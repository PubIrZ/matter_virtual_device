package com.matter.virtual.device.app.feature.setup

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.matter.virtual.device.app.core.common.result.successOr
import com.matter.virtual.device.app.core.domain.usecase.network.GetSSIDUseCase
import com.matter.virtual.device.app.core.domain.usecase.sharedpreferences.SetCommissioningSequenceFlagUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import timber.log.Timber

@HiltViewModel
class SetupViewModel
@Inject
constructor(
  private val setCommissioningSequenceFlagUseCase: SetCommissioningSequenceFlagUseCase,
  private val getSSIDUseCase: GetSSIDUseCase
) : ViewModel() {

  override fun onCleared() {
    Timber.d("Hit")
    super.onCleared()
  }

  fun setCommissioningSequenceFlag() {
    Timber.d("Hit")
    viewModelScope.launch { setCommissioningSequenceFlagUseCase(true) }
  }

  suspend fun getSSID(): String {
    Timber.d("Hit")
    val deferred = viewModelScope.async { getSSIDUseCase().successOr("Unknown") }

    val ssid = deferred.await()
    Timber.d("ssid:${ssid}")
    return ssid
  }
}
