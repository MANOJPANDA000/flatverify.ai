package com.example.my_first_app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.my_first_app.data.AppDatabase
import com.example.my_first_app.data.AuditRepository
import com.example.my_first_app.ui.viewmodels.HistoryViewModel
import com.example.my_first_app.ui.viewmodels.ViewModelFactory
import com.example.my_first_app.util.DimensionParser
import com.example.my_first_app.util.PdfUtil

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AuditHistoryScreen(navController: NavController) {
    val context = LocalContext.current
    val database = AppDatabase.getDatabase(context)
    val repository = AuditRepository(database.auditDao())
    val viewModel: HistoryViewModel = viewModel(factory = ViewModelFactory(repository))
    val audits by viewModel.allAudits.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Audit History", fontWeight = FontWeight.Black) })
        }
    ) { innerPadding ->
        if (audits.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        Icons.Default.History,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.secondary.copy(alpha = 0.5f)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("No saved audits found", color = MaterialTheme.colorScheme.secondary)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .background(MaterialTheme.colorScheme.background)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(audits) { audit ->
                    AuditHistoryCard(
                        audit = audit,
                        onDelete = { viewModel.deleteAudit(audit.id) },
                        onDownload = { PdfUtil.generateAuditReport(context, audit) }
                    )
                }
            }
        }
    }
}

@Composable
fun AuditHistoryCard(
    audit: com.example.my_first_app.data.PropertyAudit,
    onDelete: () -> Unit,
    onDownload: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = audit.auditName,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${DimensionParser.formatArea(audit.carpetArea)} Carpet",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = if (audit.type == "scan") "Scanned Blueprint" else "Manual Calculation",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.secondary
                )
            }
            Row {
                IconButton(onClick = onDownload) {
                    Icon(Icons.Default.Download, contentDescription = "Download PDF", tint = MaterialTheme.colorScheme.primary)
                }
                IconButton(onClick = onDelete) {
                    Icon(Icons.Default.Delete, contentDescription = "Delete", tint = MaterialTheme.colorScheme.error)
                }
            }
        }
    }
}
