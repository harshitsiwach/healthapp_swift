package com.aihealthappoffline.android.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.aihealthappoffline.android.MainActivity
import com.aihealthappoffline.android.R
import com.aihealthappoffline.android.data.local.HydrationDataStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

class HydrationReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val store = HydrationDataStore(context)
        val current = runBlocking { store.hydrationFlow.first() }
        val goal = runBlocking { store.goalFlow.first() }
        
        val remaining = goal - current
        val message = if (remaining > 0) "${remaining}ml to reach your daily goal!" else "Great job! Goal reached for today!"
        
        showNotification(context, "💧 Hydration Time!", message)
    }

    private fun showNotification(context: Context, title: String, message: String) {
        val channelId = "hydration_reminders"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Hydration Reminders", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Reminders to drink water"
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

        notificationManager.notify(1001, notification)
    }
}
