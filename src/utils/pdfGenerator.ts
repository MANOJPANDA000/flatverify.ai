import { jsPDF } from 'jspdf';
import { AreaDisplayUnit, PropertyAudit } from '../types';
import { DimensionParser } from './dimensionParser';

export class PdfReportGenerator {
  static generateAuditPdf(audit: PropertyAudit, displayUnit: AreaDisplayUnit = 'imperial'): jsPDF {
    const doc = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: 'a4',
    });

    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    let currentY = 14;

    // Helper: Add Watermark
    const addWatermark = () => {
      doc.saveGraphicsState();
      doc.setTextColor(230, 235, 245);
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(42);
      doc.text('Flatverify.ai', pageWidth / 2, pageHeight / 2 - 10, {
        align: 'center',
        angle: 45,
      });
      doc.setFontSize(14);
      doc.text('Understand Your Property', pageWidth / 2, pageHeight / 2 + 8, {
        align: 'center',
        angle: 45,
      });
      doc.restoreGraphicsState();
    };

    addWatermark();

    // 1. Header Banner
    doc.setFillColor(23, 43, 101); // #172B65
    doc.roundedRect(12, currentY, pageWidth - 24, 32, 3, 3, 'F');

    doc.setTextColor(255, 255, 255);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(18);
    doc.text('Flatverify.ai', 18, currentY + 10);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(200, 215, 255);
    doc.text('Understand your property • RERA Carpet Area Verification', 18, currentY + 16);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(13);
    doc.setTextColor(255, 255, 255);
    doc.text(audit.auditName || 'Property Area Audit Report', 18, currentY + 26);

    const auditTypeLabel = audit.type === 'scan' ? 'FLOOR PLAN SCAN' : 'MANUAL AUDIT';
    doc.setFontSize(8);
    doc.setTextColor(180, 210, 255);
    doc.text(auditTypeLabel, pageWidth - 20, currentY + 10, { align: 'right' });

    const formattedDate = new Date(audit.timestamp).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
    doc.text(`Generated: ${formattedDate}`, pageWidth - 20, currentY + 26, { align: 'right' });

    currentY += 38;

    // 2. Property Information (if provided)
    const hasPropertyInfo = [
      audit.builder,
      audit.project,
      audit.tower,
      audit.flat,
      audit.floor,
      audit.configuration,
    ].some(val => val && val.trim().length > 0);

    if (hasPropertyInfo) {
      doc.setFillColor(248, 250, 253);
      doc.setDrawColor(220, 226, 238);
      doc.roundedRect(12, currentY, pageWidth - 24, 28, 2, 2, 'FD');

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(10);
      doc.setTextColor(23, 43, 101);
      doc.text('Property Details', 16, currentY + 7);

      doc.setFontSize(8.5);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(100, 116, 139);

      const col1 = 16;
      const col2 = 75;
      const col3 = 135;

      // Row 1
      doc.text(`Builder: `, col1, currentY + 15);
      doc.setTextColor(30, 41, 59);
      doc.setFont('helvetica', 'bold');
      doc.text(audit.builder || 'N/A', col1 + 14, currentY + 15);

      doc.setTextColor(100, 116, 139);
      doc.setFont('helvetica', 'normal');
      doc.text(`Project: `, col2, currentY + 15);
      doc.setTextColor(30, 41, 59);
      doc.setFont('helvetica', 'bold');
      doc.text(audit.project || 'N/A', col2 + 13, currentY + 15);

      doc.setTextColor(100, 116, 139);
      doc.setFont('helvetica', 'normal');
      doc.text(`Config: `, col3, currentY + 15);
      doc.setTextColor(30, 41, 59);
      doc.setFont('helvetica', 'bold');
      doc.text(audit.configuration || 'N/A', col3 + 12, currentY + 15);

      // Row 2
      doc.setTextColor(100, 116, 139);
      doc.setFont('helvetica', 'normal');
      doc.text(`Tower: `, col1, currentY + 23);
      doc.setTextColor(30, 41, 59);
      doc.setFont('helvetica', 'bold');
      doc.text(audit.tower || 'N/A', col1 + 12, currentY + 23);

      doc.setTextColor(100, 116, 139);
      doc.setFont('helvetica', 'normal');
      doc.text(`Flat / Unit: `, col2, currentY + 23);
      doc.setTextColor(30, 41, 59);
      doc.setFont('helvetica', 'bold');
      doc.text(audit.flat || 'N/A', col2 + 18, currentY + 23);

      doc.setTextColor(100, 116, 139);
      doc.setFont('helvetica', 'normal');
      doc.text(`Floor: `, col3, currentY + 23);
      doc.setTextColor(30, 41, 59);
      doc.setFont('helvetica', 'bold');
      doc.text(audit.floor || 'N/A', col3 + 11, currentY + 23);

      currentY += 34;
    }

    // 3. Area Summary Table
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(11);
    doc.setTextColor(23, 43, 101);
    doc.text('Area Summary', 12, currentY);
    currentY += 4;

    const summaryRows: Array<{ label: string; sub: string; val: number; highlight?: boolean }> = [
      {
        label: 'RERA Carpet Area',
        sub: (audit.utilityInsideArea && audit.utilityInsideArea > 0)
          ? `Net usable floor + partitions (Includes enclosed utility: ${DimensionParser.formatArea(audit.utilityInsideArea, displayUnit)})`
          : 'Net usable internal floor space + internal partition walls (Sec 2(k))',
        val: audit.carpetArea || audit.usableArea,
        highlight: true,
      },
    ];

    if (audit.balconyArea && audit.balconyArea > 0) {
      summaryRows.push({
        label: 'Exclusive Balcony Area',
        sub: 'Excluded from Carpet under RERA Sec 2(k); Included in Built-up Area',
        val: audit.balconyArea,
        highlight: false,
      });
    }

    if (audit.utilityOutsideArea && audit.utilityOutsideArea > 0) {
      summaryRows.push({
        label: 'Dry Balcony (Outside Outer Wall)',
        sub: 'Cantilevered utility; Excluded from Carpet; Included in Built-up',
        val: audit.utilityOutsideArea,
        highlight: false,
      });
    }

    summaryRows.push(
      {
        label: `Internal Wall Area (${audit.internalWallPercent.toFixed(1)}%)`,
        sub: 'Mandated inclusion under RERA Sec 2(k)',
        val: audit.internalWallArea,
        highlight: false,
      },
      {
        label: 'Built-up Area (Plinth)',
        sub: 'Carpet area + internal/external walls + balconies/outdoor utilities',
        val: audit.builtUpArea,
        highlight: true,
      },
      {
        label: `External Wall Area (${audit.externalWallPercent.toFixed(1)}%)`,
        sub: 'External perimeter boundary walls included in Built-up',
        val: audit.externalWallArea,
        highlight: false,
      },
      {
        label: `Loading / Common Area (${audit.loadingPercent.toFixed(1)}%)`,
        sub: 'Proportionate share of corridors, lobby, lifts',
        val: audit.loadingArea,
        highlight: false,
      },
      {
        label: 'Super Built-up / Saleable Area',
        sub: 'Built-up area + proportionate common loading area',
        val: audit.superBuiltUpArea,
        highlight: true,
      }
    );

    summaryRows.forEach(row => {
      if (row.highlight) {
        doc.setFillColor(238, 243, 255);
        doc.setDrawColor(191, 208, 255);
        doc.roundedRect(12, currentY, pageWidth - 24, 11, 1.5, 1.5, 'FD');
      } else {
        doc.setDrawColor(241, 245, 249);
        doc.line(12, currentY + 10, pageWidth - 12, currentY + 10);
      }

      doc.setFont('helvetica', row.highlight ? 'bold' : 'normal');
      doc.setFontSize(9);
      doc.setTextColor(row.highlight ? 23 : 51, row.highlight ? 43 : 65, row.highlight ? 101 : 85);
      doc.text(row.label, 16, currentY + (row.highlight ? 5.5 : 5));

      doc.setFontSize(7);
      doc.setTextColor(148, 163, 184);
      doc.text(row.sub, 16, currentY + (row.highlight ? 9 : 8.5));

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9.5);
      doc.setTextColor(row.highlight ? 29 : 30, row.highlight ? 78 : 41, row.highlight ? 216 : 59);
      const formattedArea = DimensionParser.formatArea(row.val, displayUnit);
      doc.text(formattedArea, pageWidth - 16, currentY + 7, { align: 'right' });

      currentY += 12;
    });

    currentY += 3;

    // 3b. Calculated Wall & Efficiency Assumptions Callout
    doc.setFillColor(248, 250, 253);
    doc.setDrawColor(226, 232, 240);
    doc.roundedRect(12, currentY, pageWidth - 24, 16, 2, 2, 'FD');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(7.5);
    doc.setTextColor(23, 43, 101);
    doc.text('Calculated Wall & Area Assumptions:', 16, currentY + 4.5);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7);
    doc.setTextColor(71, 85, 105);
    const efficiency =
      audit.superBuiltUpArea > 0
        ? ((audit.carpetArea / audit.superBuiltUpArea) * 100).toFixed(1)
        : '0';
    const wallSummary1 = `• Internal Wall Allowance: ${audit.internalWallPercent.toFixed(1)}% (${DimensionParser.formatArea(audit.internalWallArea, displayUnit)})   • External Wall: ${audit.externalWallPercent.toFixed(1)}% (${DimensionParser.formatArea(audit.externalWallArea, displayUnit)})`;
    const wallSummary2 = `• Common Loading Factor: ${audit.loadingPercent.toFixed(1)}% (${DimensionParser.formatArea(audit.loadingArea, displayUnit)})   • Usable Efficiency: ${efficiency}% living carpet`;
    doc.text(wallSummary1, 16, currentY + 9);
    doc.text(wallSummary2, 16, currentY + 13);

    currentY += 20;

    // 4. Room-wise Breakdown Table
    if (audit.rooms && audit.rooms.length > 0) {
      // Check if page overflow
      if (currentY > pageHeight - 75) {
        doc.addPage();
        addWatermark();
        currentY = 16;
      }

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(11);
      doc.setTextColor(23, 43, 101);
      doc.text('Room-wise Breakdown', 12, currentY);
      currentY += 4;

      // Table Header
      doc.setFillColor(241, 245, 249);
      doc.rect(12, currentY, pageWidth - 24, 7, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(8);
      doc.setTextColor(71, 85, 105);

      doc.text('Room / Space', 16, currentY + 4.5);
      doc.text('Length', 90, currentY + 4.5);
      doc.text('Width', 125, currentY + 4.5);
      doc.text(`Area (${DimensionParser.getUnitLabel(displayUnit)})`, pageWidth - 16, currentY + 4.5, { align: 'right' });

      currentY += 7;

      doc.setFont('helvetica', 'normal');
      audit.rooms.forEach((room, idx) => {
        if (currentY > pageHeight - 25) {
          doc.addPage();
          addWatermark();
          currentY = 16;
        }

        if (idx % 2 === 1) {
          doc.setFillColor(250, 252, 255);
          doc.rect(12, currentY, pageWidth - 24, 6.5, 'F');
        }

        doc.setFontSize(8);
        doc.setTextColor(30, 41, 59);
        doc.text(room.name, 16, currentY + 4.5);

        const lenText = DimensionParser.formatLength(room.lengthMeters, displayUnit);
        const widText = DimensionParser.formatLength(room.widthMeters, displayUnit);
        const sqFt = DimensionParser.squareMetersToSquareFeet(room.lengthMeters * room.widthMeters);
        const areaText = DimensionParser.formatArea(sqFt, displayUnit);

        doc.text(lenText, 90, currentY + 4.5);
        doc.text(widText, 125, currentY + 4.5);
        doc.setFont('helvetica', 'bold');
        doc.text(areaText, pageWidth - 16, currentY + 4.5, { align: 'right' });
        doc.setFont('helvetica', 'normal');

        currentY += 6.5;
      });

      currentY += 5;
    }

    // 5. Notes / Assumptions
    if (currentY > pageHeight - 45) {
      doc.addPage();
      addWatermark();
      currentY = 16;
    }

    if (audit.notes && audit.notes.trim().length > 0) {
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9);
      doc.setTextColor(23, 43, 101);
      doc.text('Audit Notes:', 12, currentY);
      currentY += 4;

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8);
      doc.setTextColor(71, 85, 105);
      const splitNotes = doc.splitTextToSize(audit.notes, pageWidth - 24);
      doc.text(splitNotes, 12, currentY);
      currentY += splitNotes.length * 4 + 4;
    }

    // 6. Technical & Legal Disclaimer
    doc.setFillColor(255, 251, 235); // warm light amber
    doc.setDrawColor(244, 212, 122);
    doc.roundedRect(12, currentY, pageWidth - 24, 16, 2, 2, 'FD');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(7.5);
    doc.setTextColor(146, 64, 14);
    doc.text('Verification & Legal Notice:', 16, currentY + 4.5);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.8);
    doc.setTextColor(113, 63, 18);
    const disclaimerText = 'This report is generated by Flatverify.ai for property analysis and verification. RERA Carpet Area definition excludes common areas, external walls, and balconies unless enclosed. Actual on-site measurements may vary slightly due to plaster, skirting, and construction tolerances. Always confirm critical boundaries with an architectural survey before execution.';
    const splitDisclaimer = doc.splitTextToSize(disclaimerText, pageWidth - 32);
    doc.text(splitDisclaimer, 16, currentY + 8);

    // 7. Additional Pages: Floor plan scan photo evidence if present
    if (audit.type === 'scan' && audit.scanPhotos && audit.scanPhotos.length > 0) {
      audit.scanPhotos.forEach((photo, pIdx) => {
        doc.addPage();
        addWatermark();

        doc.setFont('helvetica', 'bold');
        doc.setFontSize(14);
        doc.setTextColor(23, 43, 101);
        doc.text(`Scanned Floor Plan Evidence (Photo ${pIdx + 1})`, 12, 18);

        let imgY = 24;
        if (photo.imageUrl) {
          try {
            doc.addImage(photo.imageUrl, 'JPEG', 12, imgY, pageWidth - 24, 140, undefined, 'FAST');
            imgY += 145;
          } catch {
            // fallback if image cannot be embedded
            doc.setFont('helvetica', 'italic');
            doc.setFontSize(9);
            doc.setTextColor(148, 163, 184);
            doc.text('[Attached floor plan blueprint image]', 12, imgY + 10);
            imgY += 20;
          }
        }

        if (photo.ocrText) {
          doc.setFont('helvetica', 'bold');
          doc.setFontSize(10);
          doc.setTextColor(23, 43, 101);
          doc.text('Extracted OCR Blueprint Text:', 12, imgY);
          imgY += 5;

          doc.setFont('courier', 'normal');
          doc.setFontSize(7);
          doc.setTextColor(71, 85, 105);
          const splitOcr = doc.splitTextToSize(photo.ocrText.slice(0, 1200), pageWidth - 24);
          doc.text(splitOcr, 12, imgY);
        }
      });
    }

    return doc;
  }

  /**
   * Generates a summary document of the calculated carpet area and wall assumptions.
   */
  static generateSummaryPdf(audit: PropertyAudit, displayUnit: AreaDisplayUnit = 'imperial'): jsPDF {
    return this.generateAuditPdf(audit, displayUnit);
  }

  /**
   * Directly exports and downloads the summary PDF for the given audit.
   */
  static exportSummaryPdf(audit: PropertyAudit, displayUnit: AreaDisplayUnit = 'imperial'): void {
    const doc = this.generateSummaryPdf(audit, displayUnit);
    const safeName = (audit.auditName || 'Property_Carpet_Audit')
      .replace(/[^a-zA-Z0-9_-]/g, '_')
      .toLowerCase();
    doc.save(`${safeName}_carpet_area_summary.pdf`);
  }
}
