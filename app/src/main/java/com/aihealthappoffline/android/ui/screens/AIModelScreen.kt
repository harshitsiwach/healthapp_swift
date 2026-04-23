package com.aihealthappoffline.android.ui.screens

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
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
import com.aihealthappoffline.android.ai.AIModel
import com.aihealthappoffline.android.ai.LocalAIManager
import com.aihealthappoffline.android.ui.theme.NeonBlue
import com.aihealthappoffline.android.ui.theme.NeonGreen
import com.aihealthappoffline.android.ui.theme.NeonOrange
import com.aihealthappoffline.android.ui.theme.NeonPurple
import com.aihealthappoffline.android.viewmodels.AIModelViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AIModelScreen(viewModel: AIModelViewModel = viewModel()) {
    val models by viewModel.availableModels.collectAsState()
    val downloadedModels by viewModel.downloadedModels.collectAsState()
    val selectedModel by viewModel.selectedModel.collectAsState()
    val downloadingId by viewModel.downloadingModelId.collectAsState()
    val downloadProgress by viewModel.downloadProgress.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("AI Models", fontWeight = FontWeight.Bold) }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
        ) {
            item {
                Text(
                    "Local AI Models",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "Download models to use AI entirely offline. No internet needed after download.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                val totalSize = downloadedModels.sumOf { it.sizeMb }
                Text(
                    "Storage: ${totalSize}MB used",
                    style = MaterialTheme.typography.bodySmall,
                    color = NeonOrange
                )
                
                Spacer(modifier = Modifier.height(16.dp))
            }

            item {
                Text(
                    "Available Models",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

            items(models) { model ->
                val isDownloaded = downloadedModels.any { it.id == model.id }
                val isSelected = selectedModel?.id == model.id
                val isDownloading = downloadingId == model.id

                ModelCard(
                    model = model,
                    isDownloaded = isDownloaded,
                    isSelected = isSelected,
                    isDownloading = isDownloading,
                    downloadProgress = if (isDownloading) downloadProgress else 0,
                    onDownload = { viewModel.downloadModel(model) },
                    onSelect = { viewModel.selectModel(model) },
                    onDelete = { viewModel.deleteModel(model) }
                )
                
                Spacer(modifier = Modifier.height(12.dp))
            }

            item {
                Spacer(modifier = Modifier.height(16.dp))
                
                Text(
                    "How it works",
                    style = MaterialTheme.typography.titleMedium
                )
                Spacer(modifier = Modifier.height(8.dp))
                
                val storageInfo = models.sumOf { it.sizeMb }
                Text(
                    "• Models are downloaded once and stored locally\n" +
                    "• Health Assistant is optimized for nutrition advice\n" +
                    "• All inference happens on your device\n" +
                    "• No data leaves your phone\n" +
                    "• Models use ~${storageInfo / 4}MB RAM when active",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun ModelCard(
    model: AIModel,
    isDownloaded: Boolean,
    isSelected: Boolean,
    isDownloading: Boolean,
    downloadProgress: Int,
    onDownload: () -> Unit,
    onSelect: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = when {
                isSelected -> NeonGreen.copy(alpha = 0.15f)
                else -> MaterialTheme.colorScheme.surfaceVariant
            }
        ),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            model.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        if (isSelected) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Icon(
                                Icons.Filled.Check,
                                contentDescription = "Selected",
                                tint = NeonGreen,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }
                    Text(
                        model.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        "${model.sizeMb} MB",
                        style = MaterialTheme.typography.bodySmall,
                        color = NeonOrange
                    )
                }

                when {
                    isDownloading -> {
                        Box(contentAlignment = Alignment.Center) {
                            CircularProgressIndicator(
                                progress = { downloadProgress / 100f },
                                modifier = Modifier.size(48.dp),
                                color = NeonBlue,
                                strokeWidth = 4.dp
                            )
                            Text(
                                "$downloadProgress%",
                                style = MaterialTheme.typography.bodySmall,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                    isDownloaded && !isSelected -> {
                        Row {
                            IconButton(onClick = onSelect) {
                                Icon(
                                    Icons.Filled.Check,
                                    contentDescription = "Select",
                                    tint = NeonGreen
                                )
                            }
                            IconButton(onClick = onDelete) {
                                Icon(
                                    Icons.Filled.Delete,
                                    contentDescription = "Delete",
                                    tint = MaterialTheme.colorScheme.error
                                )
                            }
                        }
                    }
                    isDownloaded && isSelected -> {
                        Box(
                            modifier = Modifier
                                .size(48.dp)
                                .clip(CircleShape)
                                .background(NeonGreen),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                Icons.Filled.Check,
                                contentDescription = "Active",
                                tint = MaterialTheme.colorScheme.onPrimary
                            )
                        }
                    }
                    else -> {
                        IconButton(onClick = onDownload) {
                            Icon(
                                Icons.Filled.Download,
                                contentDescription = "Download",
                                tint = NeonBlue
                            )
                        }
                    }
                }
            }

            if (isDownloading) {
                Spacer(modifier = Modifier.height(12.dp))
                LinearProgressIndicator(
                    progress = { downloadProgress / 100f },
                    modifier = Modifier.fillMaxWidth(),
                    color = NeonBlue,
                    trackColor = MaterialTheme.colorScheme.surfaceVariant
                )
            }
        }
    }
}