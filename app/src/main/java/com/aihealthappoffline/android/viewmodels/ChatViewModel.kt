package com.aihealthappoffline.android.viewmodels

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.ai.LlmEngine
import com.aihealthappoffline.android.data.local.FoodCalorieDatabase
import com.aihealthappoffline.android.data.models.IndianFoodItem
import com.aihealthappoffline.android.services.FoodAnalyzer
import com.aihealthappoffline.android.services.FoodAnalysisResult
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

data class ChatMessage(
    val text: String,
    val isUser: Boolean,
    val isFoodAnalysis: Boolean = false,
    val foodResult: FoodAnalysisResult? = null
)

data class FoodAnalysisState(
    val isAnalyzing: Boolean = false,
    val result: FoodAnalysisResult? = null,
    val error: String? = null
)

class ChatViewModel : ViewModel() {

    private val _messages = MutableStateFlow<List<ChatMessage>>(
        listOf(
            ChatMessage(
                "Namaste! I'm your offline AI Health Coach. I can help with nutrition, meal planning, workout advice, and analyze food photos to estimate calories. What would you like to know?",
                false
            )
        )
    )
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _foodAnalysis = MutableStateFlow(FoodAnalysisState())
    val foodAnalysis: StateFlow<FoodAnalysisState> = _foodAnalysis.asStateFlow()

    private var llmEngine: LlmEngine? = null
    private var foodAnalyzer: FoodAnalyzer? = null

    private val foodCalorieDb by lazy { FoodCalorieDatabase(AppContextHolder.context) }

    private var isLlmReady = false

    fun initialize(context: Context) {
        llmEngine = LlmEngine(context)
        foodAnalyzer = FoodAnalyzer(context)
        
        val currentModel = llmEngine?.getCurrentModel()
        isLlmReady = currentModel != null && llmEngine?.isModelReady() == true
    }

    fun sendMessage(text: String) {
        viewModelScope.launch {
            _messages.value = _messages.value + ChatMessage(text, true)
            _isLoading.value = true

            delay(400)

            val response = generateResponse(text)
            _isLoading.value = false
            _messages.value = _messages.value + ChatMessage(response, false)
        }
    }

    fun analyzeFoodImage(bitmap: Bitmap) {
        viewModelScope.launch {
            _foodAnalysis.value = FoodAnalysisState(isAnalyzing = true)
            
            try {
                val analyzer = foodAnalyzer ?: return@launch
                val result = analyzer.analyzeImage(bitmap)
                
                _foodAnalysis.value = FoodAnalysisState(result = result)
                
                val message = formatFoodResult(result)
                _messages.value = _messages.value + ChatMessage(
                    text = message,
                    isUser = true,
                    isFoodAnalysis = true,
                    foodResult = result
                )
                
                val advice = generateFoodAdvice(result)
                _messages.value = _messages.value + ChatMessage(advice, false)
                
            } catch (e: Exception) {
                _foodAnalysis.value = FoodAnalysisState(error = e.message)
            }
        }
    }

    fun analyzeFoodFromUri(uri: Uri) {
        viewModelScope.launch {
            _foodAnalysis.value = FoodAnalysisState(isAnalyzing = true)
            
            try {
                val analyzer = foodAnalyzer ?: return@launch
                val result = analyzer.analyzeImageFromUri(uri)
                
                _foodAnalysis.value = FoodAnalysisState(result = result)
                
                if (result.recognizedFood.isNotEmpty()) {
                    val message = formatFoodResult(result)
                    _messages.value = _messages.value + ChatMessage(
                        text = message,
                        isUser = true,
                        isFoodAnalysis = true,
                        foodResult = result
                    )
                    
                    val advice = generateFoodAdvice(result)
                    _messages.value = _messages.value + ChatMessage(advice, false)
                } else {
                    _messages.value = _messages.value + ChatMessage(
                        "I couldn't identify food in that image. Try a clearer photo with good lighting!",
                        false
                    )
                }
            } catch (e: Exception) {
                _messages.value = _messages.value + ChatMessage(
                    "Sorry, I couldn't analyze that image. Error: ${e.message}",
                    false
                )
            }
        }
    }

    private fun formatFoodResult(result: FoodAnalysisResult): String {
        if (result.recognizedFood.isEmpty()) {
            return "Analyzed: ${result.labels.joinToString(", ")}"
        }
        
        val foodNames = result.recognizedFood.take(3).joinToString(", ") { it.name }
        return "Analyzed food: $foodNames | Calories: ${result.totalCalories} | Protein: ${String.format("%.1f", result.totalProtein)}g"
    }

    private fun generateFoodAdvice(result: FoodAnalysisResult): String {
        if (result.recognizedFood.isEmpty()) {
            return "Tip: For accurate calorie estimation, try taking photos in good lighting with the food on a clean plate."
        }
        
        val foods = result.recognizedFood
        val advice = StringBuilder()
        
        if (result.totalCalories > 500) {
            advice.append("This is a ${if (result.totalCalories > 800) "high" else "moderate"} calorie meal. ")
        }
        
        if (result.totalProtein < 10 && foods.any { it.proteinG < 10 }) {
            advice.append("Consider adding protein (dal, paneer, or eggs) for a more balanced meal. ")
        }
        
        val highCarb = foods.filter { it.carbsG > 30 }
        if (highCarb.isNotEmpty()) {
            advice.append("High carb items: ${highCarb.joinToString(", ") { it.name }}. Pair with vegetables for fiber. ")
        }
        
        if (advice.isEmpty()) {
            advice.append("Good nutrition balance! To log this meal, tap the + button on Dashboard.")
        }
        
        return advice.toString()
    }

    private suspend fun generateResponse(userText: String): String {
        val lower = userText.lowercase()
        
        return when {
            lower.contains("hello") || lower.contains("hi") || lower.contains("namaste") ->
                "Namaste! How can I help you with your health today?"
            lower.contains("thank") ->
                "You're welcome! Stay healthy! Is there anything else I can help with?"
            lower.contains("calorie") || lower.contains("how many") ->
                generateCalorieResponse(lower)
            lower.contains("protein") ->
                "Protein is essential! For Indians, great sources: Paneer (25g/100g), Dal (9g/100g), Eggs (6g each), Chicken (31g/100g), Soy (36g/100g). Aim for 1.2-1.6g per kg body weight."
            lower.contains("weight loss") || lower.contains("lose weight") ->
                """Safe weight loss tips:
1. 300-500kcal daily deficit
2. High protein (1.6-2g/kg)
3. Fiber-rich vegetables
4. 7-8 hours sleep
5. Strength training 2-3x/week
6. Stay hydrated!
Want a meal plan?"""
            lower.contains("muscle") || lower.contains("gain weight") ->
                """To gain muscle:
1. 200-300kcal surplus
2. Protein 1.6-2.2g/kg
3. Strength training
4. Progressive overload
5. Good sleep
Want a high-protein meal plan?"""
            lower.contains("water") || lower.contains("hydration") ||
            lower.contains("how much water") || lower.contains("drink") ->
                "Aim for 2.5-3 liters daily. More if active. Tips: Drink before meals, set reminders, add lemon for flavor. Signs of dehydration: dark urine, thirst, fatigue."
            lower.contains("meal") || lower.contains("food") || lower.contains("eat") ->
                "Great question! For a balanced Indian meal: 1/4 plate proteins (dal/egg/chicken), 1/2 plate vegetables, 1/4 plate carbs (roti/rice). Add curd for probiotics."
            lower.contains("sleep") ->
                "Good sleep tips: 7-9 hours, consistent schedule, no screens 1hr before bed, cool room (18-21°C), avoid caffeine after 2pm, light dinner."
            lower.contains("workout") || lower.contains("exercise") ||
            lower.contains("fitness") ->
                """Fit India tips:
• 150 min cardio/week
• 2 strength sessions
• Start walking, progress slowly
• Track steps (10k/day goal)
• Strength: squats, pushups
• Rest between sessions"""
            lower.contains("diabetes") || lower.contains("sugar") ||
            lower.contains("blood glucose") ->
                """Diabetes management:
• Low GI foods
• Avoid refined carbs
• Protein with carbs
• Regular meals
• Stay active
• Monitor HbA1c
Consult your doctor!"""
            lower.contains("heart") || lower.contains("cholesterol") ||
            lower.contains("blood pressure") ->
                """Heart health:
• Omega-3 (fish, flaxseed)
• Fiber rich foods
• Fruits & vegetables
• Avoid saturated fats
• Regular exercise
• Manage stress
• Regular checkups"""
            lower.contains("vegetable") || lower.contains("veg") ->
                "Eat 5 servings daily! Mix colors: greens (spinach, methi), orange (carrots), purple (beetroot). Local seasonal veggies are best!"
            lower.contains("fruit") ->
                "1-2 servings daily. Have whole fruit, not juice. Best: seasonal fruits (banana, apple, orange, mango in season)."
            lower.contains("diet") || lower.contains("balanced") ->
                """Balanced Indian diet:
• Dal daily (protein + fiber)
• Seasonal vegetables
• Curd/yogurt (probiotics)
• Whole grains
• Moderate oil/ghee
• Avoid processed foods"""
            lower.contains("sugar") ->
                "Limit added sugar! WHO: <25g/day. Avoid sweet drinks. Read labels - many foods have hidden sugar. Natural alternatives: jaggery, dates."
            lower.contains("what can you do") || lower.contains("help") ||
            lower.contains(" capabilities") ->
                """I can help you with:
• Calorie counting
• Protein & nutrition info
• Meal planning
• Workout advice
• Weight management
• Sleep tips
• Analyze food photos!
Just ask!"""
            else ->
                generateDefaultResponse(lower)
        }
    }

