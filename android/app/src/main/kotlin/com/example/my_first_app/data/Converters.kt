package com.example.my_first_app.data

import androidx.room.TypeConverter
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class Converters {
    private val json = Json { ignoreUnknownKeys = true }

    @TypeConverter
    fun fromRoomList(value: List<SavedRoomRecord>): String {
        return json.encodeToString(value)
    }

    @TypeConverter
    fun toRoomList(value: String): List<SavedRoomRecord> {
        return json.decodeFromString(value)
    }
}
