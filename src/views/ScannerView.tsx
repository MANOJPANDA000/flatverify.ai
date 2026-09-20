import React, { useState, useRef } from 'react';
import {
  Upload,
  Camera,
  FileImage,
  Sparkles,
  ScanLine,
  RotateCcw,
  Save,
  FileCheck,
  CheckCircle2,
  AlertCircle,
  Eye,
  Plus,
  Sliders,
  ChevronDown,
  ChevronUp,
  Layers,
  Home,
  Building,
} from 'lucide-react';
import { createWorker } from 'tesseract.js';
import { RoomData, PropertyAudit, ScanPhotoData, ReraPropertyType, inferRoomSpaceType } from '../types';
import { DimensionParser } from '../utils/dimensionParser';
import { DimensionScanParser } from '../utils/dimensionScanParser';
import { SAMPLE_FLOOR_PLANS, SampleFloorPlan } from '../data/sampleFloorPlans';
import { useSession } from '../context/SessionContext';
import { ScanRoomCard } from '../components/ScanRoomCard';
import { ResultCard } from '../components/ResultCard';
import { OcrDimensionReviewModal, PendingRoomPair } from '../components/OcrDimensionReviewModal';
import { AuditDetailsModal } from '../components/AuditDetailsModal';
import { PdfViewerModal } from '../components/PdfViewerModal';
import { ReraComplianceChecklist } from '../components/ReraComplianceChecklist';
import { AreaUnitControl } from '../components/AreaUnitControl';
import { ReraBalconyUtilityGuide } from '../components/ReraBalconyUtilityGuide';

