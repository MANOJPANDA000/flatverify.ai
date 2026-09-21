package com.example.my_first_app.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.my_first_app.data.SavedRoomRecord
import com.example.my_first_app.util.AreaDisplayUnit
import com.example.my_first_app.util.DimensionParser

@Composable
fun RoomCard(
    room: SavedRoomRecord,
    onRemove: () -> Unit,
    onUpdate: (SavedRoomRecord) -> Unit,
    displayUnit: AreaDisplayUnit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = room.name,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Bold
                )
                IconButton(onClick = onRemove) {
                    Icon(Icons.Default.Delete, contentDescription = "Remove", tint = MaterialTheme.colorScheme.error)
                }
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = DimensionParser.format(room.lengthMeters, 2),
                    onValueChange = { /* TODO: Implement actual numeric entry */ },
                    label = { Text("Length (m)") },
                    modifier = Modifier.weight(1f),
                    readOnly = true // Simplification for now
                )
                OutlinedTextField(
                    value = DimensionParser.format(room.widthMeters, 2),
                    onValueChange = { /* TODO: Implement actual numeric entry */ },
                    label = { Text("Width (m)") },
                    modifier = Modifier.weight(1f),
                    readOnly = true
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            val areaSqFt = DimensionParser.squareMetersToSquareFeet(room.lengthMeters * room.widthMeters)
            Text(
                text = "Area: ${DimensionParser.formatArea(areaSqFt, displayUnit)}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun ResultCard(
    title: String,
    value: Double,
    displayUnit: AreaDisplayUnit,
    icon: ImageVector,
    highlighted: Boolean = false
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (highlighted) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = null, tint = if (highlighted) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.secondary)
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.secondary
                )
                Text(
                    text = DimensionParser.formatArea(value, displayUnit),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Black,
                    color = if (highlighted) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}
