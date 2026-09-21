package com.example.my_first_app.util

import com.example.my_first_app.data.RoomSpaceType

object RoomUtil {
    val ROOM_KEYWORDS = listOf(
        "living room", "living/dining", "living", "dining room", "dining", "drawing room", "drawing",
        "master bed room", "master bedroom", "master bed", "bed room", "bedroom", "bed", "kitchen",
        "utility", "dry yard", "balcony", "terrace", "toilet", "attached toilet", "bath",
        "attached bath", "bathroom", "powder room", "foyer", "entry", "study room", "study",
        "pooja", "puja", "mandir", "store", "dress", "wardrobe", "passage", "corridor"
    )

    fun inferRoomSpaceType(roomName: String): RoomSpaceType {
        val name = roomName.lowercase().trim()
        if (listOf("balcony", "balc", "verandah", "veranda", "sitout", "deck", "terrace").any { name.contains(it) }) {
            if (name.contains("dry balcony") || name.contains("utility")) {
                return RoomSpaceType.UTILITY_OUTSIDE
            }
            return RoomSpaceType.BALCONY
        }
        if (listOf("dry balcony", "dry yard", "service yard").any { name.contains(it) }) {
            return RoomSpaceType.UTILITY_OUTSIDE
        }
        if (name.contains("utility") || name.contains("wash")) {
            return RoomSpaceType.UTILITY_INSIDE
        }
        return RoomSpaceType.INTERNAL
    }

    fun normalizeText(text: String): String {
        return text
            .replace(Regex("[\u2018\u2019\u201A\u201B`]"), "'")
            .replace(Regex("[\u201C\u201D\u201E\u201F]"), "\"")
            .replace(Regex("[xX×*]"), " x ")
            .replace(Regex("\\s+"), " ")
            .trim()
    }
}

data class ParsedRoomMeasurement(
    val name: String,
    val length: String,
    val width: String
)

object DimensionScanParser {
    fun parseRooms(rawText: String): List<ParsedRoomMeasurement> {
        val results = mutableListOf<ParsedRoomMeasurement>()
        val lines = rawText.lines().map { it.trim() }.filter { it.isNotBlank() }

        for (i in lines.indices) {
            val line = lines[i]
            val normLine = RoomUtil.normalizeText(line)

            val feetRegex = Regex("(\\d{1,2}\\s*['′\\-]\\s*\\d{0,2}\\s*[\"″]?)\\s*[xX×*]\\s*(\\d{1,2}\\s*['′\\-]\\s*\\d{0,2}\\s*[\"″]?)", RegexOption.IGNORE_CASE)
            val metricRegex = Regex("(\\d+(?:\\.\\d+)?\\s*(?:mm|cm|m)?)\\s*[xX×*]\\s*(\\d+(?:\\.\\d+)?\\s*(?:mm|cm|m)?)", RegexOption.IGNORE_CASE)

            val feetMatches = feetRegex.findAll(normLine)
            val metricMatches = metricRegex.findAll(normLine)

            if (feetMatches.any()) {
                feetMatches.forEach { match ->
                    val lenStr = match.groupValues[1].trim()
                    val widStr = match.groupValues[2].trim()
                    val roomName = findNearestRoomName(lines, i) ?: "Room ${results.size + 1}"
                    results.add(ParsedRoomMeasurement(roomName, lenStr, widStr))
                }
            } else if (metricMatches.any()) {
                metricMatches.forEach { match ->
                    val lenStr = match.groupValues[1].trim()
                    val widStr = match.groupValues[2].trim()
                    val n1 = lenStr.toDoubleOrNull() ?: 0.0
                    if ((n1 >= 1.0 && n1 <= 100) || n1 >= 1000) {
                        val roomName = findNearestRoomName(lines, i) ?: "Room ${results.size + 1}"
                        results.add(ParsedRoomMeasurement(roomName, lenStr, widStr))
                    }
                }
            }
        }

        if (results.isEmpty()) {
            val normText = RoomUtil.normalizeText(rawText)
            val allMatches = Regex("(\\d{1,2}\\s*['′\\-]\\s*\\d{0,2}\\s*[\"″]?)\\s*x\\s*(\\d{1,2}\\s*['′\\-]\\s*\\d{0,2}\\s*[\"″]?)", RegexOption.IGNORE_CASE).findAll(normText)
            allMatches.forEach { match ->
                results.add(ParsedRoomMeasurement("Room ${results.size + 1}", match.groupValues[1].trim(), match.groupValues[2].trim()))
            }
        }

        return results
    }

    private fun findNearestRoomName(lines: List<String>, targetIdx: Int): String? {
        for (offset in listOf(0, -1, -2, 1)) {
            val idx = targetIdx + offset
            if (idx in lines.indices) {
                val text = lines[idx].lowercase()
                for (kw in RoomUtil.ROOM_KEYWORDS) {
                    if (text.contains(kw)) {
                        return kw.split(" ").joinToString(" ") { it.replaceFirstChar { char -> char.uppercase() } }
                    }
                }
            }
        }
        return null
    }
}
