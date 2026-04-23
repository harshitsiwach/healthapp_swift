package com.aihealthappoffline.android.ui.screens.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Female
import androidx.compose.material.icons.filled.Male
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.aihealthappoffline.android.ui.theme.NeonBlue
import com.aihealthappoffline.android.ui.theme.NeonGreen
import com.aihealthappoffline.android.ui.theme.NeonOrange
import com.aihealthappoffline.android.ui.theme.NeonPurple
import com.aihealthappoffline.android.viewmodels.OnboardingViewModel
import java.util.Calendar

@Composable
fun OnboardingScreen(
    onComplete: () -> Unit,
    viewModel: OnboardingViewModel = viewModel()
) {
    var step by remember { mutableIntStateOf(0) }
    val totalSteps = 4
    val progress = (step + 1) / totalSteps.toFloat()

    Scaffold(
        bottomBar = {
            Column(modifier = Modifier.padding(16.dp)) {
                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .clip(RoundedCornerShape(3.dp)),
                    color = NeonGreen,
                    trackColor = MaterialTheme.colorScheme.surfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    if (step > 0) {
                        OutlinedButton(
                            onClick = { step-- },
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text("Back")
                        }
                    } else {
                        Spacer(modifier = Modifier.width(80.dp))
                    }
                    Button(
                        onClick = {
                            if (step < totalSteps - 1) {
                                step++
                            } else {
                                viewModel.saveProfile()
                                onComplete()
                            }
                        },
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = NeonGreen)
                    ) {
                        Text(if (step == totalSteps - 1) "Get Started" else "Next")
                        if (step < totalSteps - 1) {
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(Icons.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(16.dp))
                        }
                    }
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 24.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(32.dp))
            StepIndicator(current = step, total = totalSteps)
            Spacer(modifier = Modifier.height(24.dp))

            AnimatedContent(
                targetState = step,
                transitionSpec = {
                    (slideInHorizontally { it } + fadeIn()) togetherWith
                            (slideOutHorizontally { -it } + fadeOut())
                },
                label = "step"
            ) { targetStep ->
                when (targetStep) {
                    0 -> StepBasicInfo(viewModel)
                    1 -> StepPhysicalData(viewModel)
                    2 -> StepPreferences(viewModel)
                    3 -> StepGoals(viewModel)
                }
            }
        }
    }
}

@Composable
fun StepIndicator(current: Int, total: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        repeat(total) { index ->
            Box(
                modifier = Modifier
                    .size(10.dp)
                    .clip(CircleShape)
                    .background(
                        if (index <= current) NeonGreen
                        else MaterialTheme.colorScheme.surfaceVariant
                    )
            )
        }
    }
}

