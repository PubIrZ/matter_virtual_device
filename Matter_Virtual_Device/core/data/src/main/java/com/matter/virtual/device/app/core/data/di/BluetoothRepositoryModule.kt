package com.matter.virtual.device.app.core.data.di

import com.matter.virtual.device.app.core.data.repository.BluetoothRepository
import com.matter.virtual.device.app.core.data.repository.BluetoothRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@InstallIn(SingletonComponent::class)
@Module
internal abstract class BluetoothRepositoryModule {

  @Binds
  abstract fun bindBluetoothRepository(repository: BluetoothRepositoryImpl): BluetoothRepository
}
