package com.aihealthappoffline.android.services

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import com.aihealthappoffline.android.data.local.FoodCalorieDatabase
import com.aihealthappoffline.android.data.models.IndianFoodItem
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.ImageLabel
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

data class FoodAnalysisResult(
    val recognizedFood: List<IndianFoodItem>,
    val labels: List<String>,
    val confidenceScores: List<Float>,
    val totalCalories: Int,
    val totalProtein: Double,
    val totalCarbs: Double,
    val totalFat: Double
)

class FoodAnalyzer(private val context: Context) {
    private val foodDatabase = FoodCalorieDatabase(context)

    private val foodKeywords = listOf(
        "food", "meal", "dish", "cuisine", "recipe", "plate", "bowl",
        "rice", "bread", "roti", "naan", "parantha", "chapati",
        "curry", "soup", "salad", "vegetable", "fruit", "meat",
        "chicken", "beef", "pork", "fish", "egg", "paneer", "tofu",
        "dal", "lentil", "bean", "potato", "tomato", "onion", "garlic",
        "spice", "herb", "sauce", "gravy", "dessert", "sweet",
        "pizza", "burger", "sandwich", "wrap", "roll", "noodle", "pasta",
        "breakfast", "lunch", "dinner", "snack", "appetizer",
        "indian", "chinese", "italian", "thai", "mexican",
        "biryani", "pulao", "kebab", "tandoor", "dosa", "idli",
        "paratha", "samosa", "pakora", "chaat", "vada", "dhokla",
        "mango", "banana", "apple", "orange", "grape",
        "milk", "yogurt", "cheese", "butter", "cream",
        "tea", "coffee", "juice", "lassi", "shake",
        "rice", "wheat", "flour", "sugar", "salt", "oil",
        "chicken", "mutton", "lamb", "goat", "fish", "prawn",
        "egg", "tofu", "paneer", "soy", "lentil", "bean"
    )

    suspend fun analyzeImage(bitmap: Bitmap): FoodAnalysisResult = suspendCancellableCoroutine { continuation ->
        val image = InputImage.fromBitmap(bitmap, 0)
        val labeler = ImageLabeling.getClient(
            ImageLabelerOptions.Builder()
                .setConfidenceThreshold(0.6f)
                .build()
        )

        labeler.process(image)
            .addOnSuccessListener { labelsList: List<ImageLabel> ->
                val labelStrings: List<String> = labelsList.map { imgLabel -> imgLabel.text }
                val confidences: List<Float> = labelsList.map { imgLabel -> imgLabel.confidence }

                val matchedFoods = mutableListOf<IndianFoodItem>()
                val matchedLabels = mutableListOf<String>()
                val matchedConfidences = mutableListOf<Float>()

                for (i in labelStrings.indices) {
                    val label = labelStrings[i]
                    val lowerLabel = label.lowercase()

                    val hasKeyword = foodKeywords.any { kw -> lowerLabel.contains(kw) }
                    if (hasKeyword) {
                        matchedLabels.add(label)
                        matchedConfidences.add(confidences[i])

                        val matched = FoodCalorieDatabase.allFoods.find { food ->
                    food.name.lowercase().contains(lowerLabel) ||
                    food.tags.split(",").any { tag -> tag.trim().lowercase().contains(lowerLabel) }
                }
                        if (matched != null && matchedFoods.none { food -> food.name == matched.name }) {
                            matchedFoods.add(matched)
                        }
                    }
                }

                if (matchedFoods.isEmpty()) {
                    for (i in labelStrings.indices) {
                        val label = labelStrings[i]
                        val lowerLabel = label.lowercase()
                        matchedLabels.add(label)
                        matchedConfidences.add(confidences[i])

                        val matched = FoodCalorieDatabase.allFoods.find { food ->
                    food.name.lowercase().contains(lowerLabel) ||
                    food.tags.split(",").any { tag -> tag.trim().lowercase().contains(lowerLabel) }
                }
                        if (matched != null && matchedFoods.none { food -> food.name == matched.name }) {
                            matchedFoods.add(matched)
                            if (matchedFoods.size >= 5) break
                        }
                    }
                }

                if (matchedFoods.isEmpty() && labelStrings.isNotEmpty()) {
                    matchedLabels.add(labelStrings[0])
                    matchedConfidences.add(confidences[0])
                }

                val totalCals = matchedFoods.sumOf { food -> food.calories }
                val totalProtein = matchedFoods.sumOf { food -> food.proteinG }
                val totalCarbs = matchedFoods.sumOf { food -> food.carbsG }
                val totalFat = matchedFoods.sumOf { food -> food.fatG }

                val result = FoodAnalysisResult(
                    recognizedFood = matchedFoods,
                    labels = matchedLabels,
                    confidenceScores = matchedConfidences,
                    totalCalories = totalCals,
                    totalProtein = totalProtein,
                    totalCarbs = totalCarbs,
                    totalFat = totalFat
                )

                if (continuation.isActive) {
                    continuation.resume(result)
                }
            }
            .addOnFailureListener { e ->
                val result = FoodAnalysisResult(
                    recognizedFood = emptyList(),
                    labels = listOf("Analysis failed: ${e.message}"),
                    confidenceScores = emptyList(),
                    totalCalories = 0,
                    totalProtein = 0.0,
                    totalCarbs = 0.0,
                    totalFat = 0.0
                )
                if (continuation.isActive) {
                    continuation.resume(result)
                }
            }
    }

