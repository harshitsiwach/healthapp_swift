package com.aihealthappoffline.android.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.aihealthappoffline.android.data.models.SleepEntry
import kotlinx.coroutines.flow.Flow

@Dao
interface SleepDao {
    @Query("SELECT * FROM sleep_entries ORDER BY date DESC")
    fun getAllSleepEntries(): Flow<List<SleepEntry>>

    @Query("SELECT * FROM sleep_entries ORDER BY date DESC LIMIT :limit")
    fun getRecentSleepEntries(limit: Int): Flow<List<SleepEntry>>

    @Query("SELECT * FROM sleep_entries WHERE date = :date LIMIT 1")
    suspend fun getSleepForDate(date: String): SleepEntry?

    @Query("SELECT AVG(hoursSlept) FROM sleep_entries WHERE date >= :startDate")
    suspend fun getAverageSleepSince(startDate: String): Float?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entry: SleepEntry): Long

    @Delete
    suspend fun delete(entry: SleepEntry)

    @Query("DELETE FROM sleep_entries WHERE id = :id")
    suspend fun deleteById(id: Long)
}