package com.aihealthappoffline.android

import android.app.Application
import androidx.room.Room
import com.aihealthappoffline.android.data.local.HealthDatabase

class HealthAppApplication : Application() {
    companion object {
        lateinit var database: HealthDatabase
            private set
    }

    override fun onCreate() {
        super.onCreate()
        database = Room.databaseBuilder(
            applicationContext,
            HealthDatabase::class.java,
            "health_database"
        )
            .fallbackToDestructiveMigration()
            .build()
    }
}
