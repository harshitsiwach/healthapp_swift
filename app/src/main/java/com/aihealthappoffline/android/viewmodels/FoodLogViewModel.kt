package com.aihealthappoffline.android.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aihealthappoffline.android.HealthAppApplication
import com.aihealthappoffline.android.data.models.DailyLog
import com.aihealthappoffline.android.data.models.IndianFoodItem
import com.aihealthappoffline.android.repositories.HealthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

class FoodLogViewModel(
    private val repository: HealthRepository = HealthRepository(
        HealthAppApplication.database.userProfileDao(),
        HealthAppApplication.database.dailyLogDao(),
        HealthAppApplication.database.indianFoodDao()
    )
) : ViewModel() {

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _searchResults = MutableStateFlow<List<IndianFoodItem>>(emptyList())
    val searchResults: StateFlow<List<IndianFoodItem>> = _searchResults.asStateFlow()

    private val _todayLogs = MutableStateFlow<List<DailyLog>>(emptyList())
    val todayLogs: StateFlow<List<DailyLog>> = _todayLogs.asStateFlow()

    private val today: String = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

    init {
        viewModelScope.launch {
            repository.getLogsForDate(today).collect { _todayLogs.value = it }
        }
        seedFoodDatabaseIfNeeded()
    }

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
        viewModelScope.launch {
            repository.searchFood(query).collect { _searchResults.value = it }
        }
    }

    fun addFoodItem(item: IndianFoodItem) {
        viewModelScope.launch {
            val log = DailyLog(
                id = UUID.randomUUID().toString(),
                date = today,
                foodName = item.name,
                estimatedCalories = item.calories,
                proteinG = item.proteinG,
                carbsG = item.carbsG,
                fatG = item.fatG,
                fiberG = item.fiberG,
                mealType = "meal"
            )
            repository.addLog(log)
            _searchQuery.value = ""
            _searchResults.value = emptyList()
        }
    }

    private fun seedFoodDatabaseIfNeeded() {
        viewModelScope.launch {
            if (!repository.isFoodDbSeeded()) {
                repository.seedFoodDatabase(indianFoodSeedData)
            }
        }
    }
}

