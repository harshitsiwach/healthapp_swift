package com.aihealthappoffline.android.services

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.provider.CalendarContract
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Calendar

class CalendarIntegration(private val context: Context) {

    suspend fun addReminderToCalendar(
        title: String,
        description: String,
        startTimeMillis: Long,
        endTimeMillis: Long,
        reminderMinutes: Int = 30
    ): Result<Long> = withContext(Dispatchers.IO) {
        try {
            val calId = getPrimaryCalendarId()
            if (calId == null) {
                return@withContext Result.failure(Exception("No calendar found"))
            }

            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DESCRIPTION, description)
                put(CalendarContract.Events.DTSTART, startTimeMillis)
                put(CalendarContract.Events.DTEND, endTimeMillis)
                put(CalendarContract.Events.EVENT_TIMEZONE, java.util.TimeZone.getDefault().id)
            }

            val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            if (uri != null) {
                val eventId = ContentUris.parseId(uri)
                addReminder(eventId, reminderMinutes)
                Result.success(eventId)
            } else {
                Result.failure(Exception("Failed to create event"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun addDailyLogToCalendar(
        date: String,
        totalCalories: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double
    ): Result<Long> = withContext(Dispatchers.IO) {
        try {
            val calId = getPrimaryCalendarId() ?: return@withContext Result.failure(Exception("No calendar"))
            
            val title = "Daily Nutrition Log"
            val description = "Calories: $totalCalories | Protein: ${proteinGrams.toInt()}g | Carbs: ${carbsGrams.toInt()}g | Fat: ${fatGrams.toInt()}g"

            val dateParts = date.split("-")
            val calendar = Calendar.getInstance().apply {
                set(dateParts[0].toInt(), dateParts[1].toInt() - 1, dateParts[2].toInt(), 8, 0)
            }
            val startMillis = calendar.timeInMillis
            val endMillis = startMillis + 60 * 60 * 1000

            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DESCRIPTION, description)
                put(CalendarContract.Events.DTSTART, startMillis)
                put(CalendarContract.Events.DTEND, endMillis)
                put(CalendarContract.Events.EVENT_TIMEZONE, java.util.TimeZone.getDefault().id)
                put(CalendarContract.Events.ALL_DAY, 1)
            }

            val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            if (uri != null) {
                Result.success(ContentUris.parseId(uri))
            } else {
                Result.failure(Exception("Failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun addHydrationReminder(intervalHours: Int = 2): Result<Long> = withContext(Dispatchers.IO) {
        try {
            val calId = getPrimaryCalendarId() ?: return@withContext Result.failure(Exception("No calendar"))
            
            val title = "Hydration Reminder"
            val description = "Time to drink water!"

            val startCal = Calendar.getInstance().apply {
                add(Calendar.HOUR_OF_DAY, 1)
            }
            val endCal = Calendar.getInstance().apply {
                add(Calendar.HOUR_OF_DAY, 2)
            }

            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DESCRIPTION, description)
                put(CalendarContract.Events.DTSTART, startCal.timeInMillis)
                put(CalendarContract.Events.DTEND, endCal.timeInMillis)
                put(CalendarContract.Events.EVENT_TIMEZONE, java.util.TimeZone.getDefault().id)
                put(CalendarContract.Events.RRULE, "FREQ=HOURLY;INTERVAL=$intervalHours")
            }

            val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            if (uri != null) {
                Result.success(ContentUris.parseId(uri))
            } else {
                Result.failure(Exception("Failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun getPrimaryCalendarId(): Long? {
        val projection = arrayOf(CalendarContract.Calendars._ID)

        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            "${CalendarContract.Calendars.IS_PRIMARY} = 1",
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(0)
            }
        }

        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            arrayOf(CalendarContract.Calendars._ID),
            null,
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(0)
            }
        }

        return null
    }

    private fun addReminder(eventId: Long, minutes: Int) {
        val values = ContentValues().apply {
            put(CalendarContract.Reminders.EVENT_ID, eventId)
            put(CalendarContract.Reminders.MINUTES, minutes)
            put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
        }
        context.contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, values)
    }
}