package com.example.my_first_app.ui.viewmodels

import android.graphics.Bitmap
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.my_first_app.data.AuditRepository
import com.example.my_first_app.data.PropertyAudit
import com.example.my_first_app.data.RoomSpaceType
import com.example.my_first_app.data.SavedRoomRecord
import com.example.my_first_app.util.AreaDisplayUnit
import com.example.my_first_app.util.DimensionParser
import com.example.my_first_app.util.DimensionScanParser
import com.example.my_first_app.util.RoomUtil
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.util.UUID

data class ScannerUiState(
    val rooms: List<SavedRoomRecord> = emptyList(),
    val isProcessing: Boolean = false,
    val ocrText: String = "",
    val displayUnit: AreaDisplayUnit = AreaDisplayUnit.IMPERIAL,
    val internalWallPercent: Double = 12.0,
    val loadingPercent: Double = 30.0
)

class ScannerViewModel(private val repository: AuditRepository) : ViewModel() {
    private val _uiState = MutableStateFlow(ScannerUiState())
    val uiState: StateFlow<ScannerUiState> = _uiState.asStateFlow()

    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    fun processImage(bitmap: Bitmap) {
        _uiState.value = _uiState.value.copy(isProcessing = true)
        val image = InputImage.fromBitmap(bitmap, 0)
        
        viewModelScope.launch {
            try {
                val result = recognizer.process(image).await()
                val text = result.text
                val parsed = DimensionScanParser.parseRooms(text)
                
                val newRooms = parsed.map { p ->
                    SavedRoomRecord(
                        name = p.name,
                        lengthMeters = DimensionParser.parseDimensionToMeters(p.length),
                        widthMeters = DimensionParser.parseDimensionToMeters(p.width),
                        unit = "feetInches",
                        source = "ocr_scan",
                        isUserVerified = false,
                        spaceType = RoomUtil.inferRoomSpaceType(p.name)
                    )
                }
                
                _uiState.value = _uiState.value.copy(
                    rooms = newRooms,
                    ocrText = text,
                    isProcessing = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isProcessing = false)
            }
        }
    }

    fun updateRoom(index: Int, room: SavedRoomRecord) {
        val newRooms = _uiState.value.rooms.toMutableList()
        newRooms[index] = room
        _uiState.value = _uiState.value.copy(rooms = newRooms)
    }

    fun removeRoom(index: Int) {
        _uiState.value = _uiState.value.copy(rooms = _uiState.value.rooms.filterIndexed { i, _ -> i != index })
    }

    fun saveAudit(name: String) {
        // Similar logic to CalculatorViewModel, could be shared in a parent class or helper
        val state = _uiState.value
        viewModelScope.launch {
            val usableArea = calculateUsableArea(state.rooms)
            val internalWallArea = usableArea * (state.internalWallPercent / 100)
            val carpetArea = usableArea + internalWallArea
            
            var balconyArea = 0.0
            var utilityInsideArea = 0.0
            var utilityOutsideArea = 0.0
            state.rooms.forEach { r ->
                val areaSqFt = DimensionParser.squareMetersToSquareFeet(r.lengthMeters * r.widthMeters)
                when (r.spaceType) {
                    RoomSpaceType.BALCONY -> balconyArea += areaSqFt
                    RoomSpaceType.UTILITY_INSIDE -> utilityInsideArea += areaSqFt
                    RoomSpaceType.UTILITY_OUTSIDE -> utilityOutsideArea += areaSqFt
                    else -> {}
                }
            }

            val builtUpArea = carpetArea + (usableArea * 0.0) + balconyArea + utilityOutsideArea
            val loadingArea = builtUpArea * (state.loadingPercent / 100)
            val superBuiltUpArea = builtUpArea + loadingArea

            val audit = PropertyAudit(
                id = UUID.randomUUID().toString(),
                type = "scan",
                auditName = name,
                timestamp = System.currentTimeMillis().toString(),
                rooms = state.rooms,
                usableArea = usableArea,
                carpetArea = carpetArea,
                internalWallPercent = state.internalWallPercent,
                internalWallArea = internalWallArea,
                builtUpArea = builtUpArea,
                externalWallPercent = 0.0,
                externalWallArea = 0.0,
                loadingPercent = state.loadingPercent,
                loadingArea = loadingArea,
                superBuiltUpArea = superBuiltUpArea,
                balconyArea = balconyArea,
                utilityInsideArea = utilityInsideArea,
                utilityOutsideArea = utilityOutsideArea
            )
            repository.insertAudit(audit)
        }
    }

    private fun calculateUsableArea(rooms: List<SavedRoomRecord>): Double {
        var total = 0.0
        rooms.forEach { r ->
            val spaceType = r.spaceType
            if (spaceType != RoomSpaceType.BALCONY && spaceType != RoomSpaceType.UTILITY_OUTSIDE) {
                total += DimensionParser.squareMetersToSquareFeet(r.lengthMeters * r.widthMeters)
            }
        }
        return total
    }
}
