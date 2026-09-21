package com.example.my_first_app.ui.screens

import android.graphics.Bitmap
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.my_first_app.data.AppDatabase
import com.example.my_first_app.data.AuditRepository
import com.example.my_first_app.ui.components.RoomCard
import com.example.my_first_app.ui.viewmodels.ScannerViewModel
import com.example.my_first_app.ui.viewmodels.ViewModelFactory

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScannerScreen() {
    val context = LocalContext.current
    val database = AppDatabase.getDatabase(context)
    val repository = AuditRepository(database.auditDao())
    val viewModel: ScannerViewModel = viewModel(factory = ViewModelFactory(repository))
    val state by viewModel.uiState.collectAsState()

    var imageUri by remember { mutableStateOf<Uri?>(null) }
    var showSaveDialog by remember { mutableStateOf(false) }
    var auditName by remember { mutableStateOf("Blueprint Scan Carpet Audit") }

    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        imageUri = uri
        uri?.let {
            val bitmap = if (Build.VERSION.SDK_INT < 28) {
                MediaStore.Images.Media.getBitmap(context.contentResolver, it)
            } else {
                val source = ImageDecoder.createSource(context.contentResolver, it)
                ImageDecoder.decodeBitmap(source)
            }
            viewModel.processImage(bitmap.copy(Bitmap.Config.ARGB_8888, true))
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Blueprint Scanner", fontWeight = FontWeight.Black) },
                actions = {
                    IconButton(onClick = { showSaveDialog = true }) {
                        Icon(Icons.Default.Save, contentDescription = "Save")
                    }
                }
            )
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
                UploadSection(onUpload = { launcher.launch("image/*") }, isProcessing = state.isProcessing)
            }

            if (state.rooms.isNotEmpty()) {
                item {
                    Text(
                        text = "Extracted Rooms",
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
            } else if (!state.isProcessing && imageUri != null) {
                item {
                    Text(
                        text = "No dimensions found. Try another image or add rooms manually.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(vertical = 16.dp)
                    )
                }
            }
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
fun UploadSection(onUpload: () -> Unit, isProcessing: Boolean) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.elevatedCardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(
            modifier = Modifier
                .padding(24.dp)
                .fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            if (isProcessing) {
                CircularProgressIndicator(modifier = Modifier.size(48.dp))
                Spacer(modifier = Modifier.height(16.dp))
                Text("Analyzing Floor Plan...", fontWeight = FontWeight.Bold)
            } else {
                Icon(
                    Icons.Default.CloudUpload,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = onUpload) {
                    Text("Upload Floor Plan")
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    "Support for JPEG, PNG architectural blueprints",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.secondary
                )
            }
        }
    }
}
