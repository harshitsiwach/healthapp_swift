package com.aihealthappoffline.android.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.HealthAppApplication
import com.aihealthappoffline.android.data.models.UserProfile
import com.aihealthappoffline.android.repositories.HealthRepository
import com.aihealthappoffline.android.repositories.MacroTotals
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class DashboardViewModel(
    private val repository: HealthRepository = HealthRepository(
        HealthAppApplication.database.userProfileDao(),
        HealthAppApplication.database.dailyLogDao(),
        HealthAppApplication.database.indianFoodDao()
    )
) : ViewModel() {

    private val _profile = MutableStateFlow<UserProfile?>(null)
    val profile: StateFlow<UserProfile?> = _profile.asStateFlow()

    private val _todayTotals = MutableStateFlow<MacroTotals?>(null)
    val todayTotals: StateFlow<MacroTotals?> = _todayTotals.asStateFlow()

    private val _hydration = MutableStateFlow(0)
    val hydration: StateFlow<Int> = _hydration.asStateFlow()

    private val _steps = MutableStateFlow(0)
    val steps: StateFlow<Int> = _steps.asStateFlow()

    private val today: String = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

    init {
        viewModelScope.launch {
            repository.profileFlow.collect { _profile.value = it }
        }
        viewModelScope.launch {
            val totals = repository.getTotals(today)
            _todayTotals.value = totals
        }
        loadHydration()
        loadSteps()
    }

    fun addWater(ml: Int) {
        _hydration.value += ml
        // TODO: persist to DataStore
    }

    private fun loadHydration() {
        // TODO: load from DataStore
        _hydration.value = 0
    }

    private fun loadSteps() {
        // TODO: load from Google Fit
        _steps.value = 0
    }
}
