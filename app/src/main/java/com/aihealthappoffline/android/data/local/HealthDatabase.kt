package com.aihealthappoffline.android.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.aihealthappoffline.android.data.models.DailyLog
import com.aihealthappoffline.android.data.models.FamilyProfile
import com.aihealthappoffline.android.data.models.IndianFoodItem
import com.aihealthappoffline.android.data.models.PeriodEntry
import com.aihealthappoffline.android.data.models.SleepEntry
import com.aihealthappoffline.android.data.models.UserProfile
import com.aihealthappoffline.android.data.models.WeightEntry

@Database(
    entities = [UserProfile::class, DailyLog::class, IndianFoodItem::class, WeightEntry::class, SleepEntry::class, FamilyProfile::class, PeriodEntry::class],
    version = 3,
    exportSchema = false
)
abstract class HealthDatabase : RoomDatabase() {
    abstract fun userProfileDao(): UserProfileDao
    abstract fun dailyLogDao(): DailyLogDao
    abstract fun indianFoodDao(): IndianFoodDao
    abstract fun weightDao(): WeightDao
    abstract fun sleepDao(): SleepDao
    abstract fun familyProfileDao(): FamilyProfileDao
    abstract fun periodEntryDao(): PeriodEntryDao
}
