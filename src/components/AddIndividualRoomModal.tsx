import React, { useState } from 'react';
import {
  X,
  Plus,
  Ruler,
  Building2,
  Sparkles,
  Check,
  ChevronDown,
  Layers,
  Home,
} from 'lucide-react';
import { DimensionUnit, RoomData, AreaDisplayUnit } from '../types';
import { DimensionParser } from '../utils/dimensionParser';
import { ROOM_CATEGORIES, CUSTOM_ROOM_OPTION } from '../data/roomCategories';

interface AddIndividualRoomModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAddRoom: (room: RoomData, keepOpen?: boolean) => void;
  displayUnit: AreaDisplayUnit;
  existingRoomCount: number;
}

interface DimensionPreset {
  label: string;
  name: string;
  feetLen: number;
  inchesLen: number;
  feetWid: number;
  inchesWid: number;
  category: string;
}

const COMMON_ROOM_PRESETS: DimensionPreset[] = [
  { label: 'Living Hall', name: 'Living Room', feetLen: 16, inchesLen: 0, feetWid: 12, inchesWid: 0, category: 'Living & Dining' },
  { label: 'Master Bedroom', name: 'Master Bedroom', feetLen: 14, inchesLen: 0, feetWid: 12, inchesWid: 0, category: 'Bedrooms' },
  { label: 'Standard Bed', name: 'Bedroom 1', feetLen: 11, inchesLen: 0, feetWid: 10, inchesWid: 0, category: 'Bedrooms' },
  { label: 'Modular Kitchen', name: 'Kitchen', feetLen: 10, inchesLen: 0, feetWid: 8, inchesWid: 0, category: 'Kitchen & Utility' },
  { label: 'Bathroom', name: 'Master Bathroom', feetLen: 8, inchesLen: 0, feetWid: 5, inchesWid: 0, category: 'Bathrooms' },
  { label: 'Common Toilet', name: 'Common Bathroom', feetLen: 7, inchesLen: 0, feetWid: 4, inchesWid: 6, category: 'Bathrooms' },
  { label: 'Balcony', name: 'Living Balcony', feetLen: 10, inchesLen: 0, feetWid: 4, inchesWid: 0, category: 'Outdoor & Balcony' },
  { label: 'Utility / Yard', name: 'Utility Area', feetLen: 6, inchesLen: 0, feetWid: 4, inchesWid: 0, category: 'Kitchen & Utility' },
  { label: 'Dining Area', name: 'Dining Room', feetLen: 12, inchesLen: 0, feetWid: 10, inchesWid: 0, category: 'Living & Dining' },
  { label: 'Pooja Room', name: 'Pooja Room / Mandir', feetLen: 5, inchesLen: 0, feetWid: 4, inchesWid: 0, category: 'Other Spaces' },
];

