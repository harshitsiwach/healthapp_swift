package com.aihealthappoffline.android

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.LocalDining
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.Chat
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.LocalDining
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.aihealthappoffline.android.ui.screens.ChatScreen
import com.aihealthappoffline.android.ui.screens.DashboardScreen
import com.aihealthappoffline.android.ui.screens.FamilyProfilesScreen
import com.aihealthappoffline.android.ui.screens.FoodLogScreen
import com.aihealthappoffline.android.ui.screens.MealPlannerScreen
import com.aihealthappoffline.android.ui.screens.PeriodTrackingScreen
import com.aihealthappoffline.android.ui.screens.SettingsScreen
import com.aihealthappoffline.android.ui.screens.SleepScreen
import com.aihealthappoffline.android.ui.screens.WeightScreen
import com.aihealthappoffline.android.ui.screens.onboarding.OnboardingScreen
import com.aihealthappoffline.android.ui.theme.HealthAppTheme
import com.aihealthappoffline.android.viewmodels.DashboardViewModel

const val GOOGLE_FIT_REQUEST_CODE = 1001

class MainActivity : ComponentActivity() {
    
    private var dashboardViewModel: DashboardViewModel? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        dashboardViewModel = DashboardViewModel(application)
        
        setContent {
            HealthAppTheme {
                val navController = rememberNavController()
                var showOnboarding by remember { mutableStateOf(false) }
                var isChecking by remember { mutableStateOf(true) }

                val context = LocalContext.current
                val activity = context as? MainActivity
                val vm = remember { activity?.dashboardViewModel }

                LaunchedEffect(Unit) {
                    val repo = HealthAppApplication.database.userProfileDao()
                    showOnboarding = repo.getCount() == 0
                    isChecking = false
                }

                when {
                    isChecking -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("HealthApp", style = MaterialTheme.typography.headlineLarge, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                        }
                    }
                    showOnboarding -> {
                        OnboardingScreen(onComplete = { showOnboarding = false })
                    }
                    else -> {
                        MainApp(navController = navController, sharedViewModel = vm)
                    }
                }
            }
        }
    }
    
    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == GOOGLE_FIT_REQUEST_CODE) {
            dashboardViewModel?.checkGoogleFit()
        }
    }
}

sealed class Screen(val route: String, val label: String, val selectedIcon: ImageVector, val unselectedIcon: ImageVector) {
    object Dashboard : Screen("dashboard", "Home", Icons.Filled.Home, Icons.Outlined.Home)
    object FoodLog : Screen("food", "Food", Icons.Filled.LocalDining, Icons.Outlined.LocalDining)
    object Chat : Screen("chat", "AI", Icons.Filled.Chat, Icons.Outlined.Chat)
    object Settings : Screen("settings", "Settings", Icons.Filled.Settings, Icons.Outlined.Settings)
}

val bottomNavItems = listOf(
    Screen.Dashboard,
    Screen.FoodLog,
    Screen.Chat,
    Screen.Settings
)

@Composable
fun MainApp(navController: NavHostController, sharedViewModel: DashboardViewModel?) {
    Scaffold(
        bottomBar = {
            val navBackStackEntry by navController.currentBackStackEntryAsState()
            val currentDestination = navBackStackEntry?.destination
            NavigationBar(
                containerColor = MaterialTheme.colorScheme.surface,
                tonalElevation = 0.dp
            ) {
                bottomNavItems.forEach { screen ->
                    val selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true
                    NavigationBarItem(
                        icon = {
                            Icon(
                                imageVector = if (selected) screen.selectedIcon else screen.unselectedIcon,
                                contentDescription = screen.label
                            )
                        },
                        label = { Text(screen.label) },
                        selected = selected,
                        onClick = {
                            navController.navigate(screen.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Dashboard.route,
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            enterTransition = {
                fadeIn(animationSpec = tween(300)) + slideInHorizontally(
                    initialOffsetX = { 300 },
                    animationSpec = tween(300, easing = FastOutSlowInEasing)
                )
            },
            exitTransition = {
                fadeOut(animationSpec = tween(300)) + slideOutHorizontally(
                    targetOffsetX = { -300 },
                    animationSpec = tween(300, easing = FastOutSlowInEasing)
                )
            },
            popEnterTransition = {
                fadeIn(animationSpec = tween(300)) + slideInHorizontally(
                    initialOffsetX = { -300 },
                    animationSpec = tween(300, easing = FastOutSlowInEasing)
                )
            },
            popExitTransition = {
                fadeOut(animationSpec = tween(300)) + slideOutHorizontally(
                    targetOffsetX = { 300 },
                    animationSpec = tween(300, easing = FastOutSlowInEasing)
                )
            }
        ) {
            composable(Screen.Dashboard.route) { 
                DashboardScreen(
                    externalViewModel = sharedViewModel,
                    onFabClick = { navController.navigate(Screen.FoodLog.route) },
                    onNavigateToWeight = { navController.navigate("weight") },
                    onNavigateToSleep = { navController.navigate("sleep") }
                ) 
            }
            composable(Screen.FoodLog.route) { FoodLogScreen() }
            composable(Screen.Chat.route) { ChatScreen() }
            composable(Screen.Settings.route) { 
                SettingsScreen(
                    onNavigateToAIModels = { navController.navigate("family") }
                ) 
            }
            composable("weight") { WeightScreen() }
            composable("sleep") { SleepScreen() }
            composable("mealplanner") { MealPlannerScreen() }
            composable("family") { FamilyProfilesScreen() }
            composable("period") { PeriodTrackingScreen() }
        }
    }
}