val indianFoodSeedData = listOf(
    IndianFoodItem("1", "Dal Makhani", "दाल मखनी", 280, 12.0, 32.0, 10.0, 8.0, "Curry", true, "1 bowl", "lentil creamy punjabi"),
    IndianFoodItem("2", "Roti (Whole Wheat)", "रोटी", 120, 4.0, 22.0, 2.5, 3.0, "Bread", true, "1 piece", "bread staple"),
    IndianFoodItem("3", "Chicken Biryani", "चिकन बिरयानी", 420, 22.0, 48.0, 14.0, 3.0, "Rice", false, "1 plate", "rice chicken hyderabadi"),
    IndianFoodItem("4", "Paneer Butter Masala", "पनीर बटर मसाला", 380, 18.0, 16.0, 28.0, 2.0, "Curry", true, "1 bowl", "paneer creamy north"),
    IndianFoodItem("5", "Idli", "इडली", 65, 2.5, 14.0, 0.2, 2.0, "Breakfast", true, "2 pieces", "south steamed fermented"),
    IndianFoodItem("6", "Sambar", "सांभर", 90, 4.0, 18.0, 1.0, 5.0, "Curry", true, "1 bowl", "south lentil vegetable"),
    IndianFoodItem("7", "Chole Bhature", "छोले भटूरे", 520, 14.0, 62.0, 22.0, 10.0, "Meal", true, "1 plate", "punjabi chickpea fried"),
    IndianFoodItem("8", "Rajma Chawal", "राजमा चावल", 340, 14.0, 48.0, 8.0, 12.0, "Meal", true, "1 plate", "kidney bean rice north"),
    IndianFoodItem("9", "Aloo Paratha", "आलू पराठा", 290, 6.0, 38.0, 12.0, 4.0, "Breakfast", true, "1 piece", "potato stuffed bread"),
    IndianFoodItem("10", "Dosa (Plain)", "डोसा", 135, 3.0, 28.0, 1.0, 1.0, "Breakfast", true, "1 piece", "south crepe rice"),
    IndianFoodItem("11", "Masala Dosa", "मसाला डोसा", 240, 5.0, 38.0, 8.0, 3.0, "Breakfast", true, "1 piece", "south potato stuffed"),
    IndianFoodItem("12", "Palak Paneer", "पालक पनीर", 300, 16.0, 12.0, 20.0, 4.0, "Curry", true, "1 bowl", "spinach cottage north"),
    IndianFoodItem("13", "Butter Chicken", "बटर चिकन", 450, 28.0, 14.0, 30.0, 1.0, "Curry", false, "1 bowl", "creamy tomato chicken"),
    IndianFoodItem("14", "Tandoori Chicken", "तंदूरी चिकन", 280, 32.0, 4.0, 14.0, 0.0, "Grill", false, "4 pieces", "grilled spiced"),
    IndianFoodItem("15", "Poha", "पोहा", 180, 4.0, 32.0, 4.0, 2.0, "Breakfast", true, "1 plate", "flattened rice west"),
    IndianFoodItem("16", "Upma", "उपमा", 220, 6.0, 36.0, 6.0, 3.0, "Breakfast", true, "1 bowl", "semolina south"),
    IndianFoodItem("17", "Vada Pav", "वड़ा पाव", 290, 6.0, 38.0, 12.0, 2.0, "Snack", true, "1 piece", "mumbai street potato"),
    IndianFoodItem("18", "Samosa", "समोसा", 260, 5.0, 28.0, 14.0, 3.0, "Snack", true, "1 piece", "fried pastry potato"),
    IndianFoodItem("19", "Pakora", "पकोड़ा", 220, 6.0, 22.0, 12.0, 4.0, "Snack", true, "4 pieces", "fritters veg"),
    IndianFoodItem("20", "Chana Chaat", "छना चाट", 180, 10.0, 28.0, 3.0, 8.0, "Snack", true, "1 bowl", "chickpea street"),
    IndianFoodItem("21", "Egg Curry", "एग करी", 260, 16.0, 12.0, 16.0, 3.0, "Curry", false, "2 eggs", "boiled egg spicy"),
    IndianFoodItem("22", "Fish Curry", "फिश करी", 240, 22.0, 8.0, 12.0, 1.0, "Curry", false, "1 bowl", "fish coconut south"),
    IndianFoodItem("23", "Mutton Rogan Josh", "मटन रोगन जोश", 380, 30.0, 8.0, 24.0, 1.0, "Curry", false, "1 bowl", "kashmiri lamb spicy"),
    IndianFoodItem("24", "Baingan Bharta", "बैंगन भरता", 160, 4.0, 18.0, 8.0, 8.0, "Curry", true, "1 bowl", "eggplant smoked north"),
    IndianFoodItem("25", "Bhindi Masala", "भिंडी मसाला", 140, 4.0, 16.0, 6.0, 6.0, "Curry", true, "1 bowl", "okra stir fried"),
    IndianFoodItem("26", "Gobi Manchurian", "गोभी मंचूरियन", 240, 6.0, 28.0, 12.0, 4.0, "Chinese", true, "1 plate", "cauliflower indo-chinese"),
    IndianFoodItem("27", "Fried Rice", "फ्राइड राइस", 280, 8.0, 42.0, 8.0, 2.0, "Chinese", true, "1 plate", "veg rice"),
    IndianFoodItem("28", "Chicken Fried Rice", "चिकन फ्राइड राइस", 360, 18.0, 42.0, 12.0, 2.0, "Chinese", false, "1 plate", "chicken rice"),
    IndianFoodItem("29", "Chapati", "चपाती", 100, 3.5, 18.0, 2.0, 2.5, "Bread", true, "1 piece", "thin whole wheat"),
    IndianFoodItem("30", "Naan", "नान", 180, 5.0, 28.0, 5.0, 1.0, "Bread", true, "1 piece", "tandoori bread"),
    IndianFoodItem("31", "Gulab Jamun", "गुलाब जामुन", 150, 2.0, 22.0, 6.0, 0.0, "Dessert", true, "2 pieces", "sweet fried milk"),
    IndianFoodItem("32", "Rasgulla", "रसगुल्ला", 120, 2.0, 24.0, 1.0, 0.0, "Dessert", true, "2 pieces", "spongy sweet bengal"),
    IndianFoodItem("33", "Jalebi", "जलेबी", 200, 2.0, 38.0, 6.0, 0.0, "Dessert", true, "4 pieces", "syrup sweet spiral"),
    IndianFoodItem("34", "Kheer", "खीर", 180, 5.0, 28.0, 5.0, 0.0, "Dessert", true, "1 bowl", "rice pudding milk"),
    IndianFoodItem("35", "Lassi", "लस्सी", 150, 6.0, 18.0, 5.0, 0.0, "Beverage", true, "1 glass", "yogurt drink punjabi"),
    IndianFoodItem("36", "Chaas", "छाछ", 60, 3.0, 6.0, 2.0, 0.0, "Beverage", true, "1 glass", "buttermilk"),
    IndianFoodItem("37", "Masala Chai", "मसाला चाय", 80, 2.0, 10.0, 3.0, 0.0, "Beverage", true, "1 cup", "tea milk spices"),
    IndianFoodItem("38", "Matar Paneer", "मटर पनीर", 260, 14.0, 16.0, 16.0, 4.0, "Curry", true, "1 bowl", "peas cottage north"),
    IndianFoodItem("39", "Kadhi Pakora", "कढ़ी पकोड़ा", 220, 8.0, 22.0, 10.0, 3.0, "Curry", true, "1 bowl", "yogurt curry fritters"),
    IndianFoodItem("40", "Aloo Gobi", "आलू गोभी", 160, 4.0, 20.0, 6.0, 5.0, "Curry", true, "1 bowl", "potato cauliflower"),
    IndianFoodItem("41", "Chana Masala", "छना मसाला", 240, 12.0, 32.0, 8.0, 10.0, "Curry", true, "1 bowl", "chickpea spicy"),
    IndianFoodItem("42", "Dal Tadka", "दाल तड़का", 180, 10.0, 24.0, 4.0, 6.0, "Curry", true, "1 bowl", "lentil tempered"),
    IndianFoodItem("43", "Methi Thepla", "मेथी थेपला", 160, 5.0, 22.0, 6.0, 4.0, "Breakfast", true, "2 pieces", "gujarati flatbread"),
    IndianFoodItem("44", "Pesarattu", "पेसरट्टू", 140, 8.0, 22.0, 2.0, 4.0, "Breakfast", true, "1 piece", "moong dal dosa"),
    IndianFoodItem("45", "Appam", "अप्पम", 120, 2.0, 26.0, 1.0, 1.0, "Breakfast", true, "2 pieces", "kerala rice pancake"),
    IndianFoodItem("46", "Stew (Vegetable)", "सब्जी स्टू", 140, 4.0, 18.0, 6.0, 5.0, "Curry", true, "1 bowl", "kerala coconut veg"),
    IndianFoodItem("47", "Chicken Chettinad", "चिकन चेट्टीनाड", 360, 28.0, 12.0, 22.0, 2.0, "Curry", false, "1 bowl", "chettinad spicy pepper"),
    IndianFoodItem("48", "Malai Kofta", "मलाई कोफ्ता", 340, 12.0, 18.0, 22.0, 4.0, "Curry", true, "1 bowl", "creamy dumpling north"),
    IndianFoodItem("49", "Shahi Paneer", "शाही पनीर", 360, 16.0, 14.0, 26.0, 2.0, "Curry", true, "1 bowl", "royal creamy cottage"),
    IndianFoodItem("50", "Mushroom Masala", "मशरूम मसाला", 200, 8.0, 14.0, 12.0, 4.0, "Curry", true, "1 bowl", "mushroom spicy"),
    IndianFoodItem("51", "Egg Bhurji", "एग भुर्जी", 220, 14.0, 8.0, 14.0, 2.0, "Breakfast", false, "2 eggs", "scrambled egg spicy"),
    IndianFoodItem("52", "Sprouts Salad", "स्प्राउट्स सलाद", 120, 10.0, 16.0, 2.0, 8.0, "Salad", true, "1 bowl", "healthy protein"),
    IndianFoodItem("53", "Raita", "रायता", 80, 4.0, 8.0, 3.0, 1.0, "Side", true, "1 bowl", "yogurt cucumber"),
    IndianFoodItem("54", "Kachori", "कचौरी", 260, 6.0, 30.0, 14.0, 3.0, "Snack", true, "2 pieces", "fried lentil pastry"),
    IndianFoodItem("55", "Pani Puri", "पानी पूरी", 120, 3.0, 18.0, 4.0, 2.0, "Snack", true, "6 pieces", "golgappa street"),
    IndianFoodItem("56", "Bhel Puri", "भेल पूरी", 160, 4.0, 28.0, 4.0, 4.0, "Snack", true, "1 plate", "puffed rice street"),
    IndianFoodItem("57", "Pav Bhaji", "पाव भाजी", 320, 8.0, 42.0, 12.0, 8.0, "Meal", true, "1 plate", "mumbai mashed veg"),
    IndianFoodItem("58", "Misal Pav", "मिसल पाव", 280, 12.0, 32.0, 8.0, 8.0, "Meal", true, "1 plate", "maharashtra spicy sprout"),
    IndianFoodItem("59", "Dhokla", "ढोकला", 140, 6.0, 22.0, 3.0, 3.0, "Snack", true, "3 pieces", "gujarati steamed"),
    IndianFoodItem("60", "Handvo", "हांडवो", 220, 8.0, 28.0, 8.0, 5.0, "Snack", true, "1 piece", "gujarati savory cake"),
    IndianFoodItem("61", "Khandvi", "खांडवी", 160, 6.0, 18.0, 7.0, 2.0, "Snack", true, "5 pieces", "gujarati rolled"),
    IndianFoodItem("62", "Undhiyu", "उंधियू", 260, 8.0, 26.0, 14.0, 8.0, "Curry", true, "1 bowl", "gujarati mixed veg"),
    IndianFoodItem("63", "Aloo Tikki", "आलू टिक्की", 180, 3.0, 24.0, 8.0, 3.0, "Snack", true, "2 pieces", "potato patty"),
    IndianFoodItem("64", "Chole Kulche", "छोले कुलचे", 380, 14.0, 52.0, 12.0, 10.0, "Meal", true, "1 plate", "amritsari chickpea"),
    IndianFoodItem("65", "Sarson Ka Saag", "सरसों का साग", 140, 6.0, 12.0, 6.0, 6.0, "Curry", true, "1 bowl", "mustard green punjabi"),
    IndianFoodItem("66", "Makki Ki Roti", "मक्की की रोटी", 140, 3.0, 28.0, 2.0, 4.0, "Bread", true, "1 piece", "corn bread punjabi"),
    IndianFoodItem("67", "Rogan Josh (Paneer)", "पनीर रोगन जोश", 280, 14.0, 10.0, 20.0, 3.0, "Curry", true, "1 bowl", "kashmiri cottage"),
    IndianFoodItem("68", "Navratan Korma", "नवरत्न कोर्मा", 280, 10.0, 16.0, 18.0, 4.0, "Curry", true, "1 bowl", "mixed veg creamy"),
    IndianFoodItem("69", "Soya Chaap", "सोया चाप", 240, 18.0, 14.0, 12.0, 5.0, "Curry", true, "4 pieces", "soya meat substitute"),
    IndianFoodItem("70", "Tofu Stir Fry", "टोफू स्टर फ्राई", 200, 16.0, 10.0, 12.0, 4.0, "Curry", true, "1 bowl", "tofu healthy vegan"),
    IndianFoodItem("71", "Biryani (Veg)", "वेज बिरयानी", 320, 10.0, 52.0, 8.0, 4.0, "Rice", true, "1 plate", "veg rice layered"),
    IndianFoodItem("72", "Pulao", "पुलाव", 220, 5.0, 38.0, 6.0, 2.0, "Rice", true, "1 plate", "veg rice light"),
    IndianFoodItem("73", "Khichdi", "खिचड़ी", 180, 8.0, 28.0, 4.0, 4.0, "Meal", true, "1 bowl", "rice lentil comfort"),
    IndianFoodItem("74", "Curd Rice", "दही चावल", 160, 6.0, 26.0, 3.0, 1.0, "Meal", true, "1 bowl", "south yogurt rice"),
    IndianFoodItem("75", "Lemon Rice", "नींबू चावल", 200, 4.0, 36.0, 5.0, 2.0, "Rice", true, "1 plate", "south tangy"),
    IndianFoodItem("76", "Tamarind Rice", "इमली चावल", 220, 4.0, 38.0, 6.0, 2.0, "Rice", true, "1 plate", "south tamarind"),
    IndianFoodItem("77", "Pongal", "पोंगल", 200, 7.0, 32.0, 5.0, 2.0, "Breakfast", true, "1 bowl", "south rice lentil"),
    IndianFoodItem("78", "Medu Vada", "मेदू वड़ा", 140, 5.0, 22.0, 4.0, 2.0, "Breakfast", true, "2 pieces", "south lentil doughnut"),
    IndianFoodItem("79", "Uttapam", "उत्तपम", 160, 5.0, 26.0, 4.0, 3.0, "Breakfast", true, "1 piece", "south thick pancake"),
    IndianFoodItem("80", "Ragi Mudde", "रागी मुद्दे", 160, 4.0, 30.0, 2.0, 5.0, "Meal", true, "1 piece", "karnataka finger millet")
)
