package com.example.my_first_app.util

import java.util.Locale
import kotlin.math.floor
import kotlin.math.hypot
import kotlin.math.round

enum class AreaDisplayUnit {
    IMPERIAL,
    METRIC,
    HYBRID
}

enum class DimensionUnit {
    FEET_INCHES,
    METER_CM,
    DECIMAL_FEET
}

object DimensionParser {
    const val METERS_TO_FEET = 3.280839895013123
    const val METERS_TO_INCHES = 39.37007874015748
    const val SQ_METERS_TO_SQ_FEET = 10.763910416709722

    fun feetInchesToMeters(feet: Double, inches: Double): Double {
        val totalInches = feet * 12 + inches
        return totalInches * 0.0254
    }

    fun meterCmToMeters(meters: Double, cm: Double): Double {
        return meters + cm / 100.0
    }

    fun squareMetersToSquareFeet(squareMeters: Double): Double {
        return squareMeters * SQ_METERS_TO_SQ_FEET
    }

    fun squareFeetToSquareMeters(squareFeet: Double): Double {
        return squareFeet / SQ_METERS_TO_SQ_FEET
    }

    fun format(value: Double, decimals: Int = 2): String {
        return String.format(Locale.US, "%.${decimals}f", value)
            .replace(Regex("\\.0+$"), "")
            .replace(Regex("(\\.[0-9]*[1-9])0+$"), "$1")
    }

    fun formatFeetInches(meters: Double): String {
        if (meters <= 0) return "0' 0\""
        val totalInches = round(meters * METERS_TO_INCHES).toInt()
        val feet = totalInches / 12
        val inches = totalInches % 12
        return "$feet' $inches\""
    }

    fun formatMeterCm(meters: Double): String {
        if (meters <= 0) return "0.00 m"
        return String.format(Locale.US, "%.2f m", meters)
    }

    fun formatArea(squareFeet: Double, unit: AreaDisplayUnit = AreaDisplayUnit.IMPERIAL): String {
        if (squareFeet <= 0 || squareFeet.isNaN()) return "0 sq ft"
        val sqMeters = squareFeetToSquareMeters(squareFeet)
        return when (unit) {
            AreaDisplayUnit.IMPERIAL -> "${format(squareFeet, 2)} sq ft"
            AreaDisplayUnit.METRIC -> "${format(sqMeters, 2)} sq m"
            AreaDisplayUnit.HYBRID -> "${format(squareFeet, 2)} sq ft (${format(sqMeters, 2)} sq m)"
        }
    }

    fun parseDimensionToMeters(input: String): Double {
        if (input.isBlank()) return 0.0
        val clean = input.trim()
            .replace(Regex("[’‘`]"), "'")
            .replace(Regex("[“”]"), "\"")
            .lowercase()

        // Feet and inches: 10' 6", 10'6", 10-6, 10 ft 6 in
        val feetInchesRegex = Regex("^(\\d+(?:\\.\\d+)?)\\s*(?:'|ft|feet)?\\s*[-–—]?\\s*(\\d+(?:\\.\\d+)?)\\s*(?:\"|in|inch|inches)?$")
        val feetInchesMatch = feetInchesRegex.find(clean)
        if (feetInchesMatch != null && (clean.contains("'") || clean.contains("ft") || clean.contains("-") || clean.contains("–") || clean.contains("\"") || clean.contains("in") || clean.contains(" "))) {
            val feet = feetInchesMatch.groupValues[1].toDoubleOrNull() ?: 0.0
            val inches = feetInchesMatch.groupValues[2].toDoubleOrNull() ?: 0.0
            return feetInchesToMeters(feet, inches)
        }

        // Feet only: 10' or 10 ft
        val feetOnlyRegex = Regex("^(\\d+(?:\\.\\d+)?)\\s*(?:'|ft|feet)$")
        val feetOnlyMatch = feetOnlyRegex.find(clean)
        if (feetOnlyMatch != null) {
            val feet = feetOnlyMatch.groupValues[1].toDoubleOrNull() ?: 0.0
            return feet * 0.3048
        }

        // Inches only: 120" or 120 in
        val inchesOnlyRegex = Regex("^(\\d+(?:\\.\\d+)?)\\s*(?:\"|in|inch|inches)$")
        val inchesOnlyMatch = inchesOnlyRegex.find(clean)
        if (inchesOnlyMatch != null) {
            val inches = inchesOnlyMatch.groupValues[1].toDoubleOrNull() ?: 0.0
            return inches * 0.0254
        }

        // Millimeters: 3500 mm
        val mmRegex = Regex("^(\\d+(?:\\.\\d+)?)\\s*mm$")
        val mmMatch = mmRegex.find(clean)
        if (mmMatch != null) {
            return (mmMatch.groupValues[1].toDoubleOrNull() ?: 0.0) / 1000.0
        }

        // Centimeters: 350 cm
        val cmRegex = Regex("^(\\d+(?:\\.\\d+)?)\\s*cm$")
        val cmMatch = cmRegex.find(clean)
        if (cmMatch != null) {
            return (cmMatch.groupValues[1].toDoubleOrNull() ?: 0.0) / 100.0
        }

        // Meters: 3.5 m
        val mRegex = Regex("^(\\d+(?:\\.\\d+)?)\\s*(?:m|meter|meters|metre|metres)$")
        val mMatch = mRegex.find(clean)
        if (mMatch != null) {
            return mMatch.groupValues[1].toDoubleOrNull() ?: 0.0
        }

        // Decimal number without unit
        val num = clean.toDoubleOrNull()
        if (num != null && num > 0) {
            return when {
                num >= 500 -> num / 1000.0
                num >= 50 -> num / 100.0
                clean.contains(".") && num <= 15 -> num
                else -> num * 0.3048
            }
        }
        return 0.0
    }
}
