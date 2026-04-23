package com.aihealthappoffline.android.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.HealthAppApplication
import com.aihealthappoffline.android.data.models.SleepEntry
import com.aihealthappoffline.android.repositories.HealthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SleepViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = HealthRepository(
        HealthAppApplication.database.userProfileDao(),
        HealthAppApplication.database.dailyLogDao(),
        HealthAppApplication.database.indianFoodDao(),
        HealthAppApplication.database.weightDao(),
        HealthAppApplication.database.sleepDao()
    )

    private val _sleepEntries = MutableStateFlow<List<SleepEntry>>(emptyList())
    val sleepEntries: StateFlow<List<SleepEntry>> = _sleepEntries.asStateFlow()

    private val today: String = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

    init {
        viewModelScope.launch {
            repository.getAllSleepEntries().collect { entries ->
                _sleepEntries.value = entries
            }
        }
    }

    fun addSleep(hoursSlept: Float, sleepQuality: Int? = null, notes: String? = null) {
        viewModelScope.launch {
            val entry = SleepEntry(
                hoursSlept = hoursSlept,
                date = today,
                sleepQuality = sleepQuality,
                notes = notes
            )
            repository.addSleepEntry(entry)
        }
    }

    fun deleteSleepEntry(id: Long) {
        viewModelScope.launch {
            repository.deleteSleepEntry(id)
        }
    }
}