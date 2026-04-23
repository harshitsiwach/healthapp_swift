package com.aihealthappoffline.android.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.HealthAppApplication
import com.aihealthappoffline.android.data.models.WeightEntry
import com.aihealthappoffline.android.repositories.HealthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class WeightViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = HealthRepository(
        HealthAppApplication.database.userProfileDao(),
        HealthAppApplication.database.dailyLogDao(),
        HealthAppApplication.database.indianFoodDao(),
        HealthAppApplication.database.weightDao(),
        HealthAppApplication.database.sleepDao()
    )

    private val _weightEntries = MutableStateFlow<List<WeightEntry>>(emptyList())
    val weightEntries: StateFlow<List<WeightEntry>> = _weightEntries.asStateFlow()

    private val today: String = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

    init {
        viewModelScope.launch {
            repository.getAllWeightEntries().collect { entries ->
                _weightEntries.value = entries
            }
        }
    }

    fun addWeight(weightKg: Float, note: String? = null) {
        viewModelScope.launch {
            val entry = WeightEntry(
                weightKg = weightKg,
                date = today,
                note = note
            )
            repository.addWeightEntry(entry)
        }
    }

    fun deleteWeightEntry(id: Long) {
        viewModelScope.launch {
            repository.deleteWeightEntry(id)
        }
    }
}