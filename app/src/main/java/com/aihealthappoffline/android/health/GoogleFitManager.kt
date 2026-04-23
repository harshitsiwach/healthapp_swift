package com.aihealthappoffline.android.health

import android.content.Context
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.fitness.Fitness
import com.google.android.gms.fitness.FitnessOptions
import com.google.android.gms.fitness.data.DataType
import com.google.android.gms.fitness.data.Field
import com.google.android.gms.fitness.request.DataReadRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.util.Calendar
import java.util.concurrent.TimeUnit

class GoogleFitManager(private val context: Context) {

    val fitnessOptions: FitnessOptions by lazy {
        FitnessOptions.builder()
            .addDataType(DataType.TYPE_STEP_COUNT_DELTA, FitnessOptions.ACCESS_READ)
            .addDataType(DataType.TYPE_CALORIES_EXPENDED, FitnessOptions.ACCESS_READ)
            .addDataType(DataType.TYPE_DISTANCE_DELTA, FitnessOptions.ACCESS_READ)
            .addDataType(DataType.TYPE_HEART_RATE_BPM, FitnessOptions.ACCESS_READ)
            .build()
    }

    fun hasPermissions(): Boolean {
        val account = GoogleSignIn.getLastSignedInAccount(context) ?: return false
        return GoogleSignIn.hasPermissions(account, fitnessOptions)
    }

    suspend fun getTodaySteps(): Int = withContext(Dispatchers.IO) {
        try {
            val account = GoogleSignIn.getLastSignedInAccount(context) ?: return@withContext 0
            val endTime = Calendar.getInstance().timeInMillis
            val startTime = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis

            val request = DataReadRequest.Builder()
                .aggregate(DataType.TYPE_STEP_COUNT_DELTA, DataType.AGGREGATE_STEP_COUNT_DELTA)
                .setTimeRange(startTime, endTime, TimeUnit.MILLISECONDS)
                .build()

            val response = Fitness.getHistoryClient(context, account).readData(request).await()
            val dataSet = response.getDataSet(DataType.AGGREGATE_STEP_COUNT_DELTA)

            var totalSteps = 0
            for (dp in dataSet.dataPoints) {
                totalSteps += dp.getValue(Field.FIELD_STEPS).asInt()
            }
            totalSteps
        } catch (e: Exception) {
            0
        }
    }

    suspend fun getTodayCaloriesBurned(): Int = withContext(Dispatchers.IO) {
        try {
            val account = GoogleSignIn.getLastSignedInAccount(context) ?: return@withContext 0
            val endTime = Calendar.getInstance().timeInMillis
            val startTime = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis

            val request = DataReadRequest.Builder()
                .aggregate(DataType.TYPE_CALORIES_EXPENDED, DataType.AGGREGATE_CALORIES_EXPENDED)
                .setTimeRange(startTime, endTime, TimeUnit.MILLISECONDS)
                .build()

            val response = Fitness.getHistoryClient(context, account).readData(request).await()
            val dataSet = response.getDataSet(DataType.AGGREGATE_CALORIES_EXPENDED)

            var totalCals = 0.0
            for (dp in dataSet.dataPoints) {
                totalCals += dp.getValue(Field.FIELD_CALORIES).asFloat()
            }
            totalCals.toInt()
        } catch (e: Exception) {
            0
        }
    }

    suspend fun getTodayDistance(): Float = withContext(Dispatchers.IO) {
        try {
            val account = GoogleSignIn.getLastSignedInAccount(context) ?: return@withContext 0f
            val endTime = Calendar.getInstance().timeInMillis
            val startTime = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis

            val request = DataReadRequest.Builder()
                .aggregate(DataType.TYPE_DISTANCE_DELTA, DataType.AGGREGATE_DISTANCE_DELTA)
                .setTimeRange(startTime, endTime, TimeUnit.MILLISECONDS)
                .build()

            val response = Fitness.getHistoryClient(context, account).readData(request).await()
            val dataSet = response.getDataSet(DataType.AGGREGATE_DISTANCE_DELTA)

            var totalDist = 0f
            for (dp in dataSet.dataPoints) {
                totalDist += dp.getValue(Field.FIELD_DISTANCE).asFloat()
            }
            totalDist / 1000f // convert to km
        } catch (e: Exception) {
            0f
        }
    }
}
