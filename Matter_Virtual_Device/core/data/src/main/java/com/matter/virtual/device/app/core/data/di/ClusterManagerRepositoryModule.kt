package com.matter.virtual.device.app.core.data.di

import com.matter.virtual.device.app.core.data.repository.cluster.*
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@InstallIn(SingletonComponent::class)
@Module
internal abstract class ClusterManagerRepositoryModule {

  @Binds
  abstract fun bindDoorLockManagerRepository(
    repository: DoorLockManagerRepositoryImpl
  ): DoorLockManagerRepository

  @Binds
  abstract fun bindKeypadInputManagerRepository(
    repository: KeypadInputManagerRepositoryImpl
  ): KeypadInputManagerRepository

  @Binds
  abstract fun bindMediaPlaybackManagerRepository(
    repository: MediaPlaybackManagerRepositoryImpl
  ): MediaPlaybackManagerRepository

  @Binds
  abstract fun bindOnOffManagerRepository(
    repository: OnOffManagerRepositoryImpl
  ): OnOffManagerRepository

  @Binds
  abstract fun bindPowerSourceManagerRepository(
    repository: PowerSourceManagerRepositoryImpl
  ): PowerSourceManagerRepository

  @Binds
  abstract fun bindTemperatureMeasurementManagerRepository(
    repository: TemperatureMeasurementManagerRepositoryImpl
  ): TemperatureMeasurementManagerRepository

  @Binds
  abstract fun bindThermostatManagerRepository(
    repository: ThermostatManagerRepositoryImpl
  ): ThermostatManagerRepository

  @Binds
  abstract fun bindWindowCoveringManagerRepository(
    repository: WindowCoveringManagerRepositoryImpl
  ): WindowCoveringManagerRepository

  @Binds
  abstract fun bindLevelManagerRepository(
    repository: LevelManagerRepositoryImpl
  ): LevelManagerRepository

  @Binds
  abstract fun bindColorControlManagerRepository(
    repository: ColorControlManagerRepositoryImpl
  ): ColorControlManagerRepository

  @Binds
  abstract fun bindOccupancySensingManagerRepository(
    repository: OccupancySensingManagerRepositoryImpl
  ): OccupancySensingManagerRepository

  @Binds
  abstract fun bindRelativeHumidityMeasurementManagerRepository(
    repository: RelativeHumidityMeasurementManagerRepositoryImpl
  ): RelativeHumidityMeasurementManagerRepository

  @Binds
  abstract fun bindBooleanStateManagerRepository(
    repository: BooleanStateManagerRepositoryImpl
  ): BooleanStateManagerRepository

  @Binds
  abstract fun bindFanControlManagerRepository(
    repository: FanControlManagerRepositoryImpl
  ): FanControlManagerRepository
}
