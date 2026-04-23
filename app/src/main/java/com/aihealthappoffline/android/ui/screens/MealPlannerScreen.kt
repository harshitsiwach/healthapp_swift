package com.aihealthappoffline.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CopyAll
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
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
import com.aihealthappoffline.android.ui.theme.NeonGreen
import com.aihealthappoffline.android.ui.theme.NeonOrange
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

data class MealPlan(
    val day: String,
    val name: String,
    val breakfast: String,
    val lunch: String,
    val dinner: String,
    val snacks: String
)

val weeklyPlans = listOf(
    MealPlan("Monday", "Weight Loss", "Oatmeal with fruits", "Grilled chicken salad", "Quinoa with veggies", "Green apple"),
    MealPlan("Tuesday", "Balance", "Eggs & toast", "Dal rice with curd", "Roti with paneer", "Mixed nuts"),
    MealPlan("Wednesday", "High Protein", "Protein shake", "Fish curry with rice", "Chicken grill", "Greek yogurt"),
    MealPlan("Thursday", "Vegetarian", "Paneer paratha", "Rajma chawal", "Vegetable biryani", "Fruit chaat"),
    MealPlan("Friday", "Light", "Smoothie bowl", "Grilled fish with salad", "Moong dal tadka", "Vegetable sticks"),
    MealPlan("Saturday", "High Energy", "Peanut butter toast", "Chicken sandwich", "Bhelpuri", "Protein bar"),
    MealPlan("Sunday", "Cheat Day", "Idli sambar", "Biryani feast", "Pav bhaji", "Ice cream")
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MealPlannerScreen() {
    var selectedPlan by remember { mutableIntStateOf(0) }
    var showBottomSheet by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Meal Planner", fontWeight = FontWeight.Bold) }
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
                    "Choose Your Plan",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "Select a weekly meal plan that fits your goals",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
            }
            
            item {
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    weeklyPlans.forEachIndexed { index, plan ->
                        FilterChip(
                            selected = selectedPlan == index,
                            onClick = { selectedPlan = index },
                            label = { Text(plan.day) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = NeonGreen,
                                selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                            )
                        )
                    }
                }
                Spacer(modifier = Modifier.height(20.dp))
            }
            
            item {
                val selected = weeklyPlans[selectedPlan]
                PlanCard(plan = selected, onExport = { showBottomSheet = true })
                Spacer(modifier = Modifier.height(16.dp))
            }
        }
        
        if (showBottomSheet) {
            ModalBottomSheet(
                onDismissRequest = { showBottomSheet = false },
                sheetState = sheetState
            ) {
                GroceryListSheet()
            }
        }
    }
}

@Composable
private fun PlanCard(plan: MealPlan, onExport: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(20.dp)
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        plan.day,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "Plan: ${plan.name}",
                        style = MaterialTheme.typography.bodySmall,
                        color = NeonOrange
                    )
                }
                Row {
                    IconButton(onClick = onExport) {
                        Icon(
                            Icons.Filled.CopyAll,
                            contentDescription = "Export list",
                            tint = NeonGreen
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            MealItem("Breakfast", plan.breakfast)
            MealItem("Lunch", plan.lunch)
            MealItem("Dinner", plan.dinner)
            MealItem("Snacks", plan.snacks)
        }
    }
}

@Composable
private fun MealItem(meal: String, food: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            meal,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.width(80.dp)
        )
        Text(
            food,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun GroceryListSheet() {
    var copied by remember { mutableStateOf(false) }
    
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp)
    ) {
        Text(
            "Grocery List",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        val groceries = listOf(
            "Oats / Oatmeal" to "500g",
            "Fresh Fruits" to "1kg",
            "Chicken Breast" to "500g",
            "Quinoa / Rice" to "1kg",
            "Fresh Vegetables" to "1kg",
            "Paneer / Tofu" to "250g",
            "Greek Yogurt" to "500g",
            "Mixed Nuts" to "200g",
            "Eggs" to "12 pieces",
            "Dal / Lentils" to "500g"
        )
        
        groceries.forEachIndexed { index, (item, qty) ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant)
                    .padding(12.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(item, fontWeight = FontWeight.Medium)
                Text(qty, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(NeonGreen.copy(alpha = 0.2f))
                .clickable {
                    copied = true
                }
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    if (copied) Icons.Filled.Check else Icons.Filled.CopyAll,
                    contentDescription = null,
                    tint = NeonGreen
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    if (copied) "Copied!" else "Copy List",
                    color = NeonGreen,
                    fontWeight = FontWeight.Bold
                )
            }
        }
        
        Spacer(modifier = Modifier.height(32.dp))
    }
}