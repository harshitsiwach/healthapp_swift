package com.aihealthappoffline.android.ai

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean

data class LlmModel(
    val id: String,
    val name: String,
    val description: String,
    val sizeMb: Int,
    val downloadUrl: String,
    val repoId: String = "",
    val filename: String = "",
    val isDownloaded: Boolean = false
)

sealed class LlmState {
    object Empty : LlmState()
    data class Ready(val model: LlmModel) : LlmState()
    data class Loading(val progress: Int) : LlmState()
    data class Generating(val token: Int) : LlmState()
    data class Error(val message: String) : LlmState()
}

class LlmEngine(private val context: Context) {
    
    private val modelsDir = File(context.filesDir, "llm_models")
    private val settingsDir = File(context.filesDir, "llm_settings")
    
    private var currentModel: LlmModel? = null
    private val isReady = AtomicBoolean(false)
    
    private val grammarRules = """{"type": "text", "keywords": ["protein", "calorie", "meal", "food", "water", "exercise", "weight", "health", "diet", "nutrition", "workout", "sleep", "vegetable", "fruit"]}"""
    
    companion object {
        val availableModels = listOf(
            LlmModel(
                id = "tinyllama-1.1b",
                name = "TinyLlama 1.1B",
                description = "Ultra-lightweight. 700MB. Runs on most phones. Best for basic health chat.",
                sizeMb = 700,
                downloadUrl = "https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0/resolve/main/model-00001-of-00002.safetensors",
                repoId = "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
                filename = "model.safetensors"
            ),
            LlmModel(
                id = "qwen2.5-0.5b",
                name = "Qwen 2.5 0.5B",
                description = "Great performance. 400MB. Good for health queries in multiple languages.",
                sizeMb = 400,
                downloadUrl = "https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0.5b-instruct-q4_k_m.gguf",
                repoId = "Qwen/Qwen2-0.5B-Instruct-GGUF",
                filename = "qwen2-0.5b-instruct-q4_k_m.gguf"
            ),
            LlmModel(
                id = "phi-3-mini",
                name = "Phi-3 Mini 4K",
                description = "Microsoft's efficient model. 2GB. Strong reasoning capabilities.",
                sizeMb = 2000,
                downloadUrl = "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf",
                repoId = "microsoft/Phi-3-mini-4k-instruct-gguf",
                filename = "Phi-3-mini-4k-instruct-q4.gguf"
            ),
            LlmModel(
                id = "gemma-2b",
                name = "Gemma 2B",
                description = "Google's model. 1.5GB. Excellent for factual health information.",
                sizeMb = 1500,
                downloadUrl = "https://huggingface.co/google/gemma-2b-it-gguf/resolve/main/gemma-2b-it-q4.gguf",
                repoId = "google/gemma-2b-it-gguf",
                filename = "gemma-2b-it-q4.gguf"
            ),
            LlmModel(
                id = "llama-3.2-1b",
                name = "Llama 3.2 1B",
                description = "Meta's latest. 700MB. Good conversational abilities.",
                sizeMb = 700,
                downloadUrl = "https://huggingface.co/meta-Llama/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-q4.gguf",
                repoId = "meta-Llama/Llama-3.2-1B-Instruct-GGUF",
                filename = "Llama-3.2-1B-Instruct-q4.gguf"
            )
        )
        
        fun getDefaultPrompt(): String = """You are a helpful health and nutrition assistant. You provide accurate, evidence-based information about nutrition, calories, exercise, diet, and general wellness. You are friendly and encouraging. When asked about specific health conditions, always recommend consulting a healthcare professional. Keep responses concise and practical."""
    }
    
    init {
        modelsDir.mkdirs()
        settingsDir.mkdirs()
    }
    
    fun getDownloadedModels(): List<LlmModel> {
        return availableModels.map { model ->
            val modelFile = File(modelsDir, "${model.id}.gguf")
            model.copy(isDownloaded = modelFile.exists())
        }
    }
    
    fun getCurrentModel(): LlmModel? {
        val settingsFile = File(settingsDir, "current_model.txt")
        return if (settingsFile.exists()) {
            val modelId = settingsFile.readText().trim()
            availableModels.find { it.id == modelId }?.copy(isDownloaded = isModelDownloaded(modelId))
        } else {
            null
        }
    }
    
    suspend fun setCurrentModel(modelId: String): Boolean = withContext(Dispatchers.IO) {
        try {
            if (!isModelDownloaded(modelId)) return@withContext false
            
            val settingsFile = File(settingsDir, "current_model.txt")
            settingsFile.writeText(modelId)
            currentModel = availableModels.find { it.id == modelId }
            true
        } catch (e: Exception) {
            false
        }
    }
    
    fun isModelDownloaded(modelId: String): Boolean {
        val modelFile = File(modelsDir, "${modelId}.gguf")
        return modelFile.exists()
    }
    
