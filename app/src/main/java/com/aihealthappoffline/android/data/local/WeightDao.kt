package com.aihealthappoffline.android.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.aihealthappoffline.android.data.models.WeightEntry
import kotlinx.coroutines.flow.Flow

@Dao
interface WeightDao {
    @Query("SELECT * FROM weight_entries ORDER BY date DESC")
    fun getAllWeightEntries(): Flow<List<WeightEntry>>

    @Query("SELECT * FROM weight_entries ORDER BY date DESC LIMIT :limit")
    fun getRecentWeightEntries(limit: Int): Flow<List<WeightEntry>>

    @Query("SELECT * FROM weight_entries WHERE date = :date LIMIT 1")
    suspend fun getWeightForDate(date: String): WeightEntry?

    @Query("SELECT * FROM weight_entries ORDER BY date ASC")
    fun getAllWeightEntriesAsc(): Flow<List<WeightEntry>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entry: WeightEntry): Long

    @Delete
    suspend fun delete(entry: WeightEntry)

    @Query("DELETE FROM weight_entries WHERE id = :id")
    suspend fun deleteById(id: Long)
}