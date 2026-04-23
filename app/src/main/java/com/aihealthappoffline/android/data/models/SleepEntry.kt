package com.aihealthappoffline.android.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "sleep_entries")
data class SleepEntry(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val hoursSlept: Float,
    val date: String, // yyyy-MM-dd
    val sleepQuality: Int? = null, // 1-5 rating
    val notes: String? = null,
    val timestamp: Long = System.currentTimeMillis()
)