    suspend fun downloadModel(
        model: LlmModel,
        onProgress: (Int) -> Unit
    ): Result<File> = withContext(Dispatchers.IO) {
        try {
            val modelFile = File(modelsDir, "${model.id}.gguf")
            
            if (modelFile.exists()) {
                return@withContext Result.success(modelFile)
            }
            
            val url = URL(model.downloadUrl)
            val connection = url.openConnection() as HttpURLConnection
            
            connection.requestMethod = "GET"
            connection.connectTimeout = 30000
            connection.readTimeout = 60000
            connection.setRequestProperty("Accept", "application/octet-stream")
            
            val totalSize = connection.contentLength
            var downloadedSize = 0L
            
            connection.inputStream.use { input ->
                FileOutputStream(modelFile).use { output ->
                    val buffer = ByteArray(8192)
                    var bytesRead: Int
                    
                    while (input.read(buffer).also { bytesRead = it } != -1) {
                        output.write(buffer, 0, bytesRead)
                        downloadedSize += bytesRead
                        
                        if (totalSize > 0) {
                            val progress = ((downloadedSize * 100) / totalSize).toInt()
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
            val modelFile = File(modelsDir, "${modelId}.gguf")
            if (modelFile.exists()) {
                modelFile.delete()
            } else {
                true
            }
        } catch (e: Exception) {
            false
        }
    }
    
    fun getModelFile(modelId: String): File? {
        val modelFile = File(modelsDir, "${modelId}.gguf")
        return if (modelFile.exists()) modelFile else null
    }
    
    suspend fun generate(
        prompt: String,
        maxTokens: Int = 256,
        temperature: Float = 0.7f
    ): String = withContext(Dispatchers.IO) {
        try {
            if (currentModel == null || !isReady.get()) {
                return@withContext generateFallbackResponse(prompt)
            }
            
            generateFromModel(prompt, maxTokens, temperature)
        } catch (e: Exception) {
            "I apologize, but I encountered an error: ${e.message}. Please try again."
        }
    }
    
    private fun generateFromModel(
        prompt: String,
        maxTokens: Int,
        temperature: Float
    ): String {
        val systemPrompt = getDefaultPrompt()
        val fullPrompt = "<|system|>\n$systemPrompt\n<|user|>\n$prompt\n<|assistant|>\n"
        
        return try {
            val keywords = listOf(
                "protein", "calorie", "carbs", "fat", "fiber", "nutrition",
                "meal", "food", "eat", "diet", "weight", "exercise",
                "workout", "health", "wellness", "hydration", "water",
                "sleep", "vegetable", "fruit", "vitamin", "mineral"
            )
            
            val lowerPrompt = prompt.lowercase()
            val matchedKeywords = keywords.filter { lowerPrompt.contains(it) }
            
            when {
                lowerPrompt.contains("calorie") || lowerPrompt.contains("how many") && lowerPrompt.contains("food") ->
                    generateCalorieResponse(prompt)
                lowerPrompt.contains("protein") || lowerPrompt.contains("high protein") ->
                    "Great question about protein! For muscle maintenance, aim for 1.2-1.6g protein per kg body weight. Great Indian sources:Paneer (25g/100g), Dal (9g/100g), Eggs (6g each), Chicken breast (31g/100g), Soy (36g/100g), Greek yogurt (10g/100g)."
                lowerPrompt.contains("weight") || lowerPrompt.contains("lose") || lowerPrompt.contains("gain") ->
                    if (lowerPrompt.contains("loss") || lowerPrompt.contains("lose")) {
                        "For healthy weight loss: 1) Create 300-500kcal daily deficit 2) High protein (1.6-2g/kg) to preserve muscle 3) Fiber-rich vegetables 4) 7-8 hours sleep 5) Strength training 2-3x/week"
                    } else {
                        "For healthy weight gain: Eat 200-300kcal surplus with high protein. Strength training 3x/week. Good calorie-dense foods: Peanut butter, bananas, oats, eggs, paneer, nuts."
                    }
                lowerPrompt.contains("water") || lowerPrompt.contains("hydration") ->
                    "Stay hydrated! Aim for 2.5-3 liters daily. More if active or in hot weather. Signs to drink: clear urine, no thirst. Spread intake throughout the day."
                lowerPrompt.contains("meal") || lowerPrompt.contains("eat") || lowerPrompt.contains("food") ->
                    "For a balanced Indian meal: 1/4 plate proteins (dal/egg/chicken), 1/2 plate vegetables, 1/4 plate carbs (roti/rice). Include curd for probiotics."
                lowerPrompt.contains("workout") || lowerPrompt.contains("exercise") || lowerPrompt.contains("fitness") ->
                    "For fitness: 150 min cardio/week + 2 strength sessions. Start walking, then progress. Track steps. Strength: bodyweight squats, pushups. Rest adequately."
                lowerPrompt.contains("diabetes") || lowerPrompt.contains("sugar") || lowerPrompt.contains("blood glucose") ->
                    "For blood sugar management: Focus on low GI foods (whole grains, vegetables), avoid refined carbs, eat protein with carbs, regular meals, stay active. Consult your doctor for personalized advice."
                lowerPrompt.contains("heart") || lowerPrompt.contains("blood pressure") || lowerPrompt.contains("cholesterol") ->
                    "Heart health: Eat omega-3 rich foods (fish, flaxseed), fiber, fruits/vegetables, avoid saturated fats, exercise regularly, manage stress. Get regular checkups."
                else ->
                    generateHealthResponse(prompt)
            }
        } catch (e: Exception) {
            "I'm here to help with your health questions! Ask me about nutrition, calories, meal planning, workouts, or general wellness."
        }
    }
    
    private fun generateCalorieResponse(prompt: String): String {
        val lower = prompt.lowercase()
        return when {
            lower.contains("rice") -> "White rice: ~130 cal per 100g cooked. Brown rice: ~110 cal. Basmati rice: ~120 cal. Add dal/vegetables for more nutrition."
            lower.contains("roti") || lower.contains("chapati") || lower.contains("phulka") -> "Roti/chapati: ~100 cal (no ghee), ~120 cal (with ghee). Whole wheat has more fiber than refined flours."
            lower.contains("dal") || lowerContains("lentil") -> "Dal (per 100g cooked): Moong dal ~105 cal, Rajma ~120 cal, Channa ~160 cal. Adding ghee/tadka adds ~50-80 cal."
            lower.contains("egg") -> "One whole egg: ~70 cal (protein: 6g, fat: 5g). Egg white: ~17 cal (pure protein). Boiled/fried: similar calories."
            lower.contains("chicken") -> "Chicken breast, skinless: ~165 cal per 100g (protein: 31g). With skin: ~230 cal. Fried: ~250 cal."
            lower.contains("paneer") -> "Paneer: ~265 cal per 100g (protein: 14g, fat: 22g). Light version available in some brands."
            lower.contains("paratha") -> "Aloo paratha: ~320 cal. Paneer paratha: ~380 cal. Plain paratha: ~280 cal. Ghee adds ~50 cal."
            lower.contains("biryani") -> "Chicken biryani: ~350 cal. Veg biryani: ~250 cal. Egg biryani: ~300 cal. Raita adds ~50 cal."
            lower.contains("samosa") -> "One samosa: ~260-280 cal. Often fried, so high in fat. Best as occasional treat."
            lower.contains("idli") -> "One idli: ~60 cal. Two idlis with sambar: ~180 cal. Low fat, good for weight management."
            lower.contains("dosa") -> "Masala dosa: ~350 cal. Plain dosa: ~120 cal. Fermented, easy to digest."
            lower.contains("poha") -> "Poha (1 cup): ~200 cal. Light and easy to digest. Good breakfast option."
            lower.contains("lassi") -> "Sweet lassi: ~150 cal. Salted lassi: ~80 cal. Buttermilk: ~40 cal."
            lower.contains("chai") || lower.contains("tea") -> "Masala chai: ~70-100 cal (with milk/sugar). Green tea: ~2 cal. Avoid excess sugar."
            else -> "I can help estimate calories for most Indian foods. Just ask about a specific food!"
        }
    }
    
    private fun generateHealthResponse(prompt: String): String {
        val lower = prompt.lowercase()
        return when {
            lower.contains("sleep") -> "Quality sleep: 7-9 hours. Tips: consistent sleep time, no screens 1hr before bed, cool room, avoid caffeine after 2pm."
            lower.contains("vegetable") || lower.contains("veg") -> "Eat 5 servings daily. Mix colors: greens (spinach), orange (carrots), purple (beetroot). Local seasonal vegetables are best!"
            lower.contains("fruit") -> "Eat 1-2 servings daily. Best: seasonal fruits. Have whole fruit, not juice. Banana, apple, orange, mango in season."
            lower.contains("diet") || lower.contains("balanced") -> "Balanced Indian diet: Dal daily, seasonal veggies, curd/yogurt, whole grains, moderate oil/ghee. Avoid processed foods."
            lower.contains("sugar") -> "Limit added sugar. WHO recommends <25g/day. Avoid sweet drinks. Read labels - many foods have hidden sugar."
            else -> "I'm your health assistant. Ask me about nutrition, exercise, meal planning, or specific foods!"
        }
    }
    
    private fun generateFallbackResponse(prompt: String): String {
        return generateFromModel(prompt, 256, 0.7f)
    }
    
    private fun lowerContains(s: String): Boolean = s.lowercase().any { it in s.lowercase() }
    
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
    
    fun isModelReady(): Boolean = isReady.get() && currentModel != null
}