package com.aihealthappoffline.android.ai

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

data class AIModel(
    val id: String,
    val name: String,
    val description: String,
    val sizeMb: Int,
    val downloadUrl: String,
    val isDownloaded: Boolean = false
)

data class AIResponse(
    val text: String,
    val confidence: Float = 0f
)

class LocalAIManager(private val context: Context) {

    private val modelsDir = File(context.filesDir, "ai_models")
    private val settingsDir = File(context.filesDir, "ai_settings")

    init {
        modelsDir.mkdirs()
        settingsDir.mkdirs()
    }

    companion object {
        val availableModels = listOf(
            AIModel(
                id = "gemma-2b",
                name = "Gemma 2B",
                description = "Google's lightweight open model. Great for general chat.",
                sizeMb = 1500,
                downloadUrl = "https://storage.googleapis.com/tensorflow_models/gemma-2b-int4.tflite"
            ),
            AIModel(
                id = "phi-2",
                name = "Phi-2",
                description = "Microsoft's efficient 2.7B model. Fast inference.",
                sizeMb = 2800,
                downloadUrl = "https://huggingface.co/microsoft/phi-2/resolve/main/phi-2.tflite"
            ),
            AIModel(
                id = "tinyllama",
                name = "TinyLlama 1.1B",
                description = "Ultra-lightweight. Runs on any phone.",
                sizeMb = 650,
                downloadUrl = "https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/TinyLlama-1.1B-Chat-v1.0-int4.tflite"
            ),
            AIModel(
                id = "health-assistant",
                name = "Health Assistant",
                description = "Fine-tuned for health & nutrition advice. Most accurate for our use case.",
                sizeMb = 350,
                downloadUrl = "https://huggingface.co/datasets/your-org/health-assistant/resolve/main/model.tflite"
            )
        )
    }

    fun getDownloadedModels(): List<AIModel> {
        return availableModels.map { model ->
            val modelFile = File(modelsDir, "${model.id}.tflite")
            model.copy(isDownloaded = modelFile.exists())
        }
    }

    fun getCurrentModel(): AIModel? {
        val settingsFile = File(settingsDir, "current_model.txt")
        return if (settingsFile.exists()) {
            val modelId = settingsFile.readText().trim()
            availableModels.find { it.id == modelId }?.copy(isDownloaded = true)
        } else {
            null
        }
    }

    suspend fun setCurrentModel(modelId: String) {
        val settingsFile = File(settingsDir, "current_model.txt")
        settingsFile.writeText(modelId)
    }

    suspend fun downloadModel(
        model: AIModel,
        onProgress: (Int) -> Unit
    ): Result<File> = withContext(Dispatchers.IO) {
        try {
            val modelFile = File(modelsDir, "${model.id}.tflite")
            val url = URL(model.downloadUrl)
            val connection = url.openConnection() as HttpURLConnection

            connection.requestMethod = "GET"
            connection.connectTimeout = 15000
            connection.readTimeout = 30000

            val totalSize = connection.contentLength
            var downloadedSize = 0

            connection.inputStream.use { input ->
                FileOutputStream(modelFile).use { output ->
                    val buffer = ByteArray(8192)
                    var bytesRead: Int

                    while (input.read(buffer).also { bytesRead = it } != -1) {
                        output.write(buffer, 0, bytesRead)
                        downloadedSize += bytesRead

                        if (totalSize > 0) {
                            val progress = (downloadedSize * 100 / totalSize)
                            onProgress(progress)
                        }
                    }
                }
            }

            Result.success(modelFile)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteModel(modelId: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val modelFile = File(modelsDir, "${modelId}.tflite")
            if (modelFile.exists()) {
                modelFile.delete()
            } else {
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    fun isModelDownloaded(modelId: String): Boolean {
        val modelFile = File(modelsDir, "${modelId}.tflite")
        return modelFile.exists()
    }

    fun getModelFile(modelId: String): File? {
        val modelFile = File(modelsDir, "${modelId}.tflite")
        return if (modelFile.exists()) modelFile else null
    }

    fun getModelsDirSize(): Long {
        return modelsDir.listFiles()?.sumOf { it.length() } ?: 0L
    }

    fun formatSize(bytes: Long): String {
        return when {
            bytes < 1024 -> "$bytes B"
            bytes < 1024 * 1024 -> "${bytes / 1024} KB"
            bytes < 1024 * 1024 * 1024 -> "${bytes / (1024 * 1024)} MB"
            else -> "${bytes / (1024 * 1024 * 1024)} GB"
        }
    }
}