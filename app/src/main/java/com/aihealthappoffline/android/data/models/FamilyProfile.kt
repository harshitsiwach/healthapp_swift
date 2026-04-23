package com.aihealthappoffline.android.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "family_profiles")
data class FamilyProfile(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val relationship: String, // spouse, child, parent, sibling
    val gender: String,
    val age: Int,
    val heightCm: Float,
    val weightKg: Float,
    val healthGoals: String? = null,
    val dietaryRestrictions: String? = null,
    val isActive: Boolean = true,
    val createdAt: Long = System.currentTimeMillis()
)