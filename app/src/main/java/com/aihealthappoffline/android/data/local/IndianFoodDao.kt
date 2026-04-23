package com.aihealthappoffline.android.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.aihealthappoffline.android.data.models.IndianFoodItem
import kotlinx.coroutines.flow.Flow

@Dao
interface IndianFoodDao {
    @Query("SELECT * FROM indian_food_db WHERE name LIKE '%' || :query || '%' OR nameHindi LIKE '%' || :query || '%' OR tags LIKE '%' || :query || '%' LIMIT 50")
    fun searchFood(query: String): Flow<List<IndianFoodItem>>

    @Query("SELECT * FROM indian_food_db WHERE category = :category LIMIT 20")
    fun getByCategory(category: String): Flow<List<IndianFoodItem>>

    @Query("SELECT * FROM indian_food_db LIMIT 50")
    fun getAll(): Flow<List<IndianFoodItem>>

    @Query("SELECT * FROM indian_food_db WHERE isVegetarian = 1 LIMIT 30")
    fun getVegetarianItems(): Flow<List<IndianFoodItem>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(items: List<IndianFoodItem>)

    @Query("SELECT COUNT(*) FROM indian_food_db")
    suspend fun getCount(): Int
}
