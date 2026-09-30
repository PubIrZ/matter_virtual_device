package com.matter.virtual.device.app.core.data.di

import com.matter.virtual.device.app.core.data.repository.SharedPreferencesRepository
import com.matter.virtual.device.app.core.data.repository.SharedPreferencesRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@InstallIn(SingletonComponent::class)
@Module
internal abstract class SharedPreferencesRepositoryModule {

  @Binds
  abstract fun bindSharedPreferencesRepository(
    repository: SharedPreferencesRepositoryImpl
  ): SharedPreferencesRepository
}
