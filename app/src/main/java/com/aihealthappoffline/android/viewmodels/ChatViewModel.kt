package com.aihealthappoffline.android.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class ChatMessage(val text: String, val isUser: Boolean)

class ChatViewModel : ViewModel() {

    private val _messages = MutableStateFlow<List<ChatMessage>>(
        listOf(
            ChatMessage(
                "Namaste! I'm your offline AI Health Coach. I can help with nutrition, meal planning, and workout advice. What would you like to know?",
                false
            )
        )
    )
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun sendMessage(text: String) {
        viewModelScope.launch {
            _messages.value = _messages.value + ChatMessage(text, true)
            _isLoading.value = true

            // Simulate AI response (replace with real local LLM inference)
            delay(800)
            val response = generateOfflineResponse(text)
            _isLoading.value = false
            _messages.value = _messages.value + ChatMessage(response, false)
        }
    }

    private fun generateOfflineResponse(userText: String): String {
        val lower = userText.lowercase()
        return when {
            lower.contains("calorie") || lower.contains("calories") ->
                "To maintain your weight, aim for a balanced intake based on your BMR and activity level. Would you like me to calculate your personalized daily target?"
            lower.contains("protein") ->
                "Great question! For muscle maintenance, aim for 1.2–1.6g per kg of body weight. Sources: lentils, paneer, eggs, chicken, and soya chaap."
            lower.contains("weight loss") || lower.contains("lose weight") ->
                "A safe deficit is 300–500 kcal below maintenance. Focus on high-protein meals, fiber-rich veggies, and consistent hydration. I can suggest a meal plan!"
            lower.contains("muscle") || lower.contains("gain") ->
                "To gain muscle, eat at a slight surplus (200–300 kcal) with 1.6–2.0g protein/kg. Combine with progressive resistance training."
            lower.contains("water") || lower.contains("hydration") ->
                "Aim for 2.5–3 liters daily. Adjust based on activity and weather. Your hydration tracker is on the Dashboard."
            lower.contains("meal") || lower.contains("food") ->
                "How about Rajma Chawal for lunch? It's high in protein and fiber. Or if you prefer lighter, try Dal Tadka with Roti."
            lower.contains("sleep") ->
                "Quality sleep (7–9 hours) is crucial for recovery and hormone regulation. Try to maintain a consistent sleep schedule."
            lower.contains("workout") || lower.contains("exercise") ->
                "Consistency beats intensity. Start with 150 min moderate cardio + 2 strength sessions per week. Track your steps in the Health tab."
            else ->
                "That's a great health question! Since I'm running fully offline, I can answer based on general nutrition and wellness knowledge. For more specific advice, consider consulting a professional."
        }
    }
}
