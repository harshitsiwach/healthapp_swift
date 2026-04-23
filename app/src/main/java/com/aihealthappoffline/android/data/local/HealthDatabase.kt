package com.aihealthappoffline.android.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.aihealthappoffline.android.data.models.DailyLog
import com.aihealthappoffline.android.data.models.IndianFoodItem
import com.aihealthappoffline.android.data.models.SleepEntry
import com.aihealthappoffline.android.data.models.UserProfile
import com.aihealthappoffline.android.data.models.WeightEntry

@Database(
    entities = [UserProfile::class, DailyLog::class, IndianFoodItem::class, WeightEntry::class, SleepEntry::class],
    version = 2,
    exportSchema = false
)
abstract class HealthDatabase : RoomDatabase() {
    abstract fun userProfileDao(): UserProfileDao
    abstract fun dailyLogDao(): DailyLogDao
    abstract fun indianFoodDao(): IndianFoodDao
    abstract fun weightDao(): WeightDao
    abstract fun sleepDao(): SleepDao
}
