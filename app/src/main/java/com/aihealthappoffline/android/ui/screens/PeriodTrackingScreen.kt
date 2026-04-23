package com.aihealthappoffline.android.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.aihealthappoffline.android.data.models.PeriodEntry
import com.aihealthappoffline.android.ui.theme.NeonOrange
import com.aihealthappoffline.android.ui.theme.NeonPurple
import com.aihealthappoffline.android.ui.theme.NeonRed
import com.aihealthappoffline.android.viewmodels.PeriodTrackingViewModel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PeriodTrackingScreen(viewModel: PeriodTrackingViewModel = viewModel()) {
    val entries by viewModel.entries.collectAsState()
    var showDialog by remember { mutableStateOf(false) }
    var flowLevel by remember { mutableFloatStateOf(1f) }
    var selectedSymptoms by remember { mutableStateOf("") }

    val symptoms = listOf("Cramps", "Headache", "Bloating", "Fatigue", "Mood", "Acne", "Breast tenderness")
    val flowLabels = listOf("None", "Light", "Medium", "Heavy")

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Period Tracking", fontWeight = FontWeight.Bold) })
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showDialog = true },
                containerColor = NeonRed
            ) {
                Icon(Icons.Filled.Add, contentDescription = "Log period", tint = MaterialTheme.colorScheme.onPrimary)
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
        ) {
            item {
                if (entries.isNotEmpty()) {
                    val lastEntry = entries.first()
                    val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
                    
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = NeonRed.copy(alpha = 0.15f)),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    Icons.Filled.Favorite,
                                    contentDescription = null,
                                    tint = NeonRed,
                                    modifier = Modifier.size(24.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Last Period", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(lastEntry.startDate, style = MaterialTheme.typography.headlineSmall)
                            Text("Flow: ${flowLabels.getOrElse(lastEntry.flowLevel) { "Unknown" }}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                } else {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                        shape = RoundedCornerShape(16.dp)
                    ) {
                        Column(modifier = Modifier.padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                Icons.Filled.Favorite,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = NeonPurple
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text("Track your cycles", style = MaterialTheme.typography.titleMedium)
                            Text("Log your first period to get started", color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                }
            }

            items(entries.take(12)) { entry ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(entry.startDate, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            Text(
                                "Flow: ${flowLabels.getOrElse(entry.flowLevel) { "Unknown" }}",
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            entry.symptoms?.let {
                                Text(it, style = MaterialTheme.typography.bodySmall, color = NeonOrange)
                            }
                        }
                        FlowIndicator(level = entry.flowLevel)
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }

    if (showDialog) {
        AlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text("Log Period") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text("Flow Level:", fontWeight = FontWeight.Medium)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        flowLabels.forEachIndexed { index, label ->
                            FilterChip(
                                selected = flowLevel.toInt() == index,
                                onClick = { flowLevel = index.toFloat() },
                                label = { Text(label, style = MaterialTheme.typography.bodySmall) },
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = when (index) {
                                        0 -> MaterialTheme.colorScheme.surfaceVariant
                                        1 -> NeonOrange.copy(alpha = 0.3f)
                                        2 -> NeonOrange
                                        else -> NeonRed
                                    }
                                )
                            )
                        }
                    }

                    Text("Symptoms:", fontWeight = FontWeight.Medium)
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        symptoms.take(4).forEach { symptom ->
                            val isSelected = selectedSymptoms.contains(symptom)
                            FilterChip(
                                selected = isSelected,
                                onClick = {
                                    selectedSymptoms = if (isSelected) {
                                        selectedSymptoms.replace("$symptom,", "").replace(symptom, "")
                                    } else {
                                        "$selectedSymptoms$symptom,"
                                    }
                                },
                                label = { Text(symptom, style = MaterialTheme.typography.bodySmall) }
                            )
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.addEntry(
                            flowLevel = flowLevel.toInt(),
                            symptoms = selectedSymptoms.takeIf { it.isNotBlank() }
                        )
                        showDialog = false
                    }
                ) { Text("Log") }
            },
            dismissButton = {
                TextButton(onClick = { showDialog = false }) { Text("Cancel") }
            }
        )
    }
}

@Composable
private fun FlowIndicator(level: Int) {
    val color = when (level) {
        0 -> NeonPurple.copy(alpha = 0.3f)
        1 -> NeonOrange.copy(alpha = 0.5f)
        2 -> NeonOrange
        else -> NeonRed
    }
    Box(
        modifier = Modifier
            .size(16.dp)
            .clip(CircleShape)
            .background(color)
    )
}