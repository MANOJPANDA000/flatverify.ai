import React, { useState } from 'react';
import {
  Plus,
  RotateCcw,
  Save,
  FileCheck,
  Sliders,
  ChevronDown,
  ChevronUp,
  Building,
  Home,
  Ruler,
  Layers,
  Sparkles,
  ArrowLeftRight,
  PlusCircle,
  Copy,
  LayoutGrid,
  HelpCircle,
  Info,
  Download,
} from 'lucide-react';
import { RoomData, PropertyAudit, ReraPropertyType, DimensionUnit, AreaDisplayUnit, inferRoomSpaceType } from '../types';
import { DimensionParser } from '../utils/dimensionParser';
import { useSession } from '../context/SessionContext';
import { RoomCard } from '../components/RoomCard';
import { ResultCard } from '../components/ResultCard';
import { AreaUnitControl } from '../components/AreaUnitControl';
import { CalculatorUnitToggle } from '../components/CalculatorUnitToggle';
import { QuickUnitConverter } from '../components/QuickUnitConverter';
import { AuditDetailsModal } from '../components/AuditDetailsModal';
import { PdfViewerModal } from '../components/PdfViewerModal';
import { ReraComplianceChecklist } from '../components/ReraComplianceChecklist';
import { AddIndividualRoomModal } from '../components/AddIndividualRoomModal';
import { AggregateCarpetBreakdown } from '../components/AggregateCarpetBreakdown';
import { WallThicknessVisualizer } from '../components/WallThicknessVisualizer';
import { ReraBalconyUtilityGuide } from '../components/ReraBalconyUtilityGuide';
import { ReraDefinitionModal } from '../components/ReraDefinitionModal';
import { downloadFile } from '../utils/downloadHelper';