export const AddIndividualRoomModal: React.FC<AddIndividualRoomModalProps> = ({
  isOpen,
  onClose,
  onAddRoom,
  displayUnit,
  existingRoomCount,
}) => {
  if (!isOpen) return null;

  const [name, setName] = useState<string>('Master Bedroom');
  const [isCustomName, setIsCustomName] = useState<boolean>(false);
  const [customNameInput, setCustomNameInput] = useState<string>('');
  const [unit, setUnit] = useState<DimensionUnit>(displayUnit === 'metric' ? 'meterCm' : 'feetInches');

  // Feet & Inches inputs
  const [feetLen, setFeetLen] = useState<string>('14');
  const [inchesLen, setInchesLen] = useState<string>('0');
  const [feetWid, setFeetWid] = useState<string>('12');
  const [inchesWid, setInchesWid] = useState<string>('0');

  // Meter & Cm inputs
  const [meterLen, setMeterLen] = useState<string>('4');
  const [cmLen, setCmLen] = useState<string>('25');
  const [meterWid, setMeterWid] = useState<string>('3');
  const [cmWid, setCmWid] = useState<string>('65');

  // Decimal Feet inputs
  const [decFeetLen, setDecFeetLen] = useState<string>('14.0');
  const [decFeetWid, setDecFeetWid] = useState<string>('12.0');

  // Success toast indicator when adding multiple in sequence
  const [lastAddedName, setLastAddedName] = useState<string | null>(null);

  // Sync unit when displayUnit changes
  React.useEffect(() => {
    if (displayUnit === 'metric') {
      setUnit('meterCm');
    } else if (displayUnit === 'imperial') {
      setUnit('feetInches');
    }
  }, [displayUnit]);

  // Compute live meters and area preview
  let lengthMeters = 0;
  let widthMeters = 0;

  if (unit === 'feetInches') {
    const fl = parseFloat(feetLen) || 0;
    const il = parseFloat(inchesLen) || 0;
    const fw = parseFloat(feetWid) || 0;
    const iw = parseFloat(inchesWid) || 0;
    lengthMeters = DimensionParser.feetInchesToMeters(fl, il);
    widthMeters = DimensionParser.feetInchesToMeters(fw, iw);
  } else if (unit === 'meterCm') {
    const ml = parseFloat(meterLen) || 0;
    const cl = parseFloat(cmLen) || 0;
    const mw = parseFloat(meterWid) || 0;
    const cw = parseFloat(cmWid) || 0;
    lengthMeters = DimensionParser.meterCmToMeters(ml, cl);
    widthMeters = DimensionParser.meterCmToMeters(mw, cw);
  } else {
    const dfl = parseFloat(decFeetLen) || 0;
    const dfw = parseFloat(decFeetWid) || 0;
    lengthMeters = dfl * 0.3048;
    widthMeters = dfw * 0.3048;
  }

  const roomAreaSqM = lengthMeters * widthMeters;
  const roomAreaSqFt = DimensionParser.squareMetersToSquareFeet(roomAreaSqM);

  const applyPreset = (preset: DimensionPreset) => {
    setName(preset.name);
    setIsCustomName(false);
    if (unit === 'feetInches') {
      setFeetLen(String(preset.feetLen));
      setInchesLen(String(preset.inchesLen));
      setFeetWid(String(preset.feetWid));
      setInchesWid(String(preset.inchesWid));
    } else if (unit === 'meterCm') {
      const lenM = DimensionParser.feetInchesToMeters(preset.feetLen, preset.inchesLen);
      const widM = DimensionParser.feetInchesToMeters(preset.feetWid, preset.inchesWid);
      setMeterLen(String(Math.floor(lenM)));
      setCmLen(String(Math.round((lenM - Math.floor(lenM)) * 100)));
      setMeterWid(String(Math.floor(widM)));
      setCmWid(String(Math.round((widM - Math.floor(widM)) * 100)));
    } else {
      const totalFeetLen = preset.feetLen + preset.inchesLen / 12;
      const totalFeetWid = preset.feetWid + preset.inchesWid / 12;
      setDecFeetLen(totalFeetLen.toFixed(2));
      setDecFeetWid(totalFeetWid.toFixed(2));
    }
  };

  const constructRoomData = (): RoomData => {
    const finalName = isCustomName ? customNameInput.trim() || `Room ${existingRoomCount + 1}` : name;
    return {
      id: `room_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
      name: finalName,
      lengthMeters,
      widthMeters,
      unit,
      isAutoExtracted: false,
      isUserVerified: true,
    };
  };

  const handleAddAndClose = () => {
    const newRoom = constructRoomData();
    onAddRoom(newRoom, false);
    onClose();
  };

  const handleAddAndAnother = () => {
    const newRoom = constructRoomData();
    onAddRoom(newRoom, true);
    setLastAddedName(newRoom.name);

    // Prepare next room default
    if (!isCustomName) {
      if (name.includes('Bedroom 1')) setName('Bedroom 2');
      else if (name.includes('Master Bathroom')) setName('Common Bathroom');
      else if (name.includes('Living Room')) setName('Dining Room');
      else if (name.includes('Kitchen')) setName('Utility Area');
      else setName(`Bedroom ${existingRoomCount + 2}`);
    } else {
      setCustomNameInput('');
    }

    setTimeout(() => {
      setLastAddedName(null);
    }, 2500);
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in duration-150"
      role="dialog"
      aria-modal="true"
    >
      <div className="bg-white rounded-3xl max-w-lg w-full overflow-hidden border border-[#CBD5E1] shadow-2xl flex flex-col max-h-[92vh]">
        {/* Header */}
        <div className="p-5 border-b border-[#E2E8F0] flex items-center justify-between bg-gradient-to-r from-blue-50/70 to-slate-50">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-blue-600/10 border border-blue-600/20 flex items-center justify-center text-blue-700 shrink-0">
              <Plus className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-extrabold text-base text-[#0F172A]">
                Add Individual Room
              </h3>
              <p className="text-xs text-[#64748B]">
                Enter room dimensions to aggregate into carpet area
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-2 text-[#64748B] hover:text-[#0F172A] hover:bg-white rounded-xl transition-colors cursor-pointer border border-transparent hover:border-[#E2E8F0]"
            aria-label="Close"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-5 overflow-y-auto space-y-5 flex-1 text-xs">
          {lastAddedName && (
            <div className="p-2.5 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-800 font-bold flex items-center gap-2 animate-in fade-in">
              <Check className="w-4 h-4 text-emerald-600" />
              <span>Added &ldquo;{lastAddedName}&rdquo;! You can now enter the next room.</span>
            </div>
          )}

          {/* Quick Preset Dimension Chips */}
          <div>
            <label className="block text-xs font-bold text-[#475569] mb-2 uppercase tracking-wide flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5 text-blue-600" />
              <span>Quick Architectural Presets</span>
            </label>
            <div className="flex flex-wrap gap-1.5">
              {COMMON_ROOM_PRESETS.map(preset => (
                <button
                  key={preset.label}
                  type="button"
                  onClick={() => applyPreset(preset)}
                  className={`px-2.5 py-1 rounded-lg border text-[11px] font-bold transition-all cursor-pointer ${
                    name === preset.name && !isCustomName
                      ? 'bg-blue-600 text-white border-blue-600 shadow-2xs'
                      : 'bg-[#F8FAFC] text-[#475569] border-[#E2E8F0] hover:bg-[#F1F5F9] hover:border-[#CBD5E1]'
                  }`}
                >
                  {preset.label} ({preset.feetLen}&apos;×{preset.feetWid}&apos;)
                </button>
              ))}
            </div>
          </div>

          {/* Room Name Selection */}
          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-xs font-bold text-[#475569] uppercase tracking-wide">
                Room Designation / Name
              </label>
              <button
                type="button"
                onClick={() => setIsCustomName(!isCustomName)}
                className="text-xs font-semibold text-blue-600 hover:text-blue-800 underline cursor-pointer"
              >
                {isCustomName ? 'Choose from Presets' : '+ Custom Name'}
              </button>
            </div>

            {isCustomName ? (
              <input
                type="text"
                value={customNameInput}
                onChange={e => setCustomNameInput(e.target.value)}
                placeholder="e.g. Guest Bedroom 2, Private Study, Gym"
                className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none"
                autoFocus
              />
            ) : (
              <div className="relative">
                <select
                  value={name}
                  onChange={e => {
                    if (e.target.value === CUSTOM_ROOM_OPTION) {
                      setIsCustomName(true);
                    } else {
                      setName(e.target.value);
                    }
                  }}
                  className="w-full appearance-none font-bold text-[#0F172A] text-sm bg-[#F8FAFC] hover:bg-[#F1F5F9] px-3.5 py-2.5 pr-8 rounded-xl border border-[#CBD5E1] focus:ring-2 focus:ring-blue-500 focus:outline-none cursor-pointer"
                >
                  {Object.entries(ROOM_CATEGORIES).map(([cat, roomList]) => (
                    <optgroup key={cat} label={cat}>
                      {roomList.map(r => (
                        <option key={r} value={r}>
                          {r}
                        </option>
                      ))}
                    </optgroup>
                  ))}
                  <option value={CUSTOM_ROOM_OPTION}>+ Other / Custom Name</option>
                </select>
                <ChevronDown className="w-4 h-4 text-[#64748B] absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            )}
          </div>

          {/* Unit Selector */}
          <div>
            <label className="block text-xs font-bold text-[#475569] mb-1.5 uppercase tracking-wide">
              Dimension Measurement Unit
            </label>
            <div className="grid grid-cols-3 gap-2 bg-[#F1F5F9] p-1 rounded-xl border border-[#E2E8F0]">
              <button
                type="button"
                onClick={() => setUnit('feetInches')}
                className={`py-1.5 rounded-lg font-bold text-xs transition-all cursor-pointer ${
                  unit === 'feetInches'
                    ? 'bg-white text-blue-700 shadow-xs font-extrabold'
                    : 'text-[#64748B] hover:text-[#0F172A]'
                }`}
              >
                Feet & Inches
              </button>
              <button
                type="button"
                onClick={() => setUnit('meterCm')}
                className={`py-1.5 rounded-lg font-bold text-xs transition-all cursor-pointer ${
                  unit === 'meterCm'
                    ? 'bg-white text-blue-700 shadow-xs font-extrabold'
                    : 'text-[#64748B] hover:text-[#0F172A]'
                }`}
              >
                Meters & CM
              </button>
              <button
                type="button"
                onClick={() => setUnit('decimalFeet')}
                className={`py-1.5 rounded-lg font-bold text-xs transition-all cursor-pointer ${
                  unit === 'decimalFeet'
                    ? 'bg-white text-blue-700 shadow-xs font-extrabold'
                    : 'text-[#64748B] hover:text-[#0F172A]'
                }`}
              >
                Decimal Feet
              </button>
            </div>
          </div>

          {/* Dimension Fields */}
          <div className="grid grid-cols-2 gap-3.5">
            {/* Length */}
            <div>
              <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
                Length
              </label>
              {unit === 'feetInches' && (
                <div className="grid grid-cols-2 gap-2">
                  <div className="relative">
                    <input
                      type="number"
                      min="0"
                      value={feetLen}
                      onChange={e => setFeetLen(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-7"
                    />
                    <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                      ft
                    </span>
                  </div>
                  <div className="relative">
                    <input
                      type="number"
                      min="0"
                      max="11.9"
                      value={inchesLen}
                      onChange={e => setInchesLen(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-7"
                    />
                    <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                      in
                    </span>
                  </div>
                </div>
              )}

              {unit === 'meterCm' && (
                <div className="grid grid-cols-2 gap-2">
                  <div className="relative">
                    <input
                      type="number"
                      min="0"
                      value={meterLen}
                      onChange={e => setMeterLen(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-7"
                    />
                    <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                      m
                    </span>
                  </div>
                  <div className="relative">
                    <input
                      type="number"
                      min="0"
                      max="99"
                      value={cmLen}
                      onChange={e => setCmLen(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
                    />
                    <span className="absolute right-2 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                      cm
                    </span>
                  </div>
                </div>
              )}

              {unit === 'decimalFeet' && (
                <div className="relative">
                  <input
                    type="number"
                    min="0"
                    step="0.1"
                    value={decFeetLen}
                    onChange={e => setDecFeetLen(e.target.value)}
                    placeholder="0.0"
                    className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-10"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                    feet
                  </span>
                </div>
              )}
            </div>

            {/* Width */}
            <div>
              <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
                Width
              </label>
              {unit === 'feetInches' && (
                <div className="grid grid-cols-2 gap-2">
                  <div className="relative">
                    <input
                      type="number"
                      min="0"
                      value={feetWid}
                      onChange={e => setFeetWid(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-7"
                    />
                    <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                      ft
                    </span>
                  </div>
                  <div className="relative">
                    <input
                      type="number"
                      min="0"
                      max="11.9"
                      value={inchesWid}
                      onChange={e => setInchesWid(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-7"
                    />
                    <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                      in
                    </span>
                  </div>
                </div>
              )}

              {unit === 'meterCm' && (
                <div className="grid grid-cols-2 gap-2">
                  <div className="relative">
                    <input
                      type="number"
                      min="0"
                      value={meterWid}
                      onChange={e => setMeterWid(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-7"
                    />
                    <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                      m
                    </span>
                  </div>
                  <div className="relative">
                    <input
                      type="number"
                      min="0"
                      max="99"
                      value={cmWid}
                      onChange={e => setCmWid(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
                    />
                    <span className="absolute right-2 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                      cm
                    </span>
                  </div>
                </div>
              )}

              {unit === 'decimalFeet' && (
                <div className="relative">
                  <input
                    type="number"
                    min="0"
                    step="0.1"
                    value={decFeetWid}
                    onChange={e => setDecFeetWid(e.target.value)}
                    placeholder="0.0"
                    className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-10"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                    feet
                  </span>
                </div>
              )}
            </div>
          </div>

          {/* Live Computed Area Preview */}
          <div className="p-3.5 bg-gradient-to-r from-blue-50 to-indigo-50/50 rounded-2xl border border-blue-200 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Ruler className="w-4 h-4 text-blue-700 shrink-0" />
              <div>
                <span className="text-[11px] font-bold text-blue-900 block">
                  Individual Room Floor Area:
                </span>
                <span className="text-[10px] text-blue-700">
                  {DimensionParser.formatLength(lengthMeters, displayUnit)} ×{' '}
                  {DimensionParser.formatLength(widthMeters, displayUnit)}
                </span>
              </div>
            </div>

            <div className="text-right">
              <span className="text-sm font-black text-blue-950 block">
                {DimensionParser.format(roomAreaSqFt, 1)} sq ft
              </span>
              <span className="text-[11px] font-bold text-blue-700">
                {DimensionParser.format(roomAreaSqM, 2)} sq m
              </span>
            </div>
          </div>
        </div>

        {/* Footer with Dual Actions */}
        <div className="p-4 border-t border-[#E2E8F0] bg-[#F8FAFC] flex flex-col sm:flex-row items-center justify-between gap-2.5">
          <button
            type="button"
            onClick={onClose}
            className="w-full sm:w-auto px-4 py-2 text-xs font-bold text-[#64748B] hover:text-[#0F172A] hover:bg-white border border-[#E2E8F0] rounded-xl transition-colors cursor-pointer text-center"
          >
            Cancel
          </button>

          <div className="w-full sm:w-auto flex items-center gap-2">
            <button
              type="button"
              onClick={handleAddAndAnother}
              className="flex-1 sm:flex-initial px-4 py-2 text-xs font-bold text-blue-700 bg-blue-50 hover:bg-blue-100 border border-blue-200 rounded-xl transition-colors cursor-pointer flex items-center justify-center gap-1.5"
              title="Add this room and immediately enter another"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Add & Add Another</span>
            </button>

            <button
              type="button"
              onClick={handleAddAndClose}
              className="flex-1 sm:flex-initial px-5 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-xs transition-colors cursor-pointer flex items-center justify-center gap-1.5"
            >
              <Check className="w-3.5 h-3.5" />
              <span>Add Room</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
