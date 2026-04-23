package com.aihealthappoffline.android.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.aihealthappoffline.android.data.models.FamilyProfile
import kotlinx.coroutines.flow.Flow

@Dao
interface FamilyProfileDao {
    @Query("SELECT * FROM family_profiles ORDER BY name ASC")
    fun getAllProfiles(): Flow<List<FamilyProfile>>

    @Query("SELECT * FROM family_profiles WHERE isActive = 1 ORDER BY name ASC")
    fun getActiveProfiles(): Flow<List<FamilyProfile>>

    @Query("SELECT * FROM family_profiles WHERE id = :id")
    suspend fun getProfileById(id: Long): FamilyProfile?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(profile: FamilyProfile): Long

    @Update
    suspend fun update(profile: FamilyProfile)

    @Delete
    suspend fun delete(profile: FamilyProfile)

    @Query("DELETE FROM family_profiles WHERE id = :id")
    suspend fun deleteById(id: Long)

    @Query("SELECT COUNT(*) FROM family_profiles")
    suspend fun getCount(): Int
}