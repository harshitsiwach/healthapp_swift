package com.aihealthappoffline.android.viewmodels

import android.app.Application
import android.content.Intent
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.HealthAppApplication
import com.aihealthappoffline.android.data.models.UserProfile
import com.aihealthappoffline.android.health.GoogleFitManager
import com.aihealthappoffline.android.repositories.HealthRepository
import com.aihealthappoffline.android.repositories.MacroTotals
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class DashboardViewModel(
    application: Application
) : AndroidViewModel(application) {

    private val repository = HealthRepository(
        HealthAppApplication.database.userProfileDao(),
        HealthAppApplication.database.dailyLogDao(),
        HealthAppApplication.database.indianFoodDao(),
        HealthAppApplication.database.weightDao(),
        HealthAppApplication.database.sleepDao()
    )

    private val googleFitManager = GoogleFitManager(application)
    private val hydrationDataStore = com.aihealthappoffline.android.data.local.HydrationDataStore(application)

    private val _profile = MutableStateFlow<UserProfile?>(null)
    val profile: StateFlow<UserProfile?> = _profile.asStateFlow()

    private val _todayTotals = MutableStateFlow<MacroTotals?>(null)
    val todayTotals: StateFlow<MacroTotals?> = _todayTotals.asStateFlow()

    private val _hydration = MutableStateFlow(0)
    val hydration: StateFlow<Int> = _hydration.asStateFlow()

    private val _hydrationGoal = MutableStateFlow(2000)
    val hydrationGoal: StateFlow<Int> = _hydrationGoal.asStateFlow()

    private val _steps = MutableStateFlow(0)
    val steps: StateFlow<Int> = _steps.asStateFlow()

    private val _caloriesBurned = MutableStateFlow(0)
    val caloriesBurned: StateFlow<Int> = _caloriesBurned.asStateFlow()

    private val _distanceKm = MutableStateFlow(0f)
    val distanceKm: StateFlow<Float> = _distanceKm.asStateFlow()

    private val _googleFitConnected = MutableStateFlow(false)
    val googleFitConnected: StateFlow<Boolean> = _googleFitConnected.asStateFlow()

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
        checkGoogleFit()
    }

    fun addWater(ml: Int) {
        viewModelScope.launch {
            hydrationDataStore.addHydration(ml)
            _hydration.value = hydrationDataStore.hydrationFlow.first()
        }
    }

    fun checkGoogleFit() {
        _googleFitConnected.value = googleFitManager.hasPermissions()
        if (_googleFitConnected.value) {
            refreshGoogleFitData()
        }
    }

    fun refreshGoogleFitData() {
        viewModelScope.launch {
            _steps.value = googleFitManager.getTodaySteps()
            _caloriesBurned.value = googleFitManager.getTodayCaloriesBurned()
            _distanceKm.value = googleFitManager.getTodayDistance()
        }
    }

    fun getGoogleFitSignInIntent(): Intent {
        val options = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .addExtension(googleFitManager.fitnessOptions)
            .build()
        return GoogleSignIn.getClient(getApplication(), options).signInIntent
    }

    private fun loadHydration() {
        viewModelScope.launch {
            _hydration.value = hydrationDataStore.hydrationFlow.first()
            _hydrationGoal.value = hydrationDataStore.goalFlow.first()
        }
    }
}
