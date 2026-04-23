package com.aihealthappoffline.android.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "period_entries")
data class PeriodEntry(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val startDate: String, // yyyy-MM-dd
    val endDate: String? = null,
    val flowLevel: Int = 0, // 0=none, 1=light, 2=medium, 3=heavy
    val symptoms: String? = null, // comma-separated: cramps, headache, mood, etc.
    val mood: String? = null, // happy, sad, irritable, calm
    val notes: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)