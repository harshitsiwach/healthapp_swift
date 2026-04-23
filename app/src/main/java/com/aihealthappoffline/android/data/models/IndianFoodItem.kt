package com.aihealthappoffline.android.data.models

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "indian_food_db")
data class IndianFoodItem(
    @PrimaryKey
    val id: String,
    val name: String,
    val nameHindi: String? = null,
    val calories: Int,
    val proteinG: Double,
    val carbsG: Double,
    val fatG: Double,
    val fiberG: Double = 0.0,
    val category: String,
    val isVegetarian: Boolean = true,
    val servingSize: String = "1 plate/bowl",
    val tags: String = ""
)
