package com.example.my_first_app.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.serialization.Serializable

@Serializable
enum class RoomSpaceType {
    INTERNAL,
    BALCONY,
    UTILITY_INSIDE,
    UTILITY_OUTSIDE
}

@Serializable
data class SavedRoomRecord(
    val name: String,
    val lengthMeters: Double,
    val widthMeters: Double,
    val unit: String,
    val source: String? = null,
    val isUserVerified: Boolean = false,
    val spaceType: RoomSpaceType = RoomSpaceType.INTERNAL
)

@Serializable
@Entity(tableName = "audits")
data class PropertyAudit(
    @PrimaryKey val id: String,
    val type: String, // "scan" or "calculator"
    val auditName: String,
    val builder: String? = null,
    val project: String? = null,
    val tower: String? = null,
    val flat: String? = null,
    val floor: String? = null,
    val configuration: String? = null,
    val notes: String? = null,
    val timestamp: String,
    val rooms: List<SavedRoomRecord>,
    val usableArea: Double,
    val carpetArea: Double,
    val internalWallPercent: Double,
    val internalWallArea: Double,
    val builtUpArea: Double,
    val externalWallPercent: Double,
    val externalWallArea: Double,
    val loadingPercent: Double,
    val loadingArea: Double,
    val superBuiltUpArea: Double,
    val balconyArea: Double? = null,
    val utilityInsideArea: Double? = null,
    val utilityOutsideArea: Double? = null
)
