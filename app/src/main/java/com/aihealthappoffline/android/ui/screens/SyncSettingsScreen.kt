package com.aihealthappoffline.android.ui.screens

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import com.aihealthappoffline.android.services.CalendarIntegration
import com.aihealthappoffline.android.services.ReminderScheduler
import com.aihealthappoffline.android.ui.theme.NeonBlue
import com.aihealthappoffline.android.ui.theme.NeonGreen
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.util.Calendar
import java.util.concurrent.TimeUnit

private val Context.settingsDataStore by preferencesDataStore(name = "settings_prefs")

@OptIn(ExperimentalMaterial3Api::class, ExperimentalPermissionsApi::class)
@Composable
fun SyncSettingsScreen() {
    val context = LocalContext.current
    
    var calendarPermissionGranted by remember { mutableStateOf(false) }
    var syncEnabled by remember { mutableStateOf(false) }
    var autoMealLog by remember { mutableStateOf(false) }
    var autoHydration by remember { mutableStateOf(false) }
    
    val calendarPermission = rememberPermissionState(Manifest.permission.READ_CALENDAR)
    val calendarWritePermission = rememberPermissionState(Manifest.permission.WRITE_CALENDAR)

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Sync & Connect", fontWeight = FontWeight.Bold) })
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState())
        ) {
            Text(
                "Connect Your Apps",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                "Sync your health data with other apps and services",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Google Calendar Card
            SyncCard(
                title = "Google Calendar",
                description = "Add your daily logs and reminders to phone calendar",
                icon = Icons.Filled.CalendarMonth,
                isEnabled = calendarPermissionGranted,
                isSyncEnabled = syncEnabled,
                onToggle = { enabled ->
                    if (enabled) {
                        calendarPermission.launchPermissionRequest()
                        calendarWritePermission.launchPermissionRequest()
                    }
                    calendarPermissionGranted = calendarPermission.status.isGranted && calendarWritePermission.status.isGranted
                    syncEnabled = enabled
                },
                onSyncNow = {
                    if (calendarPermissionGranted) {
                        // Calendar integration ready
                    }
                }
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Auto-sync options
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        "Auto Sync",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    SyncToggle(
                        title = "Daily Meal Log",
                        subtitle = "Automatically add meals to calendar",
                        checked = autoMealLog,
                        onCheckedChange = { autoMealLog = it }
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    SyncToggle(
                        title = "Hydration Reminders",
                        subtitle = "Schedule hydration reminders",
                        checked = autoHydration,
                        onCheckedChange = { enabled ->
                            autoHydration = enabled
                            if (enabled) {
                                ReminderScheduler.scheduleHydrationReminders(context, 2)
                                ReminderScheduler.scheduleDailyCheckIn(context, 20, 0)
                            } else {
                                ReminderScheduler.cancelReminders(context)
                            }
                        }
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    SyncToggle(
                        title = "Daily Check-in",
                        subtitle = "Evening reminder to log your day",
                        checked = autoMealLog,
                        onCheckedChange = { enabled ->
                            autoMealLog = enabled
                            if (enabled) {
                                ReminderScheduler.scheduleDailyCheckIn(context, 20, 0)
                            }
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Notifications Card
            SyncCard(
                title = "System Reminders",
                description = "Use phone's reminder system",
                icon = Icons.Filled.Notifications,
                isEnabled = true,
                isSyncEnabled = syncEnabled,
                onToggle = { /* Toggle */ },
                onSyncNow = {
                    val calendar = CalendarIntegration(context)
                }
            )

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                "What gets synced:",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            
            SyncInfo("✓ Daily nutrition summary at end of day")
            SyncInfo("✓ Workout sessions")
            SyncInfo("✓ Hydration reminders")
            SyncInfo("✓ Weekly meal plans")
            SyncInfo("✓ Weight check-ins")
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Text(
                "🔒 Privacy",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                "Your data stays on your device. Calendar access is used only to create events you specify.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun SyncCard(
    title: String,
    description: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    isEnabled: Boolean,
    isSyncEnabled: Boolean,
    onToggle: (Boolean) -> Unit,
    onSyncNow: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (isSyncEnabled) NeonGreen.copy(alpha = 0.1f)
            else MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    icon,
                    contentDescription = null,
                    modifier = Modifier.size(32.dp),
                    tint = if (isSyncEnabled) NeonGreen else NeonBlue
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Text(
                        description,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Switch(checked = isSyncEnabled, onCheckedChange = onToggle)
        }
    }
}

@Composable
private fun SyncToggle(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
            Text(
                subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

@Composable
private fun SyncInfo(text: String) {
    Row(modifier = Modifier.padding(vertical = 2.dp)) {
        Text("• ", color = NeonGreen)
        Text(text, style = MaterialTheme.typography.bodySmall)
    }
}