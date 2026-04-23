package com.aihealthappoffline.android.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.HealthAppApplication
import com.aihealthappoffline.android.data.models.FamilyProfile
import com.aihealthappoffline.android.data.local.FamilyProfileDao
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class FamilyProfileViewModel(application: Application) : AndroidViewModel(application) {

    private val familyProfileDao = HealthAppApplication.database.familyProfileDao()

    private val _profiles = MutableStateFlow<List<FamilyProfile>>(emptyList())
    val profiles: StateFlow<List<FamilyProfile>> = _profiles.asStateFlow()

    init {
        viewModelScope.launch {
            familyProfileDao.getAllProfiles().collect { _profiles.value = it }
        }
    }

    fun addProfile(
        name: String,
        relationship: String,
        gender: String,
        age: Int,
        height: Float,
        weight: Float
    ) {
        viewModelScope.launch {
            val profile = FamilyProfile(
                name = name,
                relationship = relationship,
                gender = gender,
                age = age,
                heightCm = height,
                weightKg = weight
            )
            familyProfileDao.insert(profile)
        }
    }

    fun deleteProfile(id: Long) {
        viewModelScope.launch {
            familyProfileDao.deleteById(id)
        }
    }
}