package com.aihealthappoffline.android.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "daily_logs")
data class DailyLog(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val date: String = "",
    val foodName: String? = null,
    val estimatedCalories: Int = 0,
    val proteinG: Double = 0.0,
    val carbsG: Double = 0.0,
    val fatG: Double = 0.0,
    val fiberG: Double = 0.0,
    val imageUri: String? = null,
    val mealType: String = "snack",
    val goalCompleted: Boolean = false,
    val timestamp: Long = System.currentTimeMillis()
)
