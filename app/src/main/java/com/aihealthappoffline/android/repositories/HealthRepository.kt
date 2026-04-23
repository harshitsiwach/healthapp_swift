package com.aihealthappoffline.android.repositories

import com.aihealthappoffline.android.data.local.DailyLogDao
import com.aihealthappoffline.android.data.local.IndianFoodDao
import com.aihealthappoffline.android.data.local.UserProfileDao
import com.aihealthappoffline.android.data.models.DailyLog
import com.aihealthappoffline.android.data.models.IndianFoodItem
import com.aihealthappoffline.android.data.models.UserProfile
import kotlinx.coroutines.flow.Flow

class HealthRepository(
    private val profileDao: UserProfileDao,
    private val logDao: DailyLogDao,
    private val foodDao: IndianFoodDao
) {
    val profileFlow: Flow<UserProfile?> = profileDao.getProfileFlow()

    suspend fun getProfile(): UserProfile? = profileDao.getProfile()

    suspend fun saveProfile(profile: UserProfile) = profileDao.insert(profile)

    suspend fun updateProfile(profile: UserProfile) = profileDao.update(profile)

    suspend fun hasProfile(): Boolean = profileDao.getCount() > 0

    fun getLogsForDate(date: String): Flow<List<DailyLog>> = logDao.getLogsForDate(date)

    suspend fun getLogsForDateOnce(date: String): List<DailyLog> = logDao.getLogsForDateOnce(date)

    suspend fun addLog(log: DailyLog) = logDao.insert(log)

    suspend fun deleteLog(id: String) = logDao.deleteById(id)

    suspend fun getTotals(date: String): MacroTotals {
        return MacroTotals(
            calories = logDao.getTotalCaloriesForDate(date) ?: 0,
            protein = logDao.getTotalProteinForDate(date) ?: 0.0,
            carbs = logDao.getTotalCarbsForDate(date) ?: 0.0,
            fat = logDao.getTotalFatForDate(date) ?: 0.0
        )
    }

    fun searchFood(query: String): Flow<List<IndianFoodItem>> =
        if (query.isBlank()) foodDao.getAll() else foodDao.searchFood(query)

    fun getFoodByCategory(category: String): Flow<List<IndianFoodItem>> =
        foodDao.getByCategory(category)

    suspend fun seedFoodDatabase(items: List<IndianFoodItem>) = foodDao.insertAll(items)

    suspend fun isFoodDbSeeded(): Boolean = foodDao.getCount() > 0
}

data class MacroTotals(
    val calories: Int,
    val protein: Double,
    val carbs: Double,
    val fat: Double
)
