package com.aihealthappoffline.android.data.local

import android.content.Context
import com.aihealthappoffline.android.data.models.IndianFoodItem
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class FoodCalorieDatabase(private val context: Context) {

    private val foods: Map<String, IndianFoodItem> = allFoods.associateBy { it.name.lowercase() }

    suspend fun searchFood(query: String): List<IndianFoodItem> = withContext(Dispatchers.IO) {
        val lowerQuery = query.lowercase()
        allFoods.filter { 
            it.name.lowercase().contains(lowerQuery) || 
            it.nameHindi?.lowercase()?.contains(lowerQuery) == true ||
            it.tags.lowercase().contains(lowerQuery)
        }.sortedByDescending { it.name.lowercase().startsWith(lowerQuery) }
    }

    fun findByLabel(label: String): IndianFoodItem? {
        val lowerLabel = label.lowercase()
        return foods[lowerLabel] ?: run {
            allFoods.find { food ->
                food.name.lowercase().contains(lowerLabel) ||
                food.tags.split(",").any { it.trim().lowercase().contains(lowerLabel) }
            }
        }
    }

    fun getFoodByName(name: String): IndianFoodItem? = foods[name.lowercase()]

    fun getAllCategories(): List<String> = allFoods.map { it.category }.distinct().sorted()

    companion object {
        val allFoods = listOf(
            IndianFoodItem("aaloo bhujiya", "आलू भुजिया", calories = 280, proteinG = 4.5, carbsG = 38.0, fatG = 12.0, fiberG = 3.2, category = "Snack", tags = "potato,snack,fried"),
            IndianFoodItem("aaloo paratha", "आलू पराथा", calories = 320, proteinG = 6.0, carbsG = 45.0, fatG = 12.5, fiberG = 4.0, category = "Main", tags = "potato,parantha,bread"),
            IndianFoodItem("banana", "केला", calories = 89, proteinG = 1.1, carbsG = 22.8, fatG = 0.3, fiberG = 2.6, category = "Fruit", tags = "fruit,sweet"),
            IndianFoodItem("bhuna chicken", "भुना चिकन", calories = 320, proteinG = 28.0, carbsG = 8.0, fatG = 18.0, fiberG = 2.0, category = "Non-Veg", tags = "chicken,curry,spicy"),
            IndianFoodItem("biryani chicken", "चिकन बिरयानी", calories = 380, proteinG = 22.0, carbsG = 48.0, fatG = 14.0, fiberG = 2.5, category = "Rice", tags = "rice,chicken,spicy"),
            IndianFoodItem("biryani egg", "अंडा बिरयानी", calories = 320, proteinG = 14.0, carbsG = 42.0, fatG = 12.0, fiberG = 1.5, category = "Rice", tags = "rice,egg,spicy"),
            IndianFoodItem("biryani vegetable", "वेज बिरयानी", calories = 280, proteinG = 6.0, carbsG = 52.0, fatG = 6.0, fiberG = 4.0, category = "Rice", tags = "rice,vegetable,spicy"),
            IndianFoodItem("bisleri basundi", "बिसलेरी बसंडी", calories = 240, proteinG = 6.0, carbsG = 32.0, fatG = 10.0, fiberG = 0.5, category = "Sweet", tags = "milk,sweet,dessert"),
            IndianFoodItem("boiled egg", "उबला अंडा", calories = 78, proteinG = 6.3, carbsG = 0.6, fatG = 5.3, fiberG = 0.0, category = "Non-Veg", tags = "egg,protein"),
            IndianFoodItem("butter chicken", "बटर चिकन", calories = 450, proteinG = 25.0, carbsG = 12.0, fatG = 32.0, fiberG = 1.5, category = "Non-Veg", tags = "chicken,cream,curry"),
            IndianFoodItem("chai", "चाय", calories = 70, proteinG = 2.0, carbsG = 10.0, fatG = 2.5, fiberG = 0.0, category = "Beverage", tags = "tea,milk,hot"),
            IndianFoodItem("channa chaat", "छना चाट", calories = 220, proteinG = 10.0, carbsG = 30.0, fatG = 7.0, fiberG = 8.0, category = "Snack", tags = "chickpeas,snack,spicy"),
            IndianFoodItem("channa dal", "छना दाल", calories = 230, proteinG = 12.0, carbsG = 35.0, fatG = 6.0, fiberG = 10.0, category = "Dal", tags = "chickpeas,protein,vegetarian"),
            IndianFoodItem("chapatti", "रोटी", calories = 120, proteinG = 3.0, carbsG = 25.0, fatG = 1.5, fiberG = 2.5, category = "Bread", tags = "wheat,roti,flatbread"),
            IndianFoodItem("cheese burger", "चीज बर्गर", calories = 420, proteinG = 18.0, carbsG = 38.0, fatG = 22.0, fiberG = 2.0, category = "Fast Food", tags = "burger,cheese,fast"),
            IndianFoodItem("chevdo", "चेवड़ो", calories = 440, proteinG = 8.0, carbsG = 52.0, fatG = 22.0, fiberG = 4.0, category = "Snack", tags = "snack,crunchy,fried"),
            IndianFoodItem("chicken 65", "चिकन 65", calories = 350, proteinG = 25.0, carbsG = 15.0, fatG = 20.0, fiberG = 1.5, category = "Non-Veg", tags = "chicken,fried,spicy"),
            IndianFoodItem("chicken curry", "चिकन करी", calories = 280, proteinG = 24.0, carbsG = 10.0, fatG = 16.0, fiberG = 2.0, category = "Non-Veg", tags = "chicken,curry,gravy"),
            IndianFoodItem("chicken kebab", "चिकन कबाब", calories = 220, proteinG = 28.0, carbsG = 5.0, fatG = 10.0, fiberG = 1.0, category = "Non-Veg", tags = "chicken,grilled,spicy"),
            IndianFoodItem("chocolate", "चॉकलेट", calories = 230, proteinG = 2.5, carbsG = 26.0, fatG = 13.0, fiberG = 2.0, category = "Sweet", tags = "sweet,dessert,chocolate"),
            IndianFoodItem("chole bhature", "छोले भटूरे", calories = 450, proteinG = 14.0, carbsG = 55.0, fatG = 18.0, fiberG = 8.0, category = "Main", tags = "chickpeas,curry,bread"),
            IndianFoodItem("dahi bhalla", "दही भल्ला", calories = 280, proteinG = 10.0, carbsG = 32.0, fatG = 12.0, fiberG = 3.0, category = "Snack", tags = "curd,snack,vegetarian"),
            IndianFoodItem("dahi papdi chaat", "दही पापड़ी चाट", calories = 200, proteinG = 6.0, carbsG = 28.0, fatG = 8.0, fiberG = 2.5, category = "Snack", tags = "curd,snack,crispy"),
            IndianFoodItem("dal makhani", "दाल मखनी", calories = 280, proteinG = 14.0, carbsG = 28.0, fatG = 12.0, fiberG = 7.0, category = "Dal", tags = "kidney beans,cream,vegetarian"),
            IndianFoodItem("dal tadka", "दाल तड़का", calories = 200, proteinG = 12.0, carbsG = 30.0, fatG = 5.0, fiberG = 8.0, category = "Dal", tags = "moong dal,spices,vegetarian"),
            IndianFoodItem("dal tehri", "दाल तेहरी", calories = 320, proteinG = 10.0, carbsG = 52.0, fatG = 8.0, fiberG = 6.0, category = "Rice", tags = "rice,dal,vegetarian"),
            IndianFoodItem("dhokla", "धोकला", calories = 160, proteinG = 5.0, carbsG = 22.0, fatG = 6.0, fiberG = 2.0, category = "Snack", tags = "fermented,snack,steamed"),
            IndianFoodItem("doodh pak", "दूध पाक", calories = 260, proteinG = 8.0, carbsG = 36.0, fatG = 10.0, fiberG = 1.0, category = "Sweet", tags = "milk,sweet,dessert"),
            IndianFoodItem("egg biryani", "अंडा बिरयानी", calories = 320, proteinG = 14.0, carbsG = 42.0, fatG = 12.0, fiberG = 1.5, category = "Rice", tags = "rice,egg,spicy"),
            IndianFoodItem("egg curry", "अंडा करी", calories = 240, proteinG = 12.0, carbsG = 8.0, fatG = 18.0, fiberG = 1.0, category = "Non-Veg", tags = "egg,curry,gravy"),
            IndianFoodItem("egg fried rice", "अंडा फ्राइड राइस", calories = 340, proteinG = 10.0, carbsG = 48.0, fatG = 12.0, fiberG = 1.5, category = "Rice", tags = "rice,egg,fried"),
            IndianFoodItem("egg omlette", "आमलेट", calories = 200, proteinG = 14.0, carbsG = 2.0, fatG = 14.0, fiberG = 0.0, category = "Non-Veg", tags = "egg,breakfast,protein"),
            IndianFoodItem("fish curry", "मछली करी", calories = 180, proteinG = 22.0, carbsG = 6.0, fatG = 8.0, fiberG = 1.0, category = "Non-Veg", tags = "fish,curry,spicy"),
            IndianFoodItem("fish fry", "मछली फ्राई", calories = 220, proteinG = 24.0, carbsG = 8.0, fatG = 10.0, fiberG = 0.5, category = "Non-Veg", tags = "fish,fried,spicy"),
            IndianFoodItem("fried rice", "फ्राइड राइस", calories = 320, proteinG = 6.0, carbsG = 52.0, fatG = 10.0, fiberG = 2.0, category = "Rice", tags = "rice,fried,egg"),
            IndianFoodItem("gajar ka halwa", "गाजर का हलवा", calories = 280, proteinG = 5.0, carbsG = 32.0, fatG = 14.0, fiberG = 3.0, category = "Sweet", tags = "carrot,sweet,dessert"),
            IndianFoodItem("garlic naan", "लहसुन नान", calories = 280, proteinG = 6.0, carbsG = 42.0, fatG = 10.0, fiberG = 2.0, category = "Bread", tags = "bread,garlic,tandoor"),
            IndianFoodItem("ghee rice", "घी चावल", calories = 350, proteinG = 5.0, carbsG = 52.0, fatG = 12.0, fiberG = 1.0, category = "Rice", tags = "rice,ghee,aromatic"),
            IndianFoodItem("gulab jamun", "गुलाब जामुन", calories = 280, proteinG = 4.0, carbsG = 38.0, fatG = 12.0, fiberG = 1.0, category = "Sweet", tags = "milk,sweet,dessert"),
            IndianFoodItem("haleem", "हलीम", calories = 320, proteinG = 18.0, carbsG = 28.0, fatG = 16.0, fiberG = 4.0, category = "Non-Veg", tags = "wheat,meat,spicy"),
            IndianFoodItem("idli", "इडली", calories = 140, proteinG = 5.0, carbsG = 26.0, fatG = 1.5, fiberG = 2.0, category = "South Indian", tags = "rice,fermented,steamed"),
            IndianFoodItem("jalebi", "जलेबी", calories = 320, proteinG = 3.0, carbsG = 52.0, fatG = 10.0, fiberG = 1.0, category = "Sweet", tags = "sweet,dessert,fried"),
            IndianFoodItem("kadai chicken", "कड़ई चिकन", calories = 380, proteinG = 26.0, carbsG = 14.0, fatG = 26.0, fiberG = 2.0, category = "Non-Veg", tags = "chicken,curry,spicy"),
            IndianFoodItem("kadha", "कधा", calories = 60, proteinG = 1.0, carbsG = 12.0, fatG = 1.0, fiberG = 1.0, category = "Beverage", tags = "tea,spices,hot"),
            IndianFoodItem("kaju katli", "काजू कतली", calories = 300, proteinG = 5.0, carbsG = 32.0, fatG = 16.0, fiberG = 1.5, category = "Sweet", tags = "cashew,sweet,dessert"),
            IndianFoodItem("kalakand", "कलाकंद", calories = 260, proteinG = 8.0, carbsG = 28.0, fatG = 12.0, fiberG = 1.0, category = "Sweet", tags = "milk,sweet,dessert"),
            IndianFoodItem("karela bharta", "करेला भर्ता", calories = 120, proteinG = 3.0, carbsG = 18.0, fatG = 4.0, fiberG = 5.0, category = "Vegetable", tags = "bitter gourd,vegetarian"),
            IndianFoodItem("kathi roll", "कथी रोल", calories = 380, proteinG = 16.0, carbsG = 42.0, fatG = 16.0, fiberG = 4.0, category = "Fast Food", tags = "wrap,kebab,roll"),
            IndianFoodItem("khaja", "खाज��", calories = 280, proteinG = 4.0, carbsG = 38.0, fatG = 12.0, fiberG = 2.0, category = "Sweet", tags = "sweet,dessert,fried"),
            IndianFoodItem("khichdi", "खिचड़ी", calories = 220, proteinG = 8.0, carbsG = 36.0, fatG = 5.0, fiberG = 5.0, category = "Rice", tags = "rice,dal,comfort"),
            IndianFoodItem("kichdi kadhi", "खिचड़ी कड़ी", calories = 280, proteinG = 10.0, carbsG = 42.0, fatG = 8.0, fiberG = 6.0, category = "Rice", tags = "rice,dal,curd"),
            IndianFoodItem("kofta curry", "कोफ्ता करी", calories = 320, proteinG = 12.0, carbsG = 20.0, fatG = 22.0, fiberG = 3.0, category = "Vegetable", tags = "paneer,curry,gravy"),
            IndianFoodItem("kulfi", "कुल्फी", calories = 220, proteinG = 6.0, carbsG = 24.0, fatG = 12.0, fiberG = 0.5, category = "Sweet", tags = "ice cream,milk,dessert"),
            IndianFoodItem("laddu", "लड्डू", calories = 300, proteinG = 5.0, carbsG = 42.0, fatG = 12.0, fiberG = 3.0, category = "Sweet", tags = "sweet,dessert,gram flour"),
            IndianFoodItem("lassi", "लस्सी", calories = 180, proteinG = 6.0, carbsG = 22.0, fatG = 7.0, fiberG = 0.5, category = "Beverage", tags = "yogurt,drink,sweet"),
            IndianFoodItem("lemon rice", "निंबायाचे भात", calories = 300, proteinG = 5.0, carbsG = 48.0, fatG = 8.0, fiberG = 2.0, category = "Rice", tags = "rice,lemon,spicy"),
            IndianFoodItem("lobia curry", "लोबिया करी", calories = 200, proteinG = 10.0, carbsG = 28.0, fatG = 6.0, fiberG = 8.0, category = "Dal", tags = "black eyed peas,vegetarian"),
            IndianFoodItem("makki di roti", "मक्की दी रोटी", calories = 100, proteinG = 2.0, carbsG = 20.0, fatG = 1.5, fiberG = 3.0, category = "Bread", tags = "corn,roti,flatbread"),
            IndianFoodItem("malai chicken", "मलाई चि���न", calories = 420, proteinG = 28.0, carbsG = 10.0, fatG = 30.0, fiberG = 1.5, category = "Non-Veg", tags = "chicken,cream,curry"),
            IndianFoodItem("malai kofta", "मलाई कोफ्ता", calories = 340, proteinG = 10.0, carbsG = 24.0, fatG = 24.0, fiberG = 3.0, category = "Vegetable", tags = "paneer,cream,vegetarian"),
            IndianFoodItem("mango", "आम", calories = 60, proteinG = 0.8, carbsG = 15.0, fatG = 0.4, fiberG = 1.6, category = "Fruit", tags = "fruit,sweet,summer"),
            IndianFoodItem("mango lassi", "आम लस्सी", calories = 220, proteinG = 6.0, carbsG = 32.0, fatG = 8.0, fiberG = 1.5, category = "Beverage", tags = "mango,yogurt,sweet"),
            IndianFoodItem("masala dosa", "मसाला डोसा", calories = 380, proteinG = 8.0, carbsG = 52.0, fatG = 14.0, fiberG = 4.0, category = "South Indian", tags = "rice,potato,crepe"),
            IndianFoodItem("masala paneer", "मसाला पनीर", calories = 320, proteinG = 18.0, carbsG = 12.0, fatG = 22.0, fiberG = 2.0, category = "Vegetable", tags = "paneer,spices,curry"),
            IndianFoodItem("mathri", "मथरी", calories = 320, proteinG = 5.0, carbsG = 38.0, fatG = 16.0, fiberG = 2.0, category = "Snack", tags = "snack,salty,flour"),
            IndianFoodItem("medu vada", "मेधु वडा", calories = 240, proteinG = 8.0, carbsG = 28.0, fatG = 10.0, fiberG = 3.0, category = "South Indian", tags = "urad dal,fried,snack"),
            IndianFoodItem("methi thepla", "मेथी थेपला", calories = 220, proteinG = 5.0, carbsG = 32.0, fatG = 8.0, fiberG = 4.0, category = "Bread", tags = "fenugreek,roti,flatbread"),
            IndianFoodItem("momo", "मोमो", calories = 280, proteinG = 10.0, carbsG = 36.0, fatG = 10.0, fiberG = 3.0, category = "Snack", tags = "dumpling,steam,fried"),
            IndianFoodItem("mushroom biryani", "मशरूम बिरयानी", calories = 260, proteinG = 8.0, carbsG = 42.0, fatG = 8.0, fiberG = 4.0, category = "Rice", tags = "rice,mushroom,spicy"),
            IndianFoodItem("mushroom curry", "मशरूम करी", calories = 180, proteinG = 6.0, carbsG = 16.0, fatG = 10.0, fiberG = 4.0, category = "Vegetable", tags = "mushroom,curry,vegetarian"),
            IndianFoodItem("mushroom fried rice", "मशरूम फ्राइड राइस", calories = 300, proteinG = 6.0, carbsG = 48.0, fatG = 9.0, fiberG = 3.0, category = "Rice", tags = "rice,mushroom,fried"),
            IndianFoodItem("naan", "नान", calories = 260, proteinG = 6.0, carbsG = 40.0, fatG = 9.0, fiberG = 2.0, category = "Bread", tags = "bread,tandoor,garlic"),
            IndianFoodItem("onion pakoda", "प्याज पकोडा", calories = 280, proteinG = 5.0, carbsG = 28.0, fatG = 16.0, fiberG = 3.0, category = "Snack", tags = "onion,fried,snack"),
            IndianFoodItem("onion rings", "प्याज के छल्ले", calories = 240, proteinG = 4.0, carbsG = 26.0, fatG = 14.0, fiberG = 2.5, category = "Snack", tags = "onion,fried,snack"),
            IndianFoodItem("palak paneer", "पालक पनीर", calories = 280, proteinG = 16.0, carbsG = 12.0, fatG = 20.0, fiberG = 5.0, category = "Vegetable", tags = "spinach,paneer,vegetarian"),
            IndianFoodItem("paneer butter masala", "पनीर बटर मसाला", calories = 380, proteinG = 18.0, carbsG = 14.0, fatG = 28.0, fiberG = 2.5, category = "Vegetable", tags = "paneer,cream,curry"),
            IndianFoodItem("paneer tikka", "पनीर टिक्का", calories = 280, proteinG = 20.0, carbsG = 8.0, fatG = 18.0, fiberG = 2.0, category = "Vegetable", tags = "paneer,grilled,spicy"),
            IndianFoodItem("papad", "पपड़", calories = 100, proteinG = 3.0, carbsG = 18.0, fatG = 2.0, fiberG = 1.0, category = "Snack", tags = "lentil,snack,crispy"),
            IndianFoodItem("parantha", "पराथा", calories = 280, proteinG = 5.0, carbsG = 38.0, fatG = 12.0, fiberG = 3.0, category = "Bread", tags = "potato,parantha,stuffed"),
            IndianFoodItem("pav bhaji", "पाव भाजी", calories = 380, proteinG = 10.0, carbsG = 48.0, fatG = 16.0, fiberG = 6.0, category = "Main", tags = "bread,vegetable,curry"),
            IndianFoodItem("phulka", "फुल्का", calories = 100, proteinG = 2.5, carbsG = 22.0, fatG = 1.0, fiberG = 2.0, category = "Bread", tags = "wheat,roti,flatbread"),
            IndianFoodItem("pizza", "पिज़्ज़ा", calories = 450, proteinG = 16.0, carbsG = 48.0, fatG = 22.0, fiberG = 3.0, category = "Fast Food", tags = "cheese,fast,italian"),
            IndianFoodItem("poha", "पोहा", calories = 220, proteinG = 5.0, carbsG = 36.0, fatG = 7.0, fiberG = 3.0, category = "Breakfast", tags = "rice flakes,vegetarian,breakfast"),
            IndianFoodItem("poori", "पूरी", calories = 240, proteinG = 4.0, carbsG = 32.0, fatG = 10.0, fiberG = 2.0, category = "Bread", tags = "wheat,fried,puffed"),
            IndianFoodItem("popcorn", "पॉपकॉर्न", calories = 180, proteinG = 3.0, carbsG = 20.0, fatG = 10.0, fiberG = 3.0, category = "Snack", tags = "corn,snack,butter"),
            IndianFoodItem("prawns curry", "प्रॉन करी", calories = 200, proteinG = 24.0, carbsG = 8.0, fatG = 9.0, fiberG = 1.0, category = "Non-Veg", tags = "prawns,curry,spicy"),
            IndianFoodItem("pulao veg", "पुलाव वेज", calories = 280, proteinG = 6.0, carbsG = 44.0, fatG = 9.0, fiberG = 4.0, category = "Rice", tags = "rice,vegetables,aromatic"),
            IndianFoodItem("puri sabzi", "पूरी सब्जी", calories = 340, proteinG = 8.0, carbsG = 42.0, fatG = 14.0, fiberG = 5.0, category = "Main", tags = "bread,vegetable,curry"),
            IndianFoodItem("rai mirchi ka achaar", "राय मिर्ची का अचार", calories = 30, proteinG = 0.5, carbsG = 5.0, fatG = 1.0, fiberG = 1.5, category = "Pickle", tags = "chilli,pickle,sour"),
            IndianFoodItem("rajma", "राजमा", calories = 220, proteinG = 12.0, carbsG = 35.0, fatG = 4.0, fiberG = 10.0, category = "Dal", tags = "kidney beans,protein,vegetarian"),
            IndianFoodItem("rajma chawal", "राजमा चावल", calories = 380, proteinG = 14.0, carbsG = 58.0, fatG = 10.0, fiberG = 12.0, category = "Rice", tags = "rice,kidney beans,comfort"),
            IndianFoodItem("rasgulla", "रसगुल्ला", calories = 200, proteinG = 4.0, carbsG = 32.0, fatG = 5.0, fiberG = 0.5, category = "Sweet", tags = "milk,sweet,dessert"),
            IndianFoodItem("rasmalai", "रसमलाई", calories = 260, proteinG = 8.0, carbsG = 28.0, fatG = 12.0, fiberG = 0.5, category = "Sweet", tags = "milk,sweet,dessert"),
            IndianFoodItem("ratalu fry", "रतालू फ्राई", calories = 180, proteinG = 3.0, carbsG = 28.0, fatG = 7.0, fiberG = 4.0, category = "Vegetable", tags = "yam,fried,spicy"),
            IndianFoodItem("rice", "चावल", calories = 200, proteinG = 4.0, carbsG = 45.0, fatG = 0.5, fiberG = 0.5, category = "Rice", tags = "rice,basmati,white"),
            IndianFoodItem("roti", "रोटी", calories = 100, proteinG = 2.5, carbsG = 22.0, fatG = 1.0, fiberG = 2.0, category = "Bread", tags = "wheat,roti,flatbread"),
            IndianFoodItem("sabji", "सब्जी", calories = 120, proteinG = 3.0, carbsG = 18.0, fatG = 5.0, fiberG = 5.0, category = "Vegetable", tags = "vegetable,curry,mixed"),
            IndianFoodItem("samosa", "समोसा", calories = 280, proteinG = 5.0, carbsG = 32.0, fatG = 14.0, fiberG = 3.0, category = "Snack", tags = "potato,fried,snack"),
            IndianFoodItem("sandesh", "संदेश", calories = 220, proteinG = 6.0, carbsG = 28.0, fatG = 10.0, fiberG = 0.5, category = "Sweet", tags = "milk,sweet,dessert"),
            IndianFoodItem("sangri", "संगरी", calories = 180, proteinG = 6.0, carbsG = 28.0, fatG = 5.0, fiberG = 6.0, category = "Vegetable", tags = "desert bean,vegetarian"),
            IndianFoodItem("sattu", "सत्तू", calories = 160, proteinG = 8.0, carbsG = 24.0, fatG = 4.0, fiberG = 6.0, category = "Beverage", tags = "barley,drink,protein"),
            IndianFoodItem("shahi paneer", "शाही पनीर", calories = 360, proteinG = 18.0, carbsG = 14.0, fatG = 26.0, fiberG = 2.0, category = "Vegetable", tags = "paneer,cream,royal"),
            IndianFoodItem("shahee tukda", "शाही टुक्दा", calories = 340, proteinG = 10.0, carbsG = 32.0, fatG = 20.0, fiberG = 2.0, category = "Sweet", tags = "bread,milk,sweet"),
            IndianFoodItem("shavai", "शवाई", calories = 240, proteinG = 5.0, carbsG = 42.0, fatG = 6.0, fiberG = 2.0, category = "Rice", tags = "vermicelli,sweet"),
            IndianFoodItem("sheermal", "शीरमल", calories = 280, proteinG = 6.0, carbsG = 38.0, fatG = 12.0, fiberG = 2.0, category = "Bread", tags = "wheat,bread,sweet"),
            IndianFoodItem("shezwan fried rice", "शेज़वान फ्राइड राइस", calories = 340, proteinG = 8.0, carbsG = 48.0, fatG = 12.0, fiberG = 2.0, category = "Rice", tags = "rice,spicy,fried"),
            IndianFoodItem("soya chaap", "सोया चाप", calories = 180, proteinG = 16.0, carbsG = 8.0, fatG = 8.0, fiberG = 4.0, category = "Vegetable", tags = "soya,protein,vegetarian"),
            IndianFoodItem("soya curry", "सोया करी", calories = 160, proteinG = 14.0, carbsG = 10.0, fatG = 7.0, fiberG = 5.0, category = "Vegetable", tags = "soya,curry,protein"),
            IndianFoodItem("spanish omelette", "स्पेनिश ओमलेट", calories = 220, proteinG = 12.0, carbsG = 8.0, fatG = 16.0, fiberG = 2.0, category = "Breakfast", tags = "egg,vegetables,protein"),
            IndianFoodItem("stuffed parantha", "स्टफ्ड पराथा", calories = 340, proteinG = 7.0, carbsG = 42.0, fatG = 14.0, fiberG = 4.0, category = "Bread", tags = "potato,parantha,stuffed"),
            IndianFoodItem("tandoori chicken", "तंदूरी चिकन", calories = 260, proteinG = 32.0, carbsG = 6.0, fatG = 12.0, fiberG = 1.5, category = "Non-Veg", tags = "chicken,grilled,spicy"),
            IndianFoodItem("tandoori roti", "तंदूरी रोटी", calories = 120, proteinG = 3.0, carbsG = 22.0, fatG = 2.5, fiberG = 2.5, category = "Bread", tags = "wheat,tandoor,bread"),
            IndianFoodItem("tea", "चाय", calories = 60, proteinG = 1.5, carbsG = 10.0, fatG = 2.0, fiberG = 0.0, category = "Beverage", tags = "tea,milk,hot"),
            IndianFoodItem("thepla", "थेपला", calories = 200, proteinG = 4.0, carbsG = 28.0, fatG = 8.0, fiberG = 3.0, category = "Bread", tags = "wheat,spices,flatbread"),
            IndianFoodItem("thumbs up", "थम्स अप", calories = 140, proteinG = 0.0, carbsG = 35.0, fatG = 0.0, fiberG = 0.0, category = "Beverage", tags = "soda,sweet"),
            IndianFoodItem("tinda bharta", "तिंडा भर्ता", calories = 140, proteinG = 4.0, carbsG = 22.0, fatG = 4.0, fiberG = 6.0, category = "Vegetable", tags = "ridge gourd,vegetarian"),
            IndianFoodItem("toast sandwich", "टोस्ट सैंडविच", calories = 320, proteinG = 10.0, carbsG = 32.0, fatG = 16.0, fiberG = 3.0, category = "Fast Food", tags = "bread,cheese,toast"),
            IndianFoodItem("tomato soup", "टमाटर सूप", calories = 80, proteinG = 2.0, carbsG = 14.0, fatG = 2.5, fiberG = 2.0, category = "Soup", tags = "tomato,soup,hot"),
            IndianFoodItem("triple schezwan rice", "ट्रिपल शेज़वान राइस", calories = 380, proteinG = 10.0, carbsG = 52.0, fatG = 14.0, fiberG = 3.0, category = "Rice", tags = "rice,spicy,mixed"),
            IndianFoodItem("tunday kabab", "तुनड्या कबाब", calories = 280, proteinG = 22.0, carbsG = 12.0, fatG = 16.0, fiberG = 3.0, category = "Non-Veg", tags = "meat,grilled,spicy"),
            IndianFoodItem("upma", "उपमा", calories = 220, proteinG = 5.0, carbsG = 32.0, fatG = 8.0, fiberG = 4.0, category = "South Indian", tags = "semolina,vegetarian"),
            IndianFoodItem("uttapam", "उत्तपम", calories = 240, proteinG = 6.0, carbsG = 34.0, fatG = 8.0, fiberG = 4.0, category = "South Indian", tags = "rice,vegetables,thick"),
            IndianFoodItem("vada pav", "वड़ा पाव", calories = 320, proteinG = 8.0, carbsG = 38.0, fatG = 14.0, fiberG = 4.0, category = "Fast Food", tags = "potato,bun,spicy"),
            IndianFoodItem("veg biryani", "वेज बिरयानी", calories = 280, proteinG = 6.0, carbsG = 52.0, fatG = 6.0, fiberG = 4.0, category = "Rice", tags = "rice,vegetable,spicy"),
            IndianFoodItem("veg fried rice", "वेज फ्राइड राइस", calories = 280, proteinG = 5.0, carbsG = 46.0, fatG = 8.0, fiberG = 3.0, category = "Rice", tags = "rice,vegetables,fried"),
            IndianFoodItem("veg kolhapuri", "वेज कोल्हापुरी", calories = 220, proteinG = 6.0, carbsG = 28.0, fatG = 10.0, fiberG = 6.0, category = "Vegetable", tags = "mixed vegetables,spicy"),
            IndianFoodItem("veg manchurian", "वेज मंचूरियन", calories = 280, proteinG = 8.0, carbsG = 32.0, fatG = 14.0, fiberG = 4.0, category = "Chinese", tags = "vegetable,chinese,gravy"),
            IndianFoodItem("veg momos", "वेज मोमोस", calories = 220, proteinG = 6.0, carbsG = 32.0, fatG = 8.0, fiberG = 4.0, category = "Snack", tags = "vegetable,dumpling,steam"),
            IndianFoodItem("veg noodles", "वेज नूडल्स", calories = 260, proteinG = 6.0, carbsG = 38.0, fatG = 10.0, fiberG = 3.0, category = "Chinese", tags = "noodles,vegetable,chinese"),
            IndianFoodItem("veg pulav", "वेज पुलाव", calories = 260, proteinG = 5.0, carbsG = 42.0, fatG = 8.0, fiberG = 4.0, category = "Rice", tags = "rice,vegetables,aromatic"),
            IndianFoodItem("veg steam rice", "वेज स्टीम राइस", calories = 200, proteinG = 4.0, carbsG = 40.0, fatG = 3.0, fiberG = 3.0, category = "Rice", tags = "rice,vegetable,light"),
            IndianFoodItem("water", "पानी", calories = 0, proteinG = 0.0, carbsG = 0.0, fatG = 0.0, fiberG = 0.0, category = "Beverage", tags = "water,drink"),
            IndianFoodItem("yogurt", "दही", calories = 60, proteinG = 3.0, carbsG = 5.0, fatG = 3.0, fiberG = 0.0, category = "Dairy", tags = "curd,yogurt,probiotic")
        )
    }
}