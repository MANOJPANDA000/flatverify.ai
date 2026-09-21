package com.example.my_first_app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.my_first_app.data.AuditRepository
import com.example.my_first_app.data.PropertyAudit
import com.example.my_first_app.data.RoomSpaceType
import com.example.my_first_app.data.SavedRoomRecord
import com.example.my_first_app.util.AreaDisplayUnit
import com.example.my_first_app.util.DimensionParser
import com.example.my_first_app.util.RoomUtil
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

data class CalculatorUiState(
    val rooms: List<SavedRoomRecord> = emptyList(),
    val displayUnit: AreaDisplayUnit = AreaDisplayUnit.IMPERIAL,
    val internalWallPercent: Double = 12.0,
    val externalWallPercent: Double = 0.0,
    val loadingPercent: Double = 30.0,
    val propertyType: String = "apartment"
)

class CalculatorViewModel(private val repository: AuditRepository) : ViewModel() {
    private val _uiState = MutableStateFlow(CalculatorUiState())
    val uiState: StateFlow<CalculatorUiState> = _uiState.asStateFlow()

    init {
        // Initialize with default rooms
        val initialRooms = listOf(
            SavedRoomRecord("Living Room", DimensionParser.feetInchesToMeters(16.0, 0.0), DimensionParser.feetInchesToMeters(12.0, 0.0), "feetInches"),
            SavedRoomRecord("Master Bedroom", DimensionParser.feetInchesToMeters(12.0, 0.0), DimensionParser.feetInchesToMeters(14.0, 0.0), "feetInches"),
            SavedRoomRecord("Kitchen", DimensionParser.feetInchesToMeters(8.0, 6.0), DimensionParser.feetInchesToMeters(10.0, 0.0), "feetInches")
        )
        _uiState.value = _uiState.value.copy(rooms = initialRooms)
    }

    fun addRoom(room: SavedRoomRecord) {
        _uiState.value = _uiState.value.copy(rooms = _uiState.value.rooms + room)
    }

    fun updateRoom(index: Int, room: SavedRoomRecord) {
        val newRooms = _uiState.value.rooms.toMutableList()
        newRooms[index] = room
        _uiState.value = _uiState.value.copy(rooms = newRooms)
    }

    fun removeRoom(index: Int) {
        _uiState.value = _uiState.value.copy(rooms = _uiState.value.rooms.filterIndexed { i, _ -> i != index })
    }

    fun setDisplayUnit(unit: AreaDisplayUnit) {
        _uiState.value = _uiState.value.copy(displayUnit = unit)
    }

    fun setInternalWallPercent(percent: Double) {
        _uiState.value = _uiState.value.copy(internalWallPercent = percent)
    }

    fun setLoadingPercent(percent: Double) {
        _uiState.value = _uiState.value.copy(loadingPercent = percent)
    }

    fun saveAudit(name: String) {
        val state = _uiState.value
        viewModelScope.launch {
            val usableArea = calculateUsableArea(state.rooms)
            val internalWallArea = usableArea * (state.internalWallPercent / 100)
            val carpetArea = usableArea + internalWallArea
            val externalWallArea = usableArea * (state.externalWallPercent / 100)
            
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

            val builtUpArea = carpetArea + externalWallArea + balconyArea + utilityOutsideArea
            val loadingArea = builtUpArea * (state.loadingPercent / 100)
            val superBuiltUpArea = builtUpArea + loadingArea

            val audit = PropertyAudit(
                id = UUID.randomUUID().toString(),
                type = "calculator",
                auditName = name,
                timestamp = System.currentTimeMillis().toString(),
                rooms = state.rooms,
                usableArea = usableArea,
                carpetArea = carpetArea,
                internalWallPercent = state.internalWallPercent,
                internalWallArea = internalWallArea,
                builtUpArea = builtUpArea,
                externalWallPercent = state.externalWallPercent,
                externalWallArea = externalWallArea,
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