@Composable
fun StepBasicInfo(viewModel: OnboardingViewModel) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            "Let's get to know you",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            "This helps us personalize your health journey",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(32.dp))

        // Gender
        Text("Gender", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
        Spacer(modifier = Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            GenderChip(
                label = "Male",
                icon = Icons.Filled.Male,
                selected = viewModel.gender == "Male",
                onClick = { viewModel.gender = "Male" }
            )
            GenderChip(
                label = "Female",
                icon = Icons.Filled.Female,
                selected = viewModel.gender == "Female",
                onClick = { viewModel.gender = "Female" }
            )
            GenderChip(
                label = "Other",
                icon = null,
                selected = viewModel.gender == "Other",
                onClick = { viewModel.gender = "Other" }
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Workouts per week
        Text("Workouts per week", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
        Spacer(modifier = Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            repeat(8) { i ->
                WorkoutChip(
                    count = i,
                    selected = viewModel.workoutsPerWeek == i,
                    onClick = { viewModel.workoutsPerWeek = i }
                )
            }
        }
    }
}

@Composable
fun StepPhysicalData(viewModel: OnboardingViewModel) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            "Your body stats",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            "Used to calculate your daily calorie needs",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(32.dp))

        // Age
        Text("Age: ${viewModel.age} years", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
        Slider(
            value = viewModel.age.toFloat(),
            onValueChange = { viewModel.age = it.toInt() },
            valueRange = 13f..90f,
            steps = 76,
            colors = SliderDefaults.colors(thumbColor = NeonGreen, activeTrackColor = NeonGreen),
            modifier = Modifier.padding(horizontal = 8.dp)
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Height
        Text("Height: ${viewModel.heightCm.toInt()} cm", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
        Slider(
            value = viewModel.heightCm.toFloat(),
            onValueChange = { viewModel.heightCm = it.toDouble() },
            valueRange = 120f..220f,
            steps = 99,
            colors = SliderDefaults.colors(thumbColor = NeonBlue, activeTrackColor = NeonBlue),
            modifier = Modifier.padding(horizontal = 8.dp)
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Weight
        Text("Weight: ${viewModel.weightKg.toInt()} kg", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
        Slider(
            value = viewModel.weightKg.toFloat(),
            onValueChange = { viewModel.weightKg = it.toDouble() },
            valueRange = 30f..150f,
            steps = 119,
            colors = SliderDefaults.colors(thumbColor = NeonOrange, activeTrackColor = NeonOrange),
            modifier = Modifier.padding(horizontal = 8.dp)
        )

        // BMI preview
        val bmi = viewModel.weightKg / ((viewModel.heightCm / 100) * (viewModel.heightCm / 100))
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            "BMI: ${String.format("%.1f", bmi)}",
            style = MaterialTheme.typography.bodyLarge,
            color = when {
                bmi < 18.5 -> NeonBlue
                bmi < 25 -> NeonGreen
                bmi < 30 -> NeonOrange
                else -> Color(0xFFFF5252)
            },
            fontWeight = FontWeight.Bold
        )
        Text(
            when {
                bmi < 18.5 -> "Underweight"
                bmi < 25 -> "Healthy weight"
                bmi < 30 -> "Overweight"
                else -> "Obese"
            },
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun StepPreferences(viewModel: OnboardingViewModel) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            "Your goals & diet",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            "We'll tailor everything to your preferences",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(32.dp))

        // Goal
        Text("Primary Goal", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
        Spacer(modifier = Modifier.height(12.dp))
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            GoalCard(
                title = "Lose Weight",
                subtitle = "Calorie deficit, focused fat loss",
                selected = viewModel.goal == "lose",
                color = NeonBlue,
                onClick = { viewModel.goal = "lose" }
            )
            GoalCard(
                title = "Maintain",
                subtitle = "Balanced intake, stay healthy",
                selected = viewModel.goal == "maintain",
                color = NeonGreen,
                onClick = { viewModel.goal = "maintain" }
            )
            GoalCard(
                title = "Gain Muscle",
                subtitle = "Calorie surplus, protein focus",
                selected = viewModel.goal == "gain",
                color = NeonOrange,
                onClick = { viewModel.goal = "gain" }
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Dietary preference
        Text("Dietary Preference", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground)
        Spacer(modifier = Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            DietChip("Vegetarian", viewModel.dietaryPreference == "vegetarian") { viewModel.dietaryPreference = "vegetarian" }
            DietChip("Vegan", viewModel.dietaryPreference == "vegan") { viewModel.dietaryPreference = "vegan" }
            DietChip("Eggetarian", viewModel.dietaryPreference == "eggetarian") { viewModel.dietaryPreference = "eggetarian" }
            DietChip("Non-Veg", viewModel.dietaryPreference == "non-vegetarian") { viewModel.dietaryPreference = "non-vegetarian" }
        }
    }
}

@Composable
fun StepGoals(viewModel: OnboardingViewModel) {
    val targets = viewModel.calculateTargets()
    val calories = targets.calories
    val protein = targets.protein
    val carbs = targets.carbs
    val fat = targets.fat

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            "Your daily targets",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            "Based on your stats and goals",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(32.dp))

        // Calorie ring
        Box(
            modifier = Modifier
                .size(180.dp)
                .clip(CircleShape)
                .background(NeonGreen.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    "$calories",
                    style = MaterialTheme.typography.displaySmall,
                    color = NeonGreen,
                    fontWeight = FontWeight.Bold
                )
                Text("kcal/day", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Macros
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            MacroTarget("Protein", "${protein}g", Color(0xFFFF5252))
            MacroTarget("Carbs", "${carbs}g", Color(0xFFFFAB40))
            MacroTarget("Fat", "${fat}g", Color(0xFFFFD740))
        }

        Spacer(modifier = Modifier.height(32.dp))

        Text(
            "You're all set! We'll help you hit these targets every day.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
fun GenderChip(label: String, icon: androidx.compose.ui.graphics.vector.ImageVector?, selected: Boolean, onClick: () -> Unit) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (icon != null) {
                    Icon(icon, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                }
                Text(label)
            }
        },
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = NeonGreen.copy(alpha = 0.2f),
            selectedLabelColor = NeonGreen
        )
    )
}

@Composable
fun WorkoutChip(count: Int, selected: Boolean, onClick: () -> Unit) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = { Text("$count") },
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = NeonPurple.copy(alpha = 0.2f),
            selectedLabelColor = NeonPurple
        )
    )
}

@Composable
fun GoalCard(title: String, subtitle: String, selected: Boolean, color: Color, onClick: () -> Unit) {
    val bgColor = if (selected) color.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant
    val borderColor = if (selected) color else MaterialTheme.colorScheme.outline

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(bgColor)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground, fontWeight = FontWeight.SemiBold)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        AnimatedVisibility(visible = selected) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = color, modifier = Modifier.size(24.dp))
        }
    }
}

@Composable
fun DietChip(label: String, selected: Boolean, onClick: () -> Unit) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = { Text(label) },
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = NeonBlue.copy(alpha = 0.2f),
            selectedLabelColor = NeonBlue
        )
    )
}

@Composable
fun MacroTarget(label: String, value: String, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(color.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Text(value, style = MaterialTheme.typography.titleMedium, color = color, fontWeight = FontWeight.Bold)
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
