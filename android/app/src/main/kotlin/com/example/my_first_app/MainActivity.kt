package com.example.my_first_app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.example.my_first_app.ui.FlatverifyApp
import com.example.my_first_app.ui.theme.FlatverifyTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            FlatverifyTheme {
                FlatverifyApp()
            }
        }
    }
}
