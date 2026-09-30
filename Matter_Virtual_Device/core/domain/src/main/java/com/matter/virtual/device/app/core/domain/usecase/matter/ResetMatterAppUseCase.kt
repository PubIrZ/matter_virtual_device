package com.matter.virtual.device.app.core.domain.usecase.matter

import com.matter.virtual.device.app.core.common.di.IoDispatcher
import com.matter.virtual.device.app.core.data.repository.BluetoothRepository
import com.matter.virtual.device.app.core.data.repository.MatterRepository
import com.matter.virtual.device.app.core.data.repository.SharedPreferencesRepository
import com.matter.virtual.device.app.core.domain.NonParamCoroutineUseCase
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher
import timber.log.Timber

class ResetMatterAppUseCase
@Inject
constructor(
  private val matterRepository: MatterRepository,
  private val sharedPreferencesRepository: SharedPreferencesRepository,
  private val bluetoothRepository: BluetoothRepository,
  @IoDispatcher dispatcher: CoroutineDispatcher
) : NonParamCoroutineUseCase<Unit>(dispatcher) {

  override suspend fun execute() {
    runCatching { bluetoothRepository.resetGattServer() }
      .onFailure { Timber.e("Timeout called", it) }

    matterRepository.reset()
    matterRepository.stopMatterAppService()
    sharedPreferencesRepository.deleteMatterSharedPreferences()
    sharedPreferencesRepository.setCommissioningDeviceCompleted(false)
    sharedPreferencesRepository.setCommissioningSequence(false)
  }
}
