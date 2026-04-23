package com.aihealthappoffline.android.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.HealthAppApplication
import com.aihealthappoffline.android.data.models.UserProfile
import com.aihealthappoffline.android.repositories.HealthRepository
import kotlinx.coroutines.launch
import java.util.UUID

data class TargetValues(val calories: Int, val protein: Int, val carbs: Int, val fat: Int)

class OnboardingViewModel(
    private val repository: HealthRepository = HealthRepository(
        HealthAppApplication.database.userProfileDao(),
        HealthAppApplication.database.dailyLogDao(),
        HealthAppApplication.database.indianFoodDao(),
        HealthAppApplication.database.weightDao(),
        HealthAppApplication.database.sleepDao()
    )
) : ViewModel() {

    var gender = "Male"
    var workoutsPerWeek = 3
    var age = 25
    var heightCm = 170.0
    var weightKg = 70.0
    var goal = "maintain"
    var dietaryPreference = "vegetarian"

    fun calculateTargets(): TargetValues {
        // Mifflin-St Jeor BMR
        val bmr = when (gender) {
            "Male" -> (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
            "Female" -> (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161
            else -> (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 78
        }

        val activityMultiplier = when (workoutsPerWeek) {
            0 -> 1.2
            1, 2 -> 1.375
            3, 4 -> 1.55
            5, 6 -> 1.725
            else -> 1.9
        }

        val tdee = (bmr * activityMultiplier).toInt()

        val calories = when (goal) {
            "lose" -> tdee - 500
            "gain" -> tdee + 300
            else -> tdee
        }

        val protein = when (goal) {
            "gain" -> (weightKg * 2.0).toInt()
            "lose" -> (weightKg * 1.8).toInt()
            else -> (weightKg * 1.4).toInt()
        }

        val fat = (calories * 0.25 / 9).toInt()
        val carbs = ((calories - (protein * 4) - (fat * 9)) / 4).coerceAtLeast(50)

        return TargetValues(calories, protein, carbs, fat)
    }

    fun saveProfile() {
        val targets = calculateTargets()
        val calories = targets.calories
        val protein = targets.protein
        val carbs = targets.carbs
        val fat = targets.fat
        val profile = UserProfile(
            id = UUID.randomUUID().toString(),
            gender = gender,
            dob = 0L, // TODO: calculate from age
            heightCm = heightCm,
            weightKg = weightKg,
            workoutsPerWeek = workoutsPerWeek,
            goal = goal,
            dietaryPreference = dietaryPreference,
            calculatedDailyCalories = calories,
            calculatedDailyProtein = protein,
            calculatedDailyCarbs = carbs,
            calculatedDailyFats = fat,
            healthScore = 70,
            streakCount = 1,
            age = age
        )
        viewModelScope.launch {
            repository.saveProfile(profile)
        }
    }
}