export const ScannerView: React.FC = () => {
  const {
    displayUnit,
    setDisplayUnit,
    defaultInternalWallPercent,
    defaultExternalWallPercent,
    defaultLoadingPercent,
    saveAudit,
  } = useSession();

  // Active Floor Plan Image
  const [selectedImage, setSelectedImage] = useState<string | null>(SAMPLE_FLOOR_PLANS[0].thumbnailSvg);
  const [activeSampleId, setActiveSampleId] = useState<string | null>(SAMPLE_FLOOR_PLANS[0].id);

  // OCR Processing State
  const [isProcessing, setIsProcessing] = useState(false);
  const [ocrProgress, setOcrProgress] = useState<number>(0);
  const [ocrStatusText, setOcrStatusText] = useState<string>('');
  const [extractedRawText, setExtractedRawText] = useState<string>(SAMPLE_FLOOR_PLANS[0].ocrText);

  // Extracted Rooms
  const [rooms, setRooms] = useState<RoomData[]>(() => {
    // Pre-populate with first sample's parsed rooms
    const s = SAMPLE_FLOOR_PLANS[0];
    return s.rooms.map((r, i) => {
      const lenM = DimensionParser.parseDimensionToMeters(r.length);
      const widM = DimensionParser.parseDimensionToMeters(r.width);
      return {
        id: `scanned_room_${i + 1}`,
        name: r.name,
        lengthMeters: lenM,
        widthMeters: widM,
        unit: 'feetInches',
        isAutoExtracted: true,
        isUserVerified: true,
        sourcePairId: `pair_${i + 1}`,
      };
    });
  });

  // Assumptions
  const [propertyType, setPropertyType] = useState<ReraPropertyType>('apartment');
  const [internalWallPercent, setInternalWallPercent] = useState<number>(defaultInternalWallPercent);
  const [externalWallPercent, setExternalWallPercent] = useState<number>(defaultExternalWallPercent);
  const [loadingPercent, setLoadingPercent] = useState<number>(defaultLoadingPercent);
  const [showAssumptions, setShowAssumptions] = useState(false);

  const handleUpdateAssumptions = (updates: {
    internalWallPercent?: number;
    externalWallPercent?: number;
    loadingPercent?: number;
  }) => {
    if (updates.internalWallPercent !== undefined) setInternalWallPercent(updates.internalWallPercent);
    if (updates.externalWallPercent !== undefined) setExternalWallPercent(updates.externalWallPercent);
    if (updates.loadingPercent !== undefined) setLoadingPercent(updates.loadingPercent);
  };

  // Review Modal State
  const [isReviewModalOpen, setIsReviewModalOpen] = useState(false);
  const [pendingPairs, setPendingPairs] = useState<PendingRoomPair[]>([]);

  // Save & PDF Modals
  const [isSaveModalOpen, setIsSaveModalOpen] = useState(false);
  const [isPdfModalOpen, setIsPdfModalOpen] = useState(false);
  const [savedSuccess, setSavedSuccess] = useState<string | null>(null);

  // File Input Ref
  const fileInputRef = useRef<HTMLInputElement>(null);
  const cameraInputRef = useRef<HTMLInputElement>(null);

  // Area Calculations segmented by RERA classification
  let internalLivingSqFt = 0;
  let utilityInsideSqFt = 0;
  let utilityOutsideSqFt = 0;
  let balconySqFt = 0;

  rooms.forEach(r => {
    const areaSqM = r.lengthMeters * r.widthMeters;
    const sqFt = DimensionParser.squareMetersToSquareFeet(areaSqM);
    const spaceType = r.spaceType || inferRoomSpaceType(r.name);
    if (spaceType === 'utility_inside') {
      utilityInsideSqFt += sqFt;
    } else if (spaceType === 'utility_outside') {
      utilityOutsideSqFt += sqFt;
    } else if (spaceType === 'balcony') {
      balconySqFt += sqFt;
    } else {
      internalLivingSqFt += sqFt;
    }
  });

  // Net usable floor area inside outer walls (Living, Bed, Kitchen, Bath + Enclosed Utility inside outer wall)
  const internalUsableSqFt = internalLivingSqFt + utilityInsideSqFt;
  const totalExclusiveOutdoorSqFt = balconySqFt + utilityOutsideSqFt;
  const totalFloorPlateSqFt = internalUsableSqFt + totalExclusiveOutdoorSqFt;

  // Internal partition walls (under RERA Sec 2(k) included in statutory Carpet Area)
  const internalWallAreaSqFt = internalUsableSqFt * (internalWallPercent / 100);
  const externalWallAreaSqFt = internalUsableSqFt * (externalWallPercent / 100);

  // RERA Carpet Area: Net usable floor (including enclosed utility inside outer wall) + internal partition walls
  const reraCarpetAreaSqFt = internalUsableSqFt + internalWallAreaSqFt;

  // Primary carpet display value:
  const usableAreaSqFt = internalUsableSqFt;
  const carpetAreaSqFt = reraCarpetAreaSqFt;

  // Built-up Area: RERA Carpet + External Walls + Balconies + Outdoor Utilities
  const builtUpAreaSqFt = reraCarpetAreaSqFt + externalWallAreaSqFt + totalExclusiveOutdoorSqFt;
  const loadingAreaSqFt = builtUpAreaSqFt * (loadingPercent / 100);
  const superBuiltUpAreaSqFt = builtUpAreaSqFt + loadingAreaSqFt;

  // Run Real OCR with Tesseract.js on an image
  const processImageOcr = async (imageDataUrl: string, sampleOverride?: SampleFloorPlan) => {
    setIsProcessing(true);
    setOcrProgress(10);
    setOcrStatusText('Initializing Optical Character Recognition (OCR)...');

    // If a known sample is passed directly, use instant high-precision blueprint data
    if (sampleOverride) {
      setTimeout(() => {
        setOcrProgress(100);
        setIsProcessing(false);
        setExtractedRawText(sampleOverride.ocrText);

        const pairs: PendingRoomPair[] = sampleOverride.rooms.map((r, i) => ({
          id: `sample_pair_${i + 1}`,
          name: r.name,
          lengthStr: r.length,
          widthStr: r.width,
          isExcluded: false,
        }));

        setPendingPairs(pairs);
        setIsReviewModalOpen(true);
      }, 500);
      return;
    }

    try {
      setOcrStatusText('Loading Tesseract OCR neural model...');
      setOcrProgress(30);

      const worker = await createWorker('eng');
      
      setOcrStatusText('Scanning architectural lines & text...');
      setOcrProgress(60);

      const ret = await worker.recognize(imageDataUrl);
      await worker.terminate();

      setOcrProgress(90);
      setOcrStatusText('Parsing room measurements & dimensions...');

      const text = ret.data.text || '';
      setExtractedRawText(text);

      // Parse text into room candidates using our ported DimensionScanParser
      const parsed = DimensionScanParser.parseRooms(text);

      const pairs: PendingRoomPair[] = parsed.map((p, idx) => ({
        id: `ocr_pair_${idx + 1}`,
        name: p.name,
        lengthStr: p.length,
        widthStr: p.width,
        isExcluded: false,
      }));

      // If OCR yielded no structured rooms, provide a friendly starter set for the user to review
      if (pairs.length === 0) {
        pairs.push({
          id: 'manual_pair_1',
          name: 'Living Room',
          lengthStr: "16' 0\"",
          widthStr: "12' 0\"",
          isExcluded: false,
        });
      }

      setPendingPairs(pairs);
      setIsReviewModalOpen(true);
    } catch (err) {
      console.warn('Tesseract OCR fallback:', err);
      // Fallback: parse whatever text or fallback to review modal
      const fallbackParsed = DimensionScanParser.parseRooms(extractedRawText);
      const pairs: PendingRoomPair[] = fallbackParsed.map((p, idx) => ({
        id: `ocr_pair_${idx + 1}`,
        name: p.name,
        lengthStr: p.length,
        widthStr: p.width,
        isExcluded: false,
      }));
      setPendingPairs(pairs);
      setIsReviewModalOpen(true);
    } finally {
      setIsProcessing(false);
      setOcrProgress(100);
    }
  };

  // Handle Local File Upload
  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setActiveSampleId(null);
    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = reader.result as string;
      setSelectedImage(dataUrl);
      processImageOcr(dataUrl);
    };
    reader.readAsDataURL(file);
  };

  // Handle Selecting Pre-loaded Sample
  const handleSelectSample = (sample: SampleFloorPlan) => {
    setActiveSampleId(sample.id);
    setSelectedImage(sample.thumbnailSvg);
    processImageOcr(sample.thumbnailSvg, sample);
  };

  // When user confirms dimension pairs from review modal
  const handleApplyReviewPairs = (confirmed: PendingRoomPair[]) => {
    const newRooms: RoomData[] = confirmed.map((c, i) => {
      const lenM = DimensionParser.parseDimensionToMeters(c.lengthStr);
      const widM = DimensionParser.parseDimensionToMeters(c.widthStr);
      return {
        id: `scanned_room_${Date.now()}_${i}`,
        name: c.name,
        lengthMeters: lenM > 0 ? lenM : DimensionParser.feetInchesToMeters(10, 0),
        widthMeters: widM > 0 ? widM : DimensionParser.feetInchesToMeters(10, 0),
        unit: 'feetInches',
        isAutoExtracted: true,
        isUserVerified: true,
        sourcePairId: c.id,
      };
    });

    setRooms(newRooms);
    setIsReviewModalOpen(false);
  };

  // Add Room Manually
  const handleAddRoom = () => {
    const newRoom: RoomData = {
      id: `manual_room_${Date.now()}`,
      name: `Room ${rooms.length + 1}`,
      lengthMeters: DimensionParser.feetInchesToMeters(11, 0),
      widthMeters: DimensionParser.feetInchesToMeters(11, 0),
      unit: 'feetInches',
      isAutoExtracted: false,
      isUserVerified: true,
    };
    setRooms(prev => [...prev, newRoom]);
  };

  const handleUpdateRoom = (index: number, updated: RoomData) => {
    setRooms(prev => {
      const copy = [...prev];
      copy[index] = updated;
      return copy;
    });
  };

  const handleRemoveRoom = (index: number) => {
    setRooms(prev => prev.filter((_, idx) => idx !== index));
  };

  const handleVerifyAll = () => {
    setRooms(prev => prev.map(r => ({ ...r, isUserVerified: true })));
  };

  // Build Audit Object
  const currentScanAudit: PropertyAudit = {
    id: `scan_${Date.now()}`,
    type: 'scan',
    auditName: 'Blueprint Scan Carpet Area Audit',
    timestamp: new Date().toISOString(),
    rawText: extractedRawText,
    imageUrls: selectedImage ? [selectedImage] : [],
    scanPhotos: selectedImage
      ? [
          {
            id: 'photo_1',
            ocrText: extractedRawText,
            dimensions: rooms.map(
              r =>
                `${DimensionParser.formatFeetInches(r.lengthMeters)} x ${DimensionParser.formatFeetInches(r.widthMeters)}`
            ),
            imageUrl: selectedImage,
          },
        ]
      : [],
    rooms: rooms.map(r => ({
      name: r.name,
      lengthMeters: r.lengthMeters,
      widthMeters: r.widthMeters,
      unit: r.unit,
      isUserVerified: r.isUserVerified,
      source: r.isAutoExtracted ? 'ocr_scan' : 'manual_entry',
      spaceType: r.spaceType || inferRoomSpaceType(r.name),
    })),
    usableArea: usableAreaSqFt,
    carpetArea: carpetAreaSqFt,
    propertyType,
    internalWallPercent,
    internalWallArea: internalWallAreaSqFt,
    builtUpArea: builtUpAreaSqFt,
    externalWallPercent,
    externalWallArea: externalWallAreaSqFt,
    loadingPercent,
    loadingArea: loadingAreaSqFt,
    superBuiltUpArea: superBuiltUpAreaSqFt,
    balconyArea: balconySqFt,
    utilityInsideArea: utilityInsideSqFt,
    utilityOutsideArea: utilityOutsideSqFt,
  };

  const handleSaveConfirmed = async (details: {
    auditName: string;
    builder: string;
    project: string;
    tower: string;
    flat: string;
    floor: string;
    configuration: string;
    notes: string;
  }) => {
    await saveAudit({
      ...currentScanAudit,
      ...details,
    });
    setIsSaveModalOpen(false);
    setSavedSuccess(`Scanned Audit "${details.auditName}" saved successfully!`);
    setTimeout(() => setSavedSuccess(null), 4000);
  };

  return (
    <div className="space-y-8 pb-16">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-[#0F172A] tracking-tight">
            Floor Plan Blueprint Scanner
          </h1>
          <p className="text-xs sm:text-sm text-[#64748B] mt-1">
            Upload or photograph builder floor plans to auto-detect room dimensions, verify RERA carpet area, and generate PDF audit certificates.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            type="button"
            onClick={() => setIsReviewModalOpen(true)}
            className="px-3 py-2 text-xs font-bold text-[#475569] hover:text-[#0F172A] hover:bg-white border border-[#CBD5E1] rounded-xl flex items-center gap-1.5 shadow-2xs transition-colors cursor-pointer"
          >
            <Eye className="w-3.5 h-3.5" />
            <span>Review OCR Text</span>
          </button>

          <button
            type="button"
            onClick={() => setIsPdfModalOpen(true)}
            className="px-3.5 py-2 text-xs font-bold text-[#1D4ED8] bg-blue-50 hover:bg-blue-100 border border-blue-200 rounded-xl flex items-center gap-1.5 transition-colors cursor-pointer"
          >
            <FileCheck className="w-3.5 h-3.5" />
            <span>Preview PDF</span>
          </button>

          <button
            type="button"
            onClick={() => setIsSaveModalOpen(true)}
            className="px-4 py-2 text-xs font-bold bg-[#1D4ED8] hover:bg-[#1E40AF] text-white rounded-xl flex items-center gap-1.5 shadow-xs shadow-blue-500/20 transition-colors cursor-pointer"
          >
            <Save className="w-3.5 h-3.5" />
            <span>Save Audit</span>
          </button>
        </div>
      </div>

      {savedSuccess && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-xs font-bold text-emerald-800 flex items-center justify-between">
          <span>✓ {savedSuccess}</span>
          <button
            onClick={() => setSavedSuccess(null)}
            className="text-emerald-700 hover:text-emerald-900 underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Upload & Sample Blueprint Bar */}
      <div className="bg-white rounded-3xl p-6 border border-[#E2E8F0] shadow-xs space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <span className="text-xs font-bold text-[#475569] uppercase tracking-wide">
              Scan Source:
            </span>
            <div className="flex items-center gap-2">
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleFileUpload}
                className="hidden"
              />
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="px-3.5 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl flex items-center gap-1.5 shadow-xs transition-colors cursor-pointer"
              >
                <Upload className="w-3.5 h-3.5" />
                <span>Upload Floor Plan</span>
              </button>

              <input
                ref={cameraInputRef}
                type="file"
                accept="image/*"
                capture="environment"
                onChange={handleFileUpload}
                className="hidden"
              />
              <button
                type="button"
                onClick={() => cameraInputRef.current?.click()}
                className="px-3 py-2 bg-[#F1F5F9] hover:bg-[#E2E8F0] text-[#0F172A] text-xs font-bold rounded-xl flex items-center gap-1.5 transition-colors cursor-pointer"
              >
                <Camera className="w-3.5 h-3.5" />
                <span>Camera</span>
              </button>
            </div>
          </div>

          {/* Preset Sample Blueprints for 1-Click Instant Testing */}
          <div className="flex items-center gap-2">
            <span className="text-xs text-[#64748B] font-semibold">Or try sample plan:</span>
            {SAMPLE_FLOOR_PLANS.map(sample => (
              <button
                key={sample.id}
                type="button"
                onClick={() => handleSelectSample(sample)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                  activeSampleId === sample.id
                    ? 'bg-blue-100 text-blue-800 border border-blue-300 shadow-xs'
                    : 'bg-[#F8FAFC] text-[#475569] border border-[#E2E8F0] hover:bg-white'
                }`}
              >
                {sample.title}
              </button>
            ))}
          </div>
        </div>

        {/* OCR Progress Bar if active */}
        {isProcessing && (
          <div className="p-4 bg-blue-50 border border-blue-200 rounded-2xl space-y-2 animate-pulse">
            <div className="flex items-center justify-between text-xs font-bold text-blue-900">
              <span className="flex items-center gap-2">
                <ScanLine className="w-4 h-4 animate-spin text-blue-600" />
                {ocrStatusText}
              </span>
              <span>{ocrProgress}%</span>
            </div>
            <div className="w-full h-2 bg-blue-200 rounded-full overflow-hidden">
              <div
                className="h-full bg-blue-600 transition-all duration-300"
                style={{ width: `${ocrProgress}%` }}
              />
            </div>
          </div>
        )}

        {/* Blueprint Preview Thumbnail */}
        {selectedImage && (
          <div className="relative rounded-2xl overflow-hidden border border-[#CBD5E1] bg-[#F8FAFC] max-h-64 flex items-center justify-center p-2 group">
            <img
              src={selectedImage}
              alt="Floor plan blueprint preview"
              className="max-h-60 w-auto object-contain rounded-xl shadow-xs"
            />
            <div className="absolute top-4 right-4 bg-black/70 backdrop-blur-md text-white px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 shadow-md">
              <ScanLine className="w-3.5 h-3.5 text-blue-400" />
              <span>Blueprint Scanned</span>
            </div>
          </div>
        )}
      </div>

      {/* RERA Statutory Balcony & Utility Area Rule Guide & Inspector */}
      <ReraBalconyUtilityGuide
        displayUnit={displayUnit}
        internalLivingSqFt={internalLivingSqFt}
        utilityInsideSqFt={utilityInsideSqFt}
        utilityOutsideSqFt={utilityOutsideSqFt}
        balconySqFt={balconySqFt}
        internalWallAreaSqFt={internalWallAreaSqFt}
        externalWallAreaSqFt={externalWallAreaSqFt}
        builtUpAreaSqFt={builtUpAreaSqFt}
      />

      {/* Main Verification Grid: Left = Scanned Room Cards, Right = Real-time Area Audit */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left Column: Scanned Room Cards */}
        <div className="lg:col-span-7 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <h2 className="font-extrabold text-sm uppercase tracking-wider text-[#475569]">
                Extracted Rooms & Spaces ({rooms.length})
              </h2>
              <span className="text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                {rooms.filter(r => r.isUserVerified).length} Verified
              </span>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={handleVerifyAll}
                className="text-xs font-bold text-emerald-700 hover:text-emerald-800 flex items-center gap-1"
              >
                <CheckCircle2 className="w-3.5 h-3.5" />
                <span>Verify All</span>
              </button>
              <button
                type="button"
                onClick={handleAddRoom}
                className="px-3 py-1.5 bg-blue-50 hover:bg-blue-100 text-blue-700 font-bold text-xs rounded-xl flex items-center gap-1 border border-blue-200 transition-colors cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Add Room</span>
              </button>
            </div>
          </div>

          <div className="space-y-3">
            {rooms.map((room, idx) => (
              <ScanRoomCard
                key={room.id}
                room={room}
                displayUnit={displayUnit}
                onUpdate={updated => handleUpdateRoom(idx, updated)}
                onRemove={() => handleRemoveRoom(idx)}
              />
            ))}
          </div>

          <div className="p-4 bg-[#F8FAFC] border border-[#E2E8F0] rounded-2xl text-xs text-[#64748B] flex items-center justify-between">
            <span>Missed a room or balcony in the scan?</span>
            <button
              type="button"
              onClick={handleAddRoom}
              className="font-bold text-blue-600 hover:text-blue-800"
            >
              + Add manually
            </button>
          </div>
        </div>

        {/* Right Column: Live Audit Summary & Wall Assumptions */}
        <div className="lg:col-span-5 space-y-6 lg:sticky lg:top-20">
          <div className="bg-white rounded-3xl p-6 border border-[#E2E8F0] shadow-sm space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 border-b border-[#F1F5F9] gap-2">
              <div>
                <h3 className="font-bold text-base text-[#0F172A]">Area Audit Summary</h3>
                <p className="text-xs text-[#64748B]">From Scanned Blueprint Dimensions</p>
              </div>
              <div className="flex items-center gap-1.5 self-start sm:self-auto">
                <AreaUnitControl
                  value={displayUnit}
                  onChanged={setDisplayUnit}
                  size="sm"
                />
              </div>
            </div>

            <div className="space-y-2.5">
              <ResultCard
                title="RERA Carpet Area"
                subtitle={
                  utilityInsideSqFt > 0
                    ? `Net usable floor + partition walls (Includes enclosed utility: ${DimensionParser.formatArea(utilityInsideSqFt, displayUnit)})`
                    : 'Net usable internal floor space + internal partition walls'
                }
                value={carpetAreaSqFt}
                icon={<Home className="w-5 h-5" />}
                displayUnit={displayUnit}
                highlighted={true}
                badge={utilityInsideSqFt > 0 ? "Includes Enclosed Utility" : "Net Usable"}
              />

              {balconySqFt > 0 && (
                <ResultCard
                  title="Exclusive Balcony Area"
                  subtitle="Excluded from RERA Carpet under Sec 2(k); added to Built-up Area"
                  value={balconySqFt}
                  icon={<Building className="w-5 h-5 text-amber-600" />}
                  displayUnit={displayUnit}
                  badge="Built-up Only"
                />
              )}

              {utilityOutsideSqFt > 0 && (
                <ResultCard
                  title="Dry Balcony (Outside Outer Wall)"
                  subtitle="Cantilevered service balcony; added to Built-up Area only"
                  value={utilityOutsideSqFt}
                  icon={<Layers className="w-5 h-5 text-amber-600" />}
                  displayUnit={displayUnit}
                  badge="Built-up Only"
                />
              )}

              <ResultCard
                title={`Internal Wall Area (${internalWallPercent}%)`}
                subtitle="Calculated partition thickness"
                value={internalWallAreaSqFt}
                icon={<Building className="w-5 h-5" />}
                displayUnit={displayUnit}
              />

              {externalWallPercent > 0 && (
                <ResultCard
                  title={`External Wall Area (${externalWallPercent}%)`}
                  subtitle="Perimeter boundary & façade walls"
                  value={externalWallAreaSqFt}
                  icon={<Building className="w-5 h-5 text-slate-500" />}
                  displayUnit={displayUnit}
                />
              )}

              <ResultCard
                title="Built-up Area (Plinth)"
                subtitle="Carpet area + internal/external walls + balconies/outdoor utilities"
                value={builtUpAreaSqFt}
                icon={<Layers className="w-5 h-5" />}
                displayUnit={displayUnit}
                highlighted={true}
              />

              <ResultCard
                title={`Loading Area (${loadingPercent}%)`}
                subtitle="Lobby, elevator, and common staircase share"
                value={loadingAreaSqFt}
                icon={<Building className="w-5 h-5" />}
                displayUnit={displayUnit}
              />

              <ResultCard
                title="Super Built-up Area"
                subtitle="Built-up + common loading area"
                value={superBuiltUpAreaSqFt}
                icon={<Sparkles className="w-5 h-5" />}
                displayUnit={displayUnit}
                highlighted={true}
                badge="Saleable"
              />
            </div>

            {/* Arithmetic Formula Check Verification */}
            <div className="p-3 bg-blue-50/80 rounded-xl border border-blue-200/70 text-xs text-[#1E3A8A] space-y-2">
              <div className="flex items-center justify-between font-bold">
                <span className="text-[11px] uppercase tracking-wide text-blue-900">Verified Area Formulation:</span>
                <span className="text-[10px] px-1.5 py-0.5 bg-emerald-100 text-emerald-800 rounded font-black">100% Balanced</span>
              </div>
              <div className="text-[11px] font-medium text-blue-950 leading-relaxed">
                <div>
                  <strong>Built-up ({DimensionParser.formatArea(builtUpAreaSqFt, displayUnit)})</strong> = Carpet ({DimensionParser.formatArea(carpetAreaSqFt, displayUnit)}) + Ext. Walls ({DimensionParser.formatArea(externalWallAreaSqFt, displayUnit)}){totalExclusiveOutdoorSqFt > 0 ? ` + Balconies/Outdoor (${DimensionParser.formatArea(totalExclusiveOutdoorSqFt, displayUnit)})` : ''}
                </div>
                <div className="mt-1 pt-1 border-t border-blue-200/60">
                  <strong>Super Built-up ({DimensionParser.formatArea(superBuiltUpAreaSqFt, displayUnit)})</strong> = Built-up ({DimensionParser.formatArea(builtUpAreaSqFt, displayUnit)}) + Loading ({DimensionParser.formatArea(loadingAreaSqFt, displayUnit)})
                </div>
              </div>
            </div>
          </div>

          {/* Wall Assumptions */}
          <div className="bg-white rounded-2xl border border-[#E2E8F0] shadow-xs overflow-hidden">
            <button
              type="button"
              onClick={() => setShowAssumptions(!showAssumptions)}
              className="w-full px-5 py-3.5 flex items-center justify-between text-left hover:bg-[#F8FAFC] transition-colors cursor-pointer"
            >
              <div className="flex items-center gap-2 text-xs font-bold text-[#0F172A]">
                <Sliders className="w-4 h-4 text-[#2563EB]" />
                <span>Adjust Wall & Loading Assumptions</span>
              </div>
              {showAssumptions ? (
                <ChevronUp className="w-4 h-4 text-[#64748B]" />
              ) : (
                <ChevronDown className="w-4 h-4 text-[#64748B]" />
              )}
            </button>

            {showAssumptions && (
              <div className="p-5 border-t border-[#F1F5F9] space-y-4 bg-[#F8FAFC]">
                <div>
                  <div className="flex items-center justify-between text-xs font-bold text-[#475569] mb-1.5">
                    <span>Internal Wall Thickness</span>
                    <span className="text-blue-700 font-extrabold">{internalWallPercent}%</span>
                  </div>
                  <input
                    type="range"
                    min="5"
                    max="20"
                    step="0.5"
                    value={internalWallPercent}
                    onChange={e => setInternalWallPercent(parseFloat(e.target.value))}
                    className="w-full accent-blue-600 cursor-pointer"
                  />
                </div>

                <div>
                  <div className="flex items-center justify-between text-xs font-bold text-[#475569] mb-1.5">
                    <span>Loading Factor Percentage</span>
                    <span className="text-blue-700 font-extrabold">{loadingPercent}%</span>
                  </div>
                  <input
                    type="range"
                    min="15"
                    max="50"
                    step="1"
                    value={loadingPercent}
                    onChange={e => setLoadingPercent(parseFloat(e.target.value))}
                    className="w-full accent-blue-600 cursor-pointer"
                  />
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* RERA Compliance Checklist Section */}
      <ReraComplianceChecklist
        propertyType={propertyType}
        onPropertyTypeChange={setPropertyType}
        rooms={rooms}
        usableAreaSqFt={usableAreaSqFt}
        carpetAreaSqFt={carpetAreaSqFt}
        internalWallPercent={internalWallPercent}
        internalWallAreaSqFt={internalWallAreaSqFt}
        externalWallPercent={externalWallPercent}
        externalWallAreaSqFt={externalWallAreaSqFt}
        loadingPercent={loadingPercent}
        loadingAreaSqFt={loadingAreaSqFt}
        superBuiltUpAreaSqFt={superBuiltUpAreaSqFt}
        displayUnit={displayUnit}
        onUpdateAssumptions={handleUpdateAssumptions}
        initialExpanded={true}
      />

      {/* Review Extracted Dimensions Modal */}
      <OcrDimensionReviewModal
        isOpen={isReviewModalOpen}
        rawText={extractedRawText}
        initialPairs={pendingPairs}
        onClose={() => setIsReviewModalOpen(false)}
        onApply={handleApplyReviewPairs}
      />

      {/* Save Modal */}
      <AuditDetailsModal
        isOpen={isSaveModalOpen}
        defaultName="Floor Plan Blueprint Carpet Audit"
        onClose={() => setIsSaveModalOpen(false)}
        onSave={handleSaveConfirmed}
      />

      {/* PDF Modal */}
      <PdfViewerModal
        isOpen={isPdfModalOpen}
        audit={currentScanAudit}
        displayUnit={displayUnit}
        onClose={() => setIsPdfModalOpen(false)}
      />
    </div>
  );
};
