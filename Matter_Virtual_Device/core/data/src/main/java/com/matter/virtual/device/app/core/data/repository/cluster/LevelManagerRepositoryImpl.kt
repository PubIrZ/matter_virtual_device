package com.matter.virtual.device.app.core.data.repository.cluster

import com.matter.virtual.device.app.core.matter.manager.LevelManagerStub
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow
import timber.log.Timber

internal class LevelManagerRepositoryImpl
@Inject
constructor(private val levelManagerStub: LevelManagerStub) : LevelManagerRepository {
  override fun getLevelFlow(): StateFlow<Int> {
    Timber.d("Hit")
    return levelManagerStub.level
  }

  override suspend fun setCurrentLevel(value: Int) {
    Timber.d("value:$value")
    levelManagerStub.setCurrentLevel(value)
  }
}
