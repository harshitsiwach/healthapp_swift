package com.aihealthappoffline.android.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.HealthAppApplication
import com.aihealthappoffline.android.data.models.UserProfile
import com.aihealthappoffline.android.repositories.HealthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class SettingsViewModel(
    private val repository: HealthRepository = HealthRepository(
        HealthAppApplication.database.userProfileDao(),
        HealthAppApplication.database.dailyLogDao(),
        HealthAppApplication.database.indianFoodDao()
    )
) : ViewModel() {

    private val _profile = MutableStateFlow<UserProfile?>(null)
    val profile: StateFlow<UserProfile?> = _profile.asStateFlow()

    private val _privacyMode = MutableStateFlow(true)
    val privacyMode: StateFlow<Boolean> = _privacyMode.asStateFlow()

    init {
        viewModelScope.launch {
            repository.profileFlow.collect { _profile.value = it }
        }
    }

    fun setPrivacyMode(enabled: Boolean) {
        _privacyMode.value = enabled
    }
}
