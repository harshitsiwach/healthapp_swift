package com.aihealthappoffline.android.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.aihealthappoffline.android.data.models.DailyLog
import kotlinx.coroutines.flow.Flow

@Dao
interface DailyLogDao {
    @Query("SELECT * FROM daily_logs WHERE date = :date ORDER BY timestamp DESC")
    fun getLogsForDate(date: String): Flow<List<DailyLog>>

    @Query("SELECT * FROM daily_logs WHERE date = :date ORDER BY timestamp DESC")
    suspend fun getLogsForDateOnce(date: String): List<DailyLog>

    @Query("SELECT SUM(estimatedCalories) FROM daily_logs WHERE date = :date")
    suspend fun getTotalCaloriesForDate(date: String): Int?

    @Query("SELECT SUM(proteinG) FROM daily_logs WHERE date = :date")
    suspend fun getTotalProteinForDate(date: String): Double?

    @Query("SELECT SUM(carbsG) FROM daily_logs WHERE date = :date")
    suspend fun getTotalCarbsForDate(date: String): Double?

    @Query("SELECT SUM(fatG) FROM daily_logs WHERE date = :date")
    suspend fun getTotalFatForDate(date: String): Double?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(log: DailyLog)

    @Update
    suspend fun update(log: DailyLog)

    @Delete
    suspend fun delete(log: DailyLog)

    @Query("DELETE FROM daily_logs WHERE id = :id")
    suspend fun deleteById(id: String)
}
