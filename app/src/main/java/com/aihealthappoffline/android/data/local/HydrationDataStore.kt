package com.aihealthappoffline.android.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

val Context.hydrationDataStore: DataStore<Preferences> by preferencesDataStore(name = "hydration_prefs")

class HydrationDataStore(private val context: Context) {

    private val hydrationKey = intPreferencesKey("hydration_ml")
    private val goalKey = intPreferencesKey("hydration_goal")

    val hydrationFlow: Flow<Int> = context.hydrationDataStore.data.map { preferences ->
        preferences[hydrationKey] ?: 0
    }

    val goalFlow: Flow<Int> = context.hydrationDataStore.data.map { preferences ->
        preferences[goalKey] ?: 2000
    }

    suspend fun saveHydration(ml: Int) {
        context.hydrationDataStore.edit { preferences ->
            preferences[hydrationKey] = ml
        }
    }

    suspend fun addHydration(ml: Int) {
        context.hydrationDataStore.edit { preferences ->
            val current = preferences[hydrationKey] ?: 0
            preferences[hydrationKey] = current + ml
        }
    }

    suspend fun setGoal(ml: Int) {
        context.hydrationDataStore.edit { preferences ->
            preferences[goalKey] = ml
        }
    }

    suspend fun resetDaily() {
        context.hydrationDataStore.edit { preferences ->
            preferences[hydrationKey] = 0
        }
    }
}