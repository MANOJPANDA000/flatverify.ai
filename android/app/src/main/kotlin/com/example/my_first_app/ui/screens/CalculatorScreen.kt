package com.example.my_first_app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.SquareFoot
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.my_first_app.data.AppDatabase
import com.example.my_first_app.data.AuditRepository
import com.example.my_first_app.data.RoomSpaceType
import com.example.my_first_app.data.SavedRoomRecord
import com.example.my_first_app.ui.components.ResultCard
import com.example.my_first_app.ui.components.RoomCard
import com.example.my_first_app.ui.viewmodels.CalculatorViewModel
import com.example.my_first_app.ui.viewmodels.ViewModelFactory
import com.example.my_first_app.util.AreaDisplayUnit
import com.example.my_first_app.util.DimensionParser
import com.example.my_first_app.util.RoomUtil

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalculatorScreen() {
    val context = LocalContext.current
    val database = AppDatabase.getDatabase(context)
    val repository = AuditRepository(database.auditDao())
    val viewModel: CalculatorViewModel = viewModel(factory = ViewModelFactory(repository))
    val state by viewModel.uiState.collectAsState()

    var showSaveDialog by remember { mutableStateOf(false) }
    var auditName by remember { mutableStateOf("Manual Property Carpet Audit") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Carpet Area Calculator", fontWeight = FontWeight.Black) },
                actions = {
                    IconButton(onClick = { showSaveDialog = true }) {
                        Icon(Icons.Default.Save, contentDescription = "Save")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = {
                viewModel.addRoom(
                    SavedRoomRecord(
                        name = "New Room ${state.rooms.size + 1}",
                        lengthMeters = DimensionParser.feetInchesToMeters(10.0, 0.0),
                        widthMeters = DimensionParser.feetInchesToMeters(10.0, 0.0),
                        unit = "feetInches"
                    )
                )
            }) {
                Icon(Icons.Default.Add, contentDescription = "Add Room")
            }
        }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(MaterialTheme.colorScheme.background)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                CalculationSummary(state)
            }

            item {
                AssumptionsSection(state, viewModel)
            }

            item {
                Text(
                    text = "Rooms & Spaces",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }

            itemsIndexed(state.rooms) { index, room ->
                RoomCard(
                    room = room,
                    onRemove = { viewModel.removeRoom(index) },
                    onUpdate = { updated -> viewModel.updateRoom(index, updated) },
                    displayUnit = state.displayUnit
                )
            }
            
            item { Spacer(modifier = Modifier.height(80.dp)) }
        }
    }

    if (showSaveDialog) {
        AlertDialog(
            onDismissRequest = { showSaveDialog = false },
            title = { Text("Save Audit") },
            text = {
                OutlinedTextField(
                    value = auditName,
                    onValueChange = { auditName = it },
                    label = { Text("Audit Name") },
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.saveAudit(auditName)
                    showSaveDialog = false
                }) {
                    Text("Save")
                }
            },
            dismissButton = {
                TextButton(onClick = { showSaveDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun CalculationSummary(state: com.example.my_first_app.ui.viewmodels.CalculatorUiState) {
    // Area Calculations
    var internalLivingSqFt = 0.0
    var utilityInsideSqFt = 0.0
    var utilityOutsideSqFt = 0.0
    var balconySqFt = 0.0

    state.rooms.forEach { r ->
        val areaSqM = r.lengthMeters * r.widthMeters
        val sqFt = DimensionParser.squareMetersToSquareFeet(areaSqM)
        val spaceType = r.spaceType
        when (spaceType) {
            RoomSpaceType.UTILITY_INSIDE -> utilityInsideSqFt += sqFt
            RoomSpaceType.UTILITY_OUTSIDE -> utilityOutsideSqFt += sqFt
            RoomSpaceType.BALCONY -> balconySqFt += sqFt
            else -> internalLivingSqFt += sqFt
        }
    }

    val internalUsableSqFt = internalLivingSqFt + utilityInsideSqFt
    val internalWallAreaSqFt = internalUsableSqFt * (state.internalWallPercent / 100)
    val reraCarpetAreaSqFt = internalUsableSqFt + internalWallAreaSqFt
    
    val totalExclusiveOutdoorSqFt = balconySqFt + utilityOutsideSqFt
    val externalWallAreaSqFt = internalUsableSqFt * (state.externalWallPercent / 100)
    val builtUpAreaSqFt = reraCarpetAreaSqFt + externalWallAreaSqFt + totalExclusiveOutdoorSqFt
    val loadingAreaSqFt = builtUpAreaSqFt * (state.loadingPercent / 100)
    val superBuiltUpAreaSqFt = builtUpAreaSqFt + loadingAreaSqFt

    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        ResultCard(
            title = "RERA Carpet Area",
            value = reraCarpetAreaSqFt,
            displayUnit = state.displayUnit,
            icon = Icons.Default.Home,
            highlighted = true
        )
        ResultCard(
            title = "Built-up Area",
            value = builtUpAreaSqFt,
            displayUnit = state.displayUnit,
            icon = Icons.Default.Business
        )
        ResultCard(
            title = "Super Built-up Area",
            value = superBuiltUpAreaSqFt,
            displayUnit = state.displayUnit,
            icon = Icons.Default.AutoAwesome
        )
    }
}

@Composable
fun AssumptionsSection(
    state: com.example.my_first_app.ui.viewmodels.CalculatorUiState,
    viewModel: CalculatorViewModel
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Assumptions",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = "Internal Wall: ${state.internalWallPercent.toInt()}%",
                style = MaterialTheme.typography.bodySmall
            )
            Slider(
                value = state.internalWallPercent.toFloat(),
                onValueChange = { viewModel.setInternalWallPercent(it.toDouble()) },
                valueRange = 5f..20f
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Loading: ${state.loadingPercent.toInt()}%",
                style = MaterialTheme.typography.bodySmall
            )
            Slider(
                value = state.loadingPercent.toFloat(),
                onValueChange = { viewModel.setLoadingPercent(it.toDouble()) },
                valueRange = 15f..50f
            )
        }
    }
}
