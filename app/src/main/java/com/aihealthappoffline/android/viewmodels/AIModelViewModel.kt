package com.aihealthappoffline.android.viewmodels

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.ai.AIModel
import com.aihealthappoffline.android.ai.LocalAIManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class AIModelViewModel(application: Application) : AndroidViewModel(application) {

    private val aiManager = LocalAIManager(application)

    private val _availableModels = MutableStateFlow<List<AIModel>>(LocalAIManager.availableModels)
    val availableModels: StateFlow<List<AIModel>> = _availableModels.asStateFlow()

    private val _downloadedModels = MutableStateFlow<List<AIModel>>(emptyList())
    val downloadedModels: StateFlow<List<AIModel>> = _downloadedModels.asStateFlow()

    private val _selectedModel = MutableStateFlow<AIModel?>(null)
    val selectedModel: StateFlow<AIModel?> = _selectedModel.asStateFlow()

    private val _downloadingModelId = MutableStateFlow<String?>(null)
    val downloadingModelId: StateFlow<String?> = _downloadingModelId.asStateFlow()

    private val _downloadProgress = MutableStateFlow(0)
    val downloadProgress: StateFlow<Int> = _downloadProgress.asStateFlow()

    init {
        loadModels()
    }

    private fun loadModels() {
        viewModelScope.launch {
            _downloadedModels.value = aiManager.getDownloadedModels()
            _selectedModel.value = aiManager.getCurrentModel()
        }
    }

    fun downloadModel(model: AIModel) {
        if (_downloadingModelId.value != null) return

        viewModelScope.launch {
            _downloadingModelId.value = model.id
            _downloadProgress.value = 0

            val result = aiManager.downloadModel(model) { progress ->
                _downloadProgress.value = progress
            }

            result.onSuccess {
                _downloadedModels.value = aiManager.getDownloadedModels()
            }

            _downloadingModelId.value = null
            _downloadProgress.value = 0
        }
    }

    fun selectModel(model: AIModel) {
        viewModelScope.launch {
            aiManager.setCurrentModel(model.id)
            _selectedModel.value = model.copy(isDownloaded = true)
        }
    }

    fun deleteModel(model: AIModel) {
        viewModelScope.launch {
            aiManager.deleteModel(model.id)
            _downloadedModels.value = aiManager.getDownloadedModels()

            if (_selectedModel.value?.id == model.id) {
                _selectedModel.value = null
                aiManager.setCurrentModel("")
            }
        }
    }
}