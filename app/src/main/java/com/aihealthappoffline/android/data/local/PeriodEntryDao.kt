package com.aihealthappoffline.android.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.aihealthappoffline.android.data.models.PeriodEntry
import kotlinx.coroutines.flow.Flow

@Dao
interface PeriodEntryDao {
    @Query("SELECT * FROM period_entries ORDER BY startDate DESC")
    fun getAllEntries(): Flow<List<PeriodEntry>>

    @Query("SELECT * FROM period_entries ORDER BY startDate DESC LIMIT :limit")
    fun getRecentEntries(limit: Int): Flow<List<PeriodEntry>>

    @Query("SELECT * FROM period_entries WHERE startDate >= :startDate AND startDate <= :endDate ORDER BY startDate DESC")
    fun getEntriesInRange(startDate: String, endDate: String): Flow<List<PeriodEntry>>

    @Query("SELECT * FROM period_entries WHERE id = :id")
    suspend fun getEntryById(id: Long): PeriodEntry?

    @Query("SELECT * FROM period_entries ORDER BY startDate DESC LIMIT 1")
    suspend fun getLatestEntry(): PeriodEntry?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entry: PeriodEntry): Long

    @Update
    suspend fun update(entry: PeriodEntry)

    @Delete
    suspend fun delete(entry: PeriodEntry)

    @Query("DELETE FROM period_entries WHERE id = :id")
    suspend fun deleteById(id: Long)

    @Query("SELECT AVG(flowLevel) FROM period_entries WHERE startDate >= :startDate")
    suspend fun getAverageFlowSince(startDate: String): Float?
}