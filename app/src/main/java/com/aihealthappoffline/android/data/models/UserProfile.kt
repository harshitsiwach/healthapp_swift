package com.aihealthappoffline.android.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "user_profiles")
data class UserProfile(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val gender: String = "Male",
    val dob: Long = 0L,
    val heightCm: Double = 170.0,
    val weightKg: Double = 70.0,
    val workoutsPerWeek: Int = 3,
    val goal: String = "maintain",
    val dietaryPreference: String = "vegetarian",
    val calculatedDailyCalories: Int = 2000,
    val calculatedDailyProtein: Int = 120,
    val calculatedDailyCarbs: Int = 250,
    val calculatedDailyFats: Int = 65,
    val healthScore: Int = 75,
    val streakCount: Int = 1,
    val lastOpenedDate: String = "",
    val notificationTime: String = "20:00",
    val name: String = "",
    val age: Int = 25
)
