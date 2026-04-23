package com.aihealthappoffline.android.services

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.aihealthappoffline.android.MainActivity
import com.aihealthappoffline.android.R
import com.aihealthappoffline.android.data.local.HydrationDataStore
import kotlinx.coroutines.flow.first
import java.util.Calendar
import java.util.concurrent.TimeUnit

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val type = intent.getStringExtra("type") ?: "hydration"
        val title = intent.getStringExtra("title") ?: "Health Reminder"
        val message = intent.getStringExtra("message") ?: "Time to take action!"

        showNotification(context, type, title, message)
    }

    private fun showNotification(context: Context, type: String, title: String, message: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "${type}_reminders"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, type.replaceFirstChar { it.uppercase() }, NotificationManager.IMPORTANCE_HIGH)
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(type.hashCode(), notification)
    }
}

object ReminderScheduler {
    private const val HYDRATION_WORK = "hydration_reminder"
    private const val DAILY_CHECK_REQUEST = 2001
    private const val HYDRATION_REQUEST = 2002

    fun scheduleHydrationReminders(context: Context, intervalHours: Int = 2) {
        val request = PeriodicWorkRequestBuilder<HydrationWorker>(intervalHours.toLong(), TimeUnit.HOURS).build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(HYDRATION_WORK, ExistingPeriodicWorkPolicy.UPDATE, request)
        
        scheduleExactHydration(context, intervalHours)
    }
    
    private fun scheduleExactHydration(context: Context, intervalHours: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, HydrationReminderReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(context, HYDRATION_REQUEST, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        
        val triggerTime = System.currentTimeMillis() + (intervalHours * 60 * 60 * 1000L)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            }
        } else {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
        }
    }

    fun scheduleDailyCheckIn(context: Context, hour: Int = 20, minute: Int = 0) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, DailyCheckReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(context, DAILY_CHECK_REQUEST, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        
        val calendar = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_MONTH, 1)
            }
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
            }
        } else {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
        }
    }

    fun cancelReminders(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(HYDRATION_WORK)
        
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val hydrationIntent = Intent(context, HydrationReminderReceiver::class.java)
        val dailyIntent = Intent(context, DailyCheckReceiver::class.java)
        
        alarmManager.cancel(PendingIntent.getBroadcast(context, HYDRATION_REQUEST, hydrationIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        alarmManager.cancel(PendingIntent.getBroadcast(context, DAILY_CHECK_REQUEST, dailyIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
    }
}

class HydrationWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val store = HydrationDataStore(applicationContext)
        val current = store.hydrationFlow.first()
        val goal = store.goalFlow.first()

        if (goal - current > 500) {
            val intent = Intent(applicationContext, ReminderReceiver::class.java).apply {
                putExtra("type", "hydration")
                putExtra("title", "💧 Time to Hydrate!")
                putExtra("message", "${goal - current}ml remaining")
            }
            applicationContext.sendBroadcast(intent)
        }
        return Result.success()
    }
}