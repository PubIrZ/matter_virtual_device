package com.matter.virtual.device.app.core.data.di

import com.matter.virtual.device.app.core.data.repository.NetworkRepository
import com.matter.virtual.device.app.core.data.repository.NetworkRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@InstallIn(SingletonComponent::class)
@Module
internal abstract class NetworkRepositoryModule {

  @Binds abstract fun bindNetworkRepository(repository: NetworkRepositoryImpl): NetworkRepository
}