    suspend fun analyzeImageFromUri(uri: Uri): FoodAnalysisResult {
        val image = InputImage.fromFilePath(context, uri)
        return analyzeFromInputImage(image)
    }

    private suspend fun analyzeFromInputImage(image: InputImage): FoodAnalysisResult = suspendCancellableCoroutine { continuation ->
        val labeler = ImageLabeling.getClient(
            ImageLabelerOptions.Builder()
                .setConfidenceThreshold(0.5f)
                .build()
        )

        labeler.process(image)
            .addOnSuccessListener { labelsList: List<ImageLabel> ->
                val labelStrings: List<String> = labelsList.map { imgLabel -> imgLabel.text }
                val confidences: List<Float> = labelsList.map { imgLabel -> imgLabel.confidence }

                val matchedFoods = mutableListOf<IndianFoodItem>()
                val matchedLabels = mutableListOf<String>()
                val matchedConfidences = mutableListOf<Float>()

                for (i in labelStrings.indices) {
                    val label = labelStrings[i]
                    val lowerLabel = label.lowercase()

                    val hasKeyword = foodKeywords.any { kw -> lowerLabel.contains(kw) }
                    if (hasKeyword) {
                        matchedLabels.add(label)
                        matchedConfidences.add(confidences[i])

                        val matched = FoodCalorieDatabase.allFoods.find { food ->
                    food.name.lowercase().contains(lowerLabel) ||
                    food.tags.split(",").any { tag -> tag.trim().lowercase().contains(lowerLabel) }
                }
                        if (matched != null && matchedFoods.none { food -> food.name == matched.name }) {
                            matchedFoods.add(matched)
                        }
                    }
                }

                if (matchedFoods.isEmpty() && labelStrings.isNotEmpty()) {
                    matchedLabels.add(labelStrings[0])
                    matchedConfidences.add(confidences[0])
                }

                val result = FoodAnalysisResult(
                    recognizedFood = matchedFoods,
                    labels = matchedLabels,
                    confidenceScores = matchedConfidences,
                    totalCalories = matchedFoods.sumOf { food -> food.calories },
                    totalProtein = matchedFoods.sumOf { food -> food.proteinG },
                    totalCarbs = matchedFoods.sumOf { food -> food.carbsG },
                    totalFat = matchedFoods.sumOf { food -> food.fatG }
                )

                if (continuation.isActive) {
                    continuation.resume(result)
                }
            }
            .addOnFailureListener { e ->
                val result = FoodAnalysisResult(
                    recognizedFood = emptyList(),
                    labels = listOf("Error: ${e.message}"),
                    confidenceScores = emptyList(),
                    totalCalories = 0,
                    totalProtein = 0.0,
                    totalCarbs = 0.0,
                    totalFat = 0.0
                )
                if (continuation.isActive) {
                    continuation.resume(result)
                }
            }
    }

    fun searchFoodSync(query: String): List<IndianFoodItem> {
        val lowerQuery = query.lowercase()
        return FoodCalorieDatabase.allFoods.filter {
            it.name.lowercase().contains(lowerQuery) ||
            it.nameHindi?.lowercase()?.contains(lowerQuery) == true ||
            it.tags.lowercase().contains(lowerQuery)
        }.take(10)
    }

    fun getFoodByName(name: String): IndianFoodItem? {
        return foodDatabase.getFoodByName(name)
    }

    fun getAllCategories(): List<String> {
        return foodDatabase.getAllCategories()
    }
}