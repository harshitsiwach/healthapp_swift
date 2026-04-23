package com.aihealthappoffline.android.ui.screens

import android.app.Activity
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.MonitorWeight
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.aihealthappoffline.android.ui.theme.CarbsColor
import com.aihealthappoffline.android.ui.theme.FatColor
import com.aihealthappoffline.android.ui.theme.NeonBlue
import com.aihealthappoffline.android.ui.theme.NeonGreen
import com.aihealthappoffline.android.ui.theme.NeonOrange
import com.aihealthappoffline.android.ui.theme.NeonPurple
import com.aihealthappoffline.android.ui.theme.ProteinColor
import com.aihealthappoffline.android.viewmodels.DashboardViewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun DashboardScreen(
    externalViewModel: DashboardViewModel? = null,
    onFabClick: () -> Unit = {},
    onNavigateToWeight: (() -> Unit)? = null,
    onNavigateToSleep: (() -> Unit)? = null
) {
    val viewModel = externalViewModel ?: viewModel<DashboardViewModel>()
    val profile by viewModel.profile.collectAsState()
    val totals by viewModel.todayTotals.collectAsState()
    val hydration by viewModel.hydration.collectAsState()
    val steps by viewModel.steps.collectAsState()
    val caloriesBurned by viewModel.caloriesBurned.collectAsState()
    val distanceKm by viewModel.distanceKm.collectAsState()
    val googleFitConnected by viewModel.googleFitConnected.collectAsState()

    val context = LocalContext.current
    val activity = context as? Activity

    val profileData = profile
    val calorieGoal = profileData?.calculatedDailyCalories ?: 2000
    val proteinGoal = profileData?.calculatedDailyProtein?.toDouble() ?: 120.0
    val carbsGoal = profileData?.calculatedDailyCarbs?.toDouble() ?: 250.0
    val fatGoal = profileData?.calculatedDailyFats?.toDouble() ?: 65.0
    val hydrationGoal by viewModel.hydrationGoal.collectAsState()

    val scrollState = rememberScrollState()

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = onFabClick,
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                shape = CircleShape
            ) {
                Icon(Icons.Filled.Add, contentDescription = "Quick Log")
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(padding)
                .padding(horizontal = 16.dp)
        ) {
            Spacer(modifier = Modifier.height(16.dp))

            // Date header
            Text(
                text = SimpleDateFormat("EEEE, d MMMM", Locale.getDefault()).format(Date()),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Dashboard",
                style = MaterialTheme.typography.headlineLarge,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(20.dp))

            // Calories card
            CalorieCard(
                consumed = totals?.calories ?: 0,
                goal = calorieGoal,
                remaining = calorieGoal - (totals?.calories ?: 0)
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Macro row
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                MacroPill(label = "Protein", value = totals?.protein ?: 0.0, goal = proteinGoal, color = ProteinColor)
                MacroPill(label = "Carbs", value = totals?.carbs ?: 0.0, goal = carbsGoal, color = CarbsColor)
                MacroPill(label = "Fat", value = totals?.fat ?: 0.0, goal = fatGoal, color = FatColor)
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Hydration card
            HydrationCard(current = hydration, goal = hydrationGoal) {
                viewModel.addWater(250)
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Activity section
            if (!googleFitConnected) {
                GoogleFitConnectCard {
                    val intent = viewModel.getGoogleFitSignInIntent()
                    activity?.startActivityForResult(intent, GOOGLE_FIT_REQUEST_CODE)
                }
            } else {
                ActivityCard(
                    steps = steps,
                    caloriesBurned = caloriesBurned,
                    distanceKm = distanceKm
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Health score
            HealthScoreCard(score = profileData?.healthScore ?: 75)

            Spacer(modifier = Modifier.height(16.dp))

            // Quick access cards
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                QuickAccessCard(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Filled.MonitorWeight,
                    label = "Weight",
                    onClick = { onNavigateToWeight?.invoke() }
                )
                QuickAccessCard(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Filled.Bedtime,
                    label = "Sleep",
                    onClick = { onNavigateToSleep?.invoke() }
                )
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
private fun QuickAccessCard(
    modifier: Modifier = Modifier,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: (() -> Unit)?
) {
    Card(
        modifier = modifier
            .height(80.dp)
            .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = NeonOrange,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                label,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

const val GOOGLE_FIT_REQUEST_CODE = 1001

@Composable
fun CalorieCard(consumed: Int, goal: Int, remaining: Int) {
    val progress = (consumed.toFloat() / goal.coerceAtLeast(1)).coerceIn(0f, 1f)
    val animatedProgress = remember { Animatable(0f) }
    LaunchedEffect(progress) { animatedProgress.animateTo(progress, animationSpec = tween(800)) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.LocalFireDepartment,
                    contentDescription = null,
                    tint = NeonOrange,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Calories", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = "$consumed / $goal kcal",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "$remaining remaining",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(12.dp))
            LinearProgressIndicator(
                progress = { animatedProgress.value },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp)),
                color = if (progress > 1f) Color(0xFFFF5252) else NeonGreen,
                trackColor = MaterialTheme.colorScheme.outlineVariant
            )
        }
    }
}

@Composable
fun MacroPill(label: String, value: Double, goal: Double, color: Color) {
    val pct = ((value / goal.coerceAtLeast(1.0)) * 100).toInt().coerceAtMost(999)
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier = Modifier
                .size(64.dp)
                .clip(CircleShape)
                .background(color.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "${value.toInt()}g",
                style = MaterialTheme.typography.labelLarge,
                color = color,
                fontWeight = FontWeight.Bold
            )
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text("$pct%", style = MaterialTheme.typography.labelSmall, color = color)
    }
}

@Composable
fun HydrationCard(current: Int, goal: Int, onAdd: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(20.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Filled.WaterDrop,
                        contentDescription = null,
                        tint = NeonBlue,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Hydration", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text("$current / $goal ml", style = MaterialTheme.typography.headlineSmall, color = MaterialTheme.colorScheme.onBackground, fontWeight = FontWeight.Bold)
            }
            FloatingActionButton(
                onClick = onAdd,
                modifier = Modifier.size(48.dp),
                containerColor = NeonBlue.copy(alpha = 0.2f),
                contentColor = NeonBlue,
                shape = CircleShape
            ) {
                Icon(Icons.Filled.Add, contentDescription = "Add water")
            }
        }
    }
}

@Composable
fun GoogleFitConnectCard(onConnect: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onConnect() },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(20.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text("Connect Google Fit", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.height(4.dp))
                Text("Sync steps, calories & distance", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(NeonGreen.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Filled.DirectionsRun,
                    contentDescription = null,
                    tint = NeonGreen,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}

@Composable
fun ActivityCard(steps: Int, caloriesBurned: Int, distanceKm: Float) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Text("Activity", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(12.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                ActivityMetric(
                    icon = Icons.Filled.DirectionsRun,
                    value = "$steps",
                    label = "Steps",
                    color = NeonGreen
                )
                ActivityMetric(
                    icon = Icons.Filled.LocalFireDepartment,
                    value = "$caloriesBurned",
                    label = "Burned",
                    color = NeonOrange
                )
                ActivityMetric(
                    icon = null,
                    value = String.format("%.1f", distanceKm),
                    label = "km",
                    color = NeonBlue
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            LinearProgressIndicator(
                progress = { (steps / 10000f).coerceIn(0f, 1f) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp)),
                color = NeonGreen,
                trackColor = MaterialTheme.colorScheme.outlineVariant
            )
        }
    }
}

@Composable
fun ActivityMetric(
    icon: androidx.compose.ui.graphics.vector.ImageVector?,
    value: String,
    label: String,
    color: Color
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        if (icon != null) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(20.dp))
            Spacer(modifier = Modifier.height(4.dp))
        }
        Text(value, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground, fontWeight = FontWeight.Bold)
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
fun HealthScoreCard(score: Int) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(20.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text("Health Score", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    "$score/100",
                    style = MaterialTheme.typography.headlineSmall,
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold
                )
            }
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(
                        when {
                            score >= 80 -> NeonGreen.copy(alpha = 0.2f)
                            score >= 50 -> NeonOrange.copy(alpha = 0.2f)
                            else -> Color(0xFFFF5252).copy(alpha = 0.2f)
                        }
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "$score",
                    style = MaterialTheme.typography.titleLarge,
                    color = when {
                        score >= 80 -> NeonGreen
                        score >= 50 -> NeonOrange
                        else -> Color(0xFFFF5252)
                    },
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
