package com.matter.virtual.device.app.core.data.di

import com.matter.virtual.device.app.core.data.repository.MatterRepository
import com.matter.virtual.device.app.core.data.repository.MatterRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@InstallIn(SingletonComponent::class)
@Module
internal abstract class DataModule {

  @Binds
  @Singleton
  abstract fun bindMatterRepository(repository: MatterRepositoryImpl): MatterRepository
}