    private fun generateCalorieResponse(query: String): String {
        return when {
            query.contains("rice") -> "White rice: ~130 cal/100g cooked. Brown rice: ~110 cal. Basmati: ~120 cal. Pair with dal/vegetables!"
            query.contains("roti") || query.contains("chapati") || query.contains("phulka") ->
                "Roti: ~100 cal (no ghee), ~120 cal (with ghee). Whole wheat has more fiber!"
            query.contains("dal") || query.contains("lentil") ->
                "Dal (per 100g cooked): Moong dal ~105 cal, Rajma ~120 cal, Channa ~160 cal. Adding tadka adds ~50-80 cal."
            query.contains("egg") ->
                "Whole egg: ~70 cal (6g protein). Egg white: ~17 cal (pure protein). Cooking method: similar calories."
            query.contains("chicken") ->
                "Chicken breast, skinless: ~165 cal/100g (31g protein). With skin: ~230 cal. Fried: ~250 cal."
            query.contains("paneer") ->
                "Paneer: ~265 cal/100g (14g protein, 22g fat). Light versions available!"
            query.contains("paratha") ->
                "Aloo paratha: ~320 cal. Paneer paratha: ~380 cal. Plain paratha: ~280 cal. Ghee adds ~50 cal."
            query.contains("biryani") ->
                "Chicken biryani: ~350 cal. Veg biryani: ~250 cal. Egg biryani: ~300 cal. Raita adds ~50 cal."
            query.contains("idli") ->
                "One idli: ~60 cal. Two idlis with sambar: ~180 cal. Low fat, good for weight management!"
            query.contains("dosa") ->
                "Masala dosa: ~350 cal. Plain dosa: ~120 cal. Fermented, easier to digest."
            query.contains("samosa") ->
                "One samosa: ~260-280 cal. Often fried - best as occasional treat!"
            query.contains("lassi") ->
                "Sweet lassi: ~150 cal. Salted lassi: ~80 cal. Buttermilk: ~40 cal."
            query.contains("chai") || query.contains("tea") ->
                "Masala chai: ~70-100 cal (with milk/sugar). Green tea: ~2 cal. Avoid excess sugar!"
            else ->
                "I can estimate calories for most Indian foods! Just ask: 'calories in [food name]'"
        }
    }

    private suspend fun generateDefaultResponse(query: String): String {
        return if (llmEngine != null && isLlmReady) {
            try {
                llmEngine?.generate(query) ?: generateFallbackResponse()
            } catch (e: Exception) {
                generateFallbackResponse()
            }
        } else {
            generateFallbackResponse()
        }
    }

    private fun generateFallbackResponse(): String {
        return """That's a great health question! 

For personalized advice, I need more details:
• Your weight goal (lose/maintain/gain)
• Any health conditions
• Activity level

I can also analyze food photos to estimate calories! 

What would you like help with?"""
    }

    fun searchFood(query: String): List<IndianFoodItem> {
        return runBlocking {
            foodCalorieDb.searchFood(query).take(10)
        }
    }

    fun getFoodByNameSync(name: String): IndianFoodItem? {
        return runBlocking {
            foodCalorieDb.getFoodByName(name)
        }
    }
}

object AppContextHolder {
    lateinit var context: Context
}