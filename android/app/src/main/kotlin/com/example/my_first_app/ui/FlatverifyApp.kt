package com.example.my_first_app.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.my_first_app.ui.screens.HomeScreen
import com.example.my_first_app.ui.screens.CalculatorScreen
import com.example.my_first_app.ui.screens.ScannerScreen
import com.example.my_first_app.ui.screens.AuditHistoryScreen
import com.example.my_first_app.ui.screens.SettingsScreen

sealed class Screen(val route: String, val label: String, val icon: @Composable () -> Unit) {
    object Home : Screen("home", "Home", { Icon(Icons.Default.Home, contentDescription = null) })
    object Calculator : Screen("calculator", "Calculator", { Icon(Icons.Default.Calculate, contentDescription = null) })
    object Scanner : Screen("scanner", "Scanner", { Icon(Icons.Default.QrCodeScanner, contentDescription = null) })
    object History : Screen("history", "Audits", { Icon(Icons.Default.History, contentDescription = null) })
    object Settings : Screen("settings", "Settings", { Icon(Icons.Default.Settings, contentDescription = null) })
}

@Composable
fun FlatverifyApp() {
    val navController = rememberNavController()
    val items = listOf(
        Screen.Home,
        Screen.Calculator,
        Screen.Scanner,
        Screen.History,
        Screen.Settings
    )

    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination
                items.forEach { screen ->
                    NavigationBarItem(
                        icon = screen.icon,
                        label = { Text(screen.label) },
                        selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
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
            startDestination = Screen.Home.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Home.route) { HomeScreen(navController) }
            composable(Screen.Calculator.route) { CalculatorScreen() }
            composable(Screen.Scanner.route) { ScannerScreen() }
            composable(Screen.History.route) { AuditHistoryScreen(navController) }
            composable(Screen.Settings.route) { SettingsScreen() }
        }
    }
}