export const CalculatorView: React.FC = () => {
  const {
    displayUnit,
    setDisplayUnit,
    defaultInternalWallPercent,
    defaultExternalWallPercent,
    defaultLoadingPercent,
    saveAudit,
  } = useSession();

  // Handle global measurement unit system switch (Imperial vs Metric)
  const handleUnitSystemChange = (newUnit: AreaDisplayUnit) => {
    setDisplayUnit(newUnit);
    // Update all current rooms' dimension entry mode to match
    setRooms(prev =>
      prev.map(r => ({
        ...r,
        unit: newUnit === 'metric' ? 'meterCm' : 'feetInches',
      }))
    );
  };

  // Initial rooms template (standard 2BHK starter)
  const [rooms, setRooms] = useState<RoomData[]>(() => {
    const initUnit: DimensionUnit = displayUnit === 'metric' ? 'meterCm' : 'feetInches';
    return [
      {
        id: 'room_1',
        name: 'Living Room',
        lengthMeters: DimensionParser.feetInchesToMeters(16, 0),
        widthMeters: DimensionParser.feetInchesToMeters(12, 0),
        unit: initUnit,
        isAutoExtracted: false,
        isUserVerified: true,
      },
      {
        id: 'room_2',
        name: 'Master Bedroom',
        lengthMeters: DimensionParser.feetInchesToMeters(12, 0),
        widthMeters: DimensionParser.feetInchesToMeters(14, 0),
        unit: initUnit,
        isAutoExtracted: false,
        isUserVerified: true,
      },
      {
        id: 'room_3',
        name: 'Kitchen',
        lengthMeters: DimensionParser.feetInchesToMeters(8, 6),
        widthMeters: DimensionParser.feetInchesToMeters(10, 0),
        unit: initUnit,
        isAutoExtracted: false,
        isUserVerified: true,
      },
      {
        id: 'room_4',
        name: 'Master Bathroom',
        lengthMeters: DimensionParser.feetInchesToMeters(5, 0),
        widthMeters: DimensionParser.feetInchesToMeters(8, 0),
        unit: initUnit,
        isAutoExtracted: false,
        isUserVerified: true,
      },
    ];
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

  // Modals
  const [isSaveModalOpen, setIsSaveModalOpen] = useState(false);
  const [isPdfModalOpen, setIsPdfModalOpen] = useState(false);
  const [isAddIndividualModalOpen, setIsAddIndividualModalOpen] = useState(false);
  const [isReraModalOpen, setIsReraModalOpen] = useState(false);
  const [reraModalTab, setReraModalTab] = useState<'comparison' | 'balcony' | 'utility' | 'checklist'>('comparison');
  const [savedAuditSuccess, setSavedAuditSuccess] = useState<string | null>(null);

  const openReraModal = (tab: 'comparison' | 'balcony' | 'utility' | 'checklist' = 'comparison') => {
    setReraModalTab(tab);
    setIsReraModalOpen(true);
  };

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
  // Mathematically identical to: internalUsable + internalWalls + externalWalls + balconies + outdoorUtilities
  const builtUpAreaSqFt = reraCarpetAreaSqFt + externalWallAreaSqFt + totalExclusiveOutdoorSqFt;
  const loadingAreaSqFt = builtUpAreaSqFt * (loadingPercent / 100);
  const superBuiltUpAreaSqFt = builtUpAreaSqFt + loadingAreaSqFt;

  // Add individual room from modal
  const handleAddIndividualRoom = (newRoom: RoomData, keepOpen = false) => {
    setRooms(prev => [...prev, newRoom]);
    if (!keepOpen) {
      setIsAddIndividualModalOpen(false);
    }
  };

  // Quick preset button for 1-click individual room addition
  const handleQuickAddPreset = (
    name: string,
    feetLen: number,
    feetWid: number,
    customUnit?: DimensionUnit
  ) => {
    const chosenUnit: DimensionUnit =
      customUnit || (displayUnit === 'metric' ? 'meterCm' : 'feetInches');
    const newRoom: RoomData = {
      id: `room_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
      name,
      lengthMeters: DimensionParser.feetInchesToMeters(feetLen, 0),
      widthMeters: DimensionParser.feetInchesToMeters(feetWid, 0),
      unit: chosenUnit,
      isAutoExtracted: false,
      isUserVerified: true,
    };
    setRooms(prev => [...prev, newRoom]);
  };

  // Duplicate an individual room
  const handleDuplicateRoom = (index: number) => {
    const target = rooms[index];
    if (!target) return;
    const duplicated: RoomData = {
      ...target,
      id: `room_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
      name: `${target.name} (Copy)`,
      isUserVerified: true,
    };
    setRooms(prev => {
      const copy = [...prev];
      copy.splice(index + 1, 0, duplicated);
      return copy;
    });
  };

  // Move room position up or down
  const handleMoveRoom = (index: number, direction: 'up' | 'down') => {
    setRooms(prev => {
      const copy = [...prev];
      const targetIndex = direction === 'up' ? index - 1 : index + 1;
      if (targetIndex < 0 || targetIndex >= copy.length) return prev;
      const temp = copy[index];
      copy[index] = copy[targetIndex];
      copy[targetIndex] = temp;
      return copy;
    });
  };

  // Add room (default blank bedroom)
  const handleAddRoom = () => {
    const newRoom: RoomData = {
      id: `room_${Date.now()}`,
      name: `Bedroom ${rooms.length + 1}`,
      lengthMeters: DimensionParser.feetInchesToMeters(10, 0),
      widthMeters: DimensionParser.feetInchesToMeters(10, 0),
      unit: displayUnit === 'metric' ? 'meterCm' : 'feetInches',
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

  const handleResetAll = () => {
    if (window.confirm('Reset all room dimensions and assumptions back to default?')) {
      const resetUnit: DimensionUnit = displayUnit === 'metric' ? 'meterCm' : 'feetInches';
      setRooms([
        {
          id: 'room_1',
          name: 'Living Room',
          lengthMeters: DimensionParser.feetInchesToMeters(16, 0),
          widthMeters: DimensionParser.feetInchesToMeters(12, 0),
          unit: resetUnit,
          isAutoExtracted: false,
          isUserVerified: true,
        },
      ]);
      setInternalWallPercent(defaultInternalWallPercent);
      setExternalWallPercent(defaultExternalWallPercent);
      setLoadingPercent(defaultLoadingPercent);
    }
  };

  // Build current audit object for preview or saving
  const currentAuditObject: PropertyAudit = {
    id: `calc_${Date.now()}`,
    type: 'calculator',
    auditName: 'Manual Area Calculation Audit',
    timestamp: new Date().toISOString(),
    rooms: rooms.map(r => ({
      name: r.name,
      lengthMeters: r.lengthMeters,
      widthMeters: r.widthMeters,
      unit: r.unit,
      isUserVerified: r.isUserVerified,
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
      ...currentAuditObject,
      ...details,
    });
    setIsSaveModalOpen(false);
    setSavedAuditSuccess(`Audit "${details.auditName}" saved successfully!`);
    setTimeout(() => setSavedAuditSuccess(null), 4000);
  };

  return (
    <div className="space-y-8 pb-16">
      {/* Title & Actions Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-[#0F172A] tracking-tight">
            Manual Carpet Area Calculator
          </h1>
          <p className="text-xs sm:text-sm text-[#64748B] mt-1">
            Specify room-by-room internal measurements to verify usable carpet area, built-up area, and loading.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          {/* Quick-Toggle Unit Converter */}
          <CalculatorUnitToggle
            variant="compact"
            displayUnit={displayUnit}
            onUnitChange={handleUnitSystemChange}
          />

          <button
            type="button"
            onClick={() => openReraModal('comparison')}
            className="px-3.5 py-2 text-xs font-bold text-blue-700 bg-blue-50 hover:bg-blue-100 border border-blue-200 rounded-xl flex items-center gap-1.5 shadow-2xs transition-colors cursor-pointer"
            title="View RERA definitions for Carpet Area vs Built-up Area, Balconies & Utilities"
          >
            <HelpCircle className="w-3.5 h-3.5 text-blue-600" />
            <span>Carpet vs Built-up Rules</span>
          </button>

          <button
            type="button"
            onClick={() => downloadFile('/flutter_rera_calculator.zip', 'flutter_rera_calculator.zip')}
            className="px-3 py-2 text-xs font-bold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 rounded-xl flex items-center gap-1.5 shadow-2xs transition-colors cursor-pointer"
            title="Download complete Flutter project code as .zip"
          >
            <Download className="w-3.5 h-3.5 text-emerald-600" />
            <span>Flutter App (.zip)</span>
          </button>

          <button
            type="button"
            onClick={handleResetAll}
            className="px-3 py-2 text-xs font-bold text-[#64748B] hover:text-[#0F172A] hover:bg-white border border-[#E2E8F0] rounded-xl flex items-center gap-1.5 shadow-2xs transition-colors cursor-pointer"
            title="Reset form"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>Reset</span>
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

      {savedAuditSuccess && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-xs font-bold text-emerald-800 flex items-center justify-between">
          <span>✓ {savedAuditSuccess}</span>
          <button
            onClick={() => setSavedAuditSuccess(null)}
            className="text-emerald-700 hover:text-emerald-900 underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Prominent Unit Switcher Banner */}
      <CalculatorUnitToggle
        displayUnit={displayUnit}
        onUnitChange={handleUnitSystemChange}
        roomCount={rooms.length}
      />

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
        onOpenModal={openReraModal}
      />

      {/* Main Grid: Left = Rooms, Right = Calculations & Assumptions */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left Column: Room Items */}
        <div className="lg:col-span-7 space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 pb-1">
            <div className="flex items-center gap-2">
              <h2 className="font-extrabold text-sm uppercase tracking-wider text-[#475569]">
                Rooms & Enclosed Spaces ({rooms.length})
              </h2>
              {rooms.length > 0 && (
                <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-blue-50 text-blue-700 border border-blue-200">
                  {DimensionParser.formatArea(usableAreaSqFt, displayUnit)} aggregate
                </span>
              )}
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={handleAddRoom}
                className="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-[#334155] font-bold text-xs rounded-xl flex items-center gap-1.5 border border-slate-200 transition-colors cursor-pointer"
                title="Add generic blank room"
              >
                <Plus className="w-3.5 h-3.5" />
                <span className="hidden sm:inline">Blank Room</span>
              </button>

              <button
                type="button"
                onClick={() => setIsAddIndividualModalOpen(true)}
                className="px-3.5 py-1.5 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl flex items-center gap-1.5 shadow-xs transition-all cursor-pointer"
              >
                <PlusCircle className="w-4 h-4" />
                <span>Add Room Individually</span>
              </button>
            </div>
          </div>

          {/* Quick-Add Preset Bar */}
          <div className="p-3 bg-white rounded-2xl border border-[#E2E8F0] shadow-2xs space-y-2">
            <div className="flex items-center justify-between text-[11px] font-bold text-[#64748B]">
              <span className="flex items-center gap-1">
                <Sparkles className="w-3.5 h-3.5 text-blue-600" />
                <span>Quick-Add Individual Spaces:</span>
              </span>
              <span className="text-[10px] text-[#94A3B8]">Click to add instantly</span>
            </div>
            <div className="flex flex-wrap gap-1.5">
              <button
                type="button"
                onClick={() => handleQuickAddPreset('Living Room', 16, 12)}
                className="px-2.5 py-1 rounded-lg text-xs font-bold bg-[#F8FAFC] hover:bg-blue-50 text-[#334155] hover:text-blue-700 border border-[#E2E8F0] hover:border-blue-200 transition-all cursor-pointer"
              >
                {displayUnit === 'metric' ? '+ Living (4.9m×3.7m)' : "+ Living (16'×12')"}
              </button>
              <button
                type="button"
                onClick={() => handleQuickAddPreset('Master Bedroom', 14, 12)}
                className="px-2.5 py-1 rounded-lg text-xs font-bold bg-[#F8FAFC] hover:bg-blue-50 text-[#334155] hover:text-blue-700 border border-[#E2E8F0] hover:border-blue-200 transition-all cursor-pointer"
              >
                {displayUnit === 'metric' ? '+ Master Bed (4.3m×3.7m)' : "+ Master Bed (14'×12')"}
              </button>
              <button
                type="button"
                onClick={() => handleQuickAddPreset(`Bedroom ${rooms.length + 1}`, 11, 10)}
                className="px-2.5 py-1 rounded-lg text-xs font-bold bg-[#F8FAFC] hover:bg-blue-50 text-[#334155] hover:text-blue-700 border border-[#E2E8F0] hover:border-blue-200 transition-all cursor-pointer"
              >
                {displayUnit === 'metric' ? '+ Bed 2 (3.4m×3.0m)' : "+ Bed 2 (11'×10')"}
              </button>
              <button
                type="button"
                onClick={() => handleQuickAddPreset('Kitchen', 10, 8)}
                className="px-2.5 py-1 rounded-lg text-xs font-bold bg-[#F8FAFC] hover:bg-blue-50 text-[#334155] hover:text-blue-700 border border-[#E2E8F0] hover:border-blue-200 transition-all cursor-pointer"
              >
                {displayUnit === 'metric' ? '+ Kitchen (3.0m×2.4m)' : "+ Kitchen (10'×8')"}
              </button>
              <button
                type="button"
                onClick={() => handleQuickAddPreset('Common Bathroom', 8, 5)}
                className="px-2.5 py-1 rounded-lg text-xs font-bold bg-[#F8FAFC] hover:bg-blue-50 text-[#334155] hover:text-blue-700 border border-[#E2E8F0] hover:border-blue-200 transition-all cursor-pointer"
              >
                {displayUnit === 'metric' ? '+ Bath (2.4m×1.5m)' : "+ Bath (8'×5')"}
              </button>
              <button
                type="button"
                onClick={() => handleQuickAddPreset('Living Balcony', 10, 4)}
                className="px-2.5 py-1 rounded-lg text-xs font-bold bg-[#F8FAFC] hover:bg-blue-50 text-[#334155] hover:text-blue-700 border border-[#E2E8F0] hover:border-blue-200 transition-all cursor-pointer"
              >
                {displayUnit === 'metric' ? '+ Balcony (3.0m×1.2m)' : "+ Balcony (10'×4')"}
              </button>
              <button
                type="button"
                onClick={() => handleQuickAddPreset('Utility Area', 6, 4)}
                className="px-2.5 py-1 rounded-lg text-xs font-bold bg-[#F8FAFC] hover:bg-blue-50 text-[#334155] hover:text-blue-700 border border-[#E2E8F0] hover:border-blue-200 transition-all cursor-pointer"
              >
                {displayUnit === 'metric' ? '+ Utility (1.8m×1.2m)' : "+ Utility (6'×4')"}
              </button>
              <button
                type="button"
                onClick={() => setIsAddIndividualModalOpen(true)}
                className="px-2.5 py-1 rounded-lg text-xs font-bold bg-blue-50 text-blue-700 hover:bg-blue-100 border border-blue-200 transition-all cursor-pointer flex items-center gap-1"
              >
                <Plus className="w-3 h-3" />
                <span>More / Custom...</span>
              </button>
            </div>
          </div>

          {/* Rooms List */}
          {rooms.length === 0 ? (
            <div className="p-8 bg-white border-2 border-dashed border-[#CBD5E1] rounded-3xl text-center space-y-3">
              <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center mx-auto">
                <LayoutGrid className="w-6 h-6" />
              </div>
              <h3 className="font-bold text-sm text-[#0F172A]">No rooms in audit yet</h3>
              <p className="text-xs text-[#64748B] max-w-sm mx-auto">
                Add rooms individually to compute the total aggregate RERA carpet area.
              </p>
              <button
                type="button"
                onClick={() => setIsAddIndividualModalOpen(true)}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl inline-flex items-center gap-1.5 cursor-pointer shadow-xs"
              >
                <PlusCircle className="w-4 h-4" />
                <span>Add First Room Individually</span>
              </button>
            </div>
          ) : (
            <div className="space-y-3.5">
              {rooms.map((room, idx) => (
                <RoomCard
                  key={room.id}
                  room={room}
                  index={idx}
                  displayUnit={displayUnit}
                  totalAggregateCarpetSqFt={carpetAreaSqFt}
                  onUpdate={updated => handleUpdateRoom(idx, updated)}
                  onRemove={() => handleRemoveRoom(idx)}
                  onDuplicate={() => handleDuplicateRoom(idx)}
                  onMoveUp={() => handleMoveRoom(idx, 'up')}
                  onMoveDown={() => handleMoveRoom(idx, 'down')}
                  canMoveUp={idx > 0}
                  canMoveDown={idx < rooms.length - 1}
                />
              ))}
            </div>
          )}

          {/* Bottom Add Room Action Buttons */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
            <button
              type="button"
              onClick={() => setIsAddIndividualModalOpen(true)}
              className="py-3.5 px-4 bg-white border-2 border-dashed border-blue-300 hover:border-blue-600 hover:bg-blue-50/50 rounded-2xl text-xs font-bold text-blue-700 flex items-center justify-center gap-2 transition-all cursor-pointer shadow-2xs"
            >
              <PlusCircle className="w-4 h-4 text-blue-600" />
              <span>Add Room Individually (Custom)</span>
            </button>

            <button
              type="button"
              onClick={handleAddRoom}
              className="py-3.5 px-4 bg-white border border-[#CBD5E1] hover:border-slate-400 hover:bg-slate-50 rounded-2xl text-xs font-bold text-[#475569] flex items-center justify-center gap-2 transition-all cursor-pointer"
            >
              <Plus className="w-4 h-4 text-[#64748B]" />
              <span>+ Blank Room</span>
            </button>
          </div>
        </div>

        {/* Right Column: Live Results & Assumptions */}
        <div className="lg:col-span-5 space-y-6 lg:sticky lg:top-20">
          {/* Results Summary Box */}
          <div className="bg-white rounded-3xl p-6 border border-[#E2E8F0] shadow-sm space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 border-b border-[#F1F5F9] gap-2">
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="font-bold text-base text-[#0F172A]">Area Audit Summary</h3>
                  <button
                    type="button"
                    onClick={() => openReraModal('comparison')}
                    className="px-2 py-0.5 text-[10px] font-bold text-blue-700 bg-blue-50 hover:bg-blue-100 border border-blue-200/70 rounded-md flex items-center gap-1 transition-colors cursor-pointer"
                    title="View RERA definitions for Carpet Area vs Built-up Area"
                  >
                    <HelpCircle className="w-3 h-3 text-blue-600" />
                    <span>RERA Rules</span>
                  </button>
                </div>
                <p className="text-xs text-[#64748B]">Real-time statutory calculation</p>
              </div>
              <div className="flex items-center gap-1.5 self-start sm:self-auto">
                <AreaUnitControl
                  value={displayUnit}
                  onChanged={handleUnitSystemChange}
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
                tooltipText="Under RERA Sec 2(k), Carpet Area is the net usable internal floor space + partition walls. Enclosed utilities inside outer perimeter walls are included. Balconies are strictly excluded."
                onInfoClick={() => openReraModal('comparison')}
                infoButtonTitle="View RERA Carpet Area definition & rules"
              />

              {balconySqFt > 0 && (
                <ResultCard
                  title="Exclusive Balcony Area"
                  subtitle="Excluded from RERA Carpet under Sec 2(k); added to Built-up Area"
                  value={balconySqFt}
                  icon={<Building className="w-5 h-5 text-amber-600" />}
                  displayUnit={displayUnit}
                  badge="Built-up Only"
                  tooltipText="RERA Sec 2(k) strictly excludes exclusive balconies & open terraces from Carpet Area. They are disclosed separately and included in Built-up (Plinth) Area."
                  onInfoClick={() => openReraModal('balcony')}
                  infoButtonTitle="View Balcony statutory rules"
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
                  tooltipText="Dry balconies or wash yards projecting outside the flat's continuous external perimeter wall are treated as outdoor service balconies. Excluded from Carpet; included in Built-up Area."
                  onInfoClick={() => openReraModal('utility')}
                  infoButtonTitle="View Utility Area inside vs outside rules"
                />
              )}

              <ResultCard
                title={`Internal Wall Area (${internalWallPercent}%)`}
                subtitle="Area occupied by partition brickwork"
                value={internalWallAreaSqFt}
                icon={<Ruler className="w-5 h-5" />}
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
                icon={<Building className="w-5 h-5" />}
                displayUnit={displayUnit}
                highlighted={true}
                tooltipText="Built-up (Plinth) Area is the total structural footprint: RERA Carpet Area + External Perimeter Walls + All Exclusive Balconies and Outdoor Dry Balconies."
                onInfoClick={() => openReraModal('comparison')}
                infoButtonTitle="View Built-up Area definition & rules"
              />

              <ResultCard
                title={`Loading Area (${loadingPercent}%)`}
                subtitle="Proportionate share of lobbies, lifts, stairs"
                value={loadingAreaSqFt}
                icon={<Layers className="w-5 h-5" />}
                displayUnit={displayUnit}
              />

              <ResultCard
                title="Super Built-up Area"
                subtitle="Built-up + proportionate common loading"
                value={superBuiltUpAreaSqFt}
                icon={<Sparkles className="w-5 h-5" />}
                displayUnit={displayUnit}
                highlighted={true}
                badge="Quoted Area"
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

            {/* Quick Pricing Tool Note */}
            <div className="p-3 bg-[#F8FAFC] rounded-xl border border-[#E2E8F0] text-xs text-[#475569] space-y-1">
              <div className="flex items-center justify-between font-bold text-[#0F172A]">
                <span>Effective Efficiency:</span>
                <span className="text-blue-700 font-extrabold">
                  {superBuiltUpAreaSqFt > 0
                    ? `${((carpetAreaSqFt / superBuiltUpAreaSqFt) * 100).toFixed(1)}% Usable`
                    : '0%'}
                </span>
              </div>
              <div className="text-[11px] text-[#64748B]">
                For every 100 sq ft purchased on Super Built-up, you get ~
                {superBuiltUpAreaSqFt > 0
                  ? ((carpetAreaSqFt / superBuiltUpAreaSqFt) * 100).toFixed(0)
                  : 0}{' '}
                sq ft of actual living room space.
              </div>
            </div>
          </div>

          {/* Wall Thickness Impact Visualizer */}
          <WallThicknessVisualizer
            usableAreaSqFt={usableAreaSqFt}
            internalWallPercent={internalWallPercent}
            onInternalWallPercentChange={setInternalWallPercent}
            displayUnit={displayUnit}
          />

          {/* Quick-Toggle Unit Converter & Conversion Matrix */}
          <QuickUnitConverter
            displayUnit={displayUnit}
            onUnitChange={handleUnitSystemChange}
            carpetAreaSqFt={carpetAreaSqFt}
            builtUpAreaSqFt={builtUpAreaSqFt}
            superBuiltUpAreaSqFt={superBuiltUpAreaSqFt}
          />

          {/* Wall & Loading Assumptions Accordion */}
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
                {/* Internal Wall % */}
                <div>
                  <div className="flex items-center justify-between text-xs font-bold text-[#475569] mb-1.5">
                    <span>Internal Wall Thickness Assumption</span>
                    <span className="text-blue-700 font-extrabold">
                      {internalWallPercent.toFixed(1)}%
                    </span>
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
                  <div className="flex justify-between text-[10px] text-[#94A3B8]">
                    <span>5% (Light drywall)</span>
                    <span>12% (Standard brick)</span>
                    <span>20% (Heavy masonry)</span>
                  </div>
                  <div className="mt-2 p-2 bg-blue-50/70 border border-blue-200/60 rounded-lg text-[11px] text-[#334155] flex items-center justify-between">
                    <span className="text-[#64748B]">Impact on floor plate:</span>
                    <span className="font-bold text-blue-900">
                      +{DimensionParser.formatArea(internalWallAreaSqFt, displayUnit)} in walls (
                      {builtUpAreaSqFt > 0
                        ? ((usableAreaSqFt / builtUpAreaSqFt) * 100).toFixed(1)
                        : 0}
                      % walkable)
                    </span>
                  </div>
                </div>

                {/* Loading % */}
                <div>
                  <div className="flex items-center justify-between text-xs font-bold text-[#475569] mb-1.5">
                    <span>Developer Loading Percentage</span>
                    <span className="text-blue-700 font-extrabold">
                      {loadingPercent.toFixed(1)}%
                    </span>
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
                  <div className="flex justify-between text-[10px] text-[#94A3B8]">
                    <span>15% (Low rise)</span>
                    <span>30% (Standard high-rise)</span>
                    <span>50% (Luxury club)</span>
                  </div>
                </div>

                {/* External Wall % */}
                <div>
                  <div className="flex items-center justify-between text-xs font-bold text-[#475569] mb-1.5">
                    <span>External Wall / Façade Allowance</span>
                    <span className="text-blue-700 font-extrabold">
                      {externalWallPercent.toFixed(1)}%
                    </span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="10"
                    step="0.5"
                    value={externalWallPercent}
                    onChange={e => setExternalWallPercent(parseFloat(e.target.value))}
                    className="w-full accent-blue-600 cursor-pointer"
                  />
                  <div className="flex justify-between text-[10px] text-[#94A3B8]">
                    <span>0% (Excluded in RERA)</span>
                    <span>5%</span>
                    <span>10%</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Total Aggregate Carpet Area Calculation & Distribution Section */}
      <AggregateCarpetBreakdown
        rooms={rooms}
        usableAreaSqFt={usableAreaSqFt}
        carpetAreaSqFt={carpetAreaSqFt}
        internalWallPercent={internalWallPercent}
        internalWallAreaSqFt={internalWallAreaSqFt}
        builtUpAreaSqFt={builtUpAreaSqFt}
        externalWallPercent={externalWallPercent}
        externalWallAreaSqFt={externalWallAreaSqFt}
        loadingPercent={loadingPercent}
        loadingAreaSqFt={loadingAreaSqFt}
        superBuiltUpAreaSqFt={superBuiltUpAreaSqFt}
        displayUnit={displayUnit}
        propertyType={propertyType}
      />

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

      {/* Add Individual Room Modal */}
      <AddIndividualRoomModal
        isOpen={isAddIndividualModalOpen}
        onClose={() => setIsAddIndividualModalOpen(false)}
        onAddRoom={handleAddIndividualRoom}
        displayUnit={displayUnit}
        existingRoomCount={rooms.length}
      />

      {/* Save Modal */}
      <AuditDetailsModal
        isOpen={isSaveModalOpen}
        defaultName="Manual Property Carpet Audit"
        onClose={() => setIsSaveModalOpen(false)}
        onSave={handleSaveConfirmed}
      />

      {/* PDF Modal */}
      <PdfViewerModal
        isOpen={isPdfModalOpen}
        audit={currentAuditObject}
        displayUnit={displayUnit}
        onClose={() => setIsPdfModalOpen(false)}
      />

      {/* RERA Definition & Categorization Modal */}
      <ReraDefinitionModal
        isOpen={isReraModalOpen}
        onClose={() => setIsReraModalOpen(false)}
        displayUnit={displayUnit}
        initialTab={reraModalTab}
      />
    </div>
  );
};
