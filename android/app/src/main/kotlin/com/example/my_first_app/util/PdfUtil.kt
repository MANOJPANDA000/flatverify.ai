package com.example.my_first_app.util

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import android.os.Environment
import android.widget.Toast
import com.example.my_first_app.data.PropertyAudit
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

object PdfUtil {

    fun generateAuditReport(context: Context, audit: PropertyAudit) {
        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(595, 842, 1).create() // A4 size in points
        val page = pdfDocument.startPage(pageInfo)
        val canvas: Canvas = page.canvas
        val paint = Paint()

        var yPos = 50f

        // Title
        paint.textSize = 24f
        paint.isFakeBoldText = true
        paint.color = Color.BLACK
        canvas.drawText("Flatverify.ai Audit Report", 50f, yPos, paint)
        yPos += 40f

        // Audit Name
        paint.textSize = 18f
        paint.isFakeBoldText = true
        canvas.drawText(audit.auditName, 50f, yPos, paint)
        yPos += 30f

        // Date
        paint.textSize = 12f
        paint.isFakeBoldText = false
        paint.color = Color.GRAY
        canvas.drawText("Date: ${audit.timestamp}", 50f, yPos, paint)
        yPos += 40f

        // Summary Header
        paint.textSize = 16f
        paint.isFakeBoldText = true
        paint.color = Color.BLACK
        canvas.drawText("Area Summary", 50f, yPos, paint)
        yPos += 25f

        // Summary Details
        paint.textSize = 12f
        paint.isFakeBoldText = false
        val summaryItems = listOf(
            "RERA Carpet Area: ${DimensionParser.formatArea(audit.carpetArea)}",
            "Built-up Area: ${DimensionParser.formatArea(audit.builtUpArea)}",
            "Super Built-up Area: ${DimensionParser.formatArea(audit.superBuiltUpArea)}",
            "Loading: ${audit.loadingPercent.toInt()}%",
            "Internal Wall Assumption: ${audit.internalWallPercent.toInt()}%"
        )

        for (item in summaryItems) {
            canvas.drawText(item, 70f, yPos, paint)
            yPos += 20f
        }
        yPos += 20f

        // Rooms Header
        paint.textSize = 16f
        paint.isFakeBoldText = true
        canvas.drawText("Room Details", 50f, yPos, paint)
        yPos += 25f

        // Rooms Table Header
        paint.textSize = 12f
        paint.isFakeBoldText = true
        canvas.drawText("Room Name", 70f, yPos, paint)
        canvas.drawText("Dimensions", 250f, yPos, paint)
        canvas.drawText("Area", 450f, yPos, paint)
        yPos += 20f
        paint.isFakeBoldText = false

        // Rooms List
        for (room in audit.rooms) {
            if (yPos > 780) { // Simple page break check
                pdfDocument.finishPage(page)
                // In a real app, we would start a new page here. 
                // For this prototype, we'll stick to one page for brevity.
                break 
            }
            canvas.drawText(room.name, 70f, yPos, paint)
            canvas.drawText("${DimensionParser.format(room.lengthMeters)}m x ${DimensionParser.format(room.widthMeters)}m", 250f, yPos, paint)
            val roomArea = DimensionParser.squareMetersToSquareFeet(room.lengthMeters * room.widthMeters)
            canvas.drawText(DimensionParser.formatArea(roomArea), 450f, yPos, paint)
            yPos += 20f
        }

        pdfDocument.finishPage(page)

        val fileName = "Audit_${audit.auditName.replace(" ", "_")}.pdf"
        val file = File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), fileName)

        try {
            pdfDocument.writeTo(FileOutputStream(file))
            Toast.makeText(context, "PDF saved to Documents", Toast.LENGTH_LONG).show()
        } catch (e: IOException) {
            e.printStackTrace()
            Toast.makeText(context, "Error saving PDF: ${e.message}", Toast.LENGTH_SHORT).show()
        }

        pdfDocument.close()
    }
}
