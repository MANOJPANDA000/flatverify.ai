import React, { useState, useEffect } from 'react';
import { Trash2, ChevronDown, Check, Ruler, Copy, ArrowUp, ArrowDown, Building2, HelpCircle } from 'lucide-react';
import { DimensionUnit, RoomData, AreaDisplayUnit, RoomSpaceType, inferRoomSpaceType } from '../types';
import { DimensionParser } from '../utils/dimensionParser';
import { ROOM_CATEGORIES, CUSTOM_ROOM_OPTION } from '../data/roomCategories';

interface RoomCardProps {
  room: RoomData;
  index: number;
  displayUnit: AreaDisplayUnit;
  onUpdate: (updated: RoomData) => void;
  onRemove: () => void;
  onDuplicate?: () => void;
  onMoveUp?: () => void;
  onMoveDown?: () => void;
  canMoveUp?: boolean;
  canMoveDown?: boolean;
  totalAggregateCarpetSqFt?: number;
}

export const RoomCard: React.FC<RoomCardProps> = ({
  room,
  index,
  displayUnit,
  onUpdate,
  onRemove,
  onDuplicate,
  onMoveUp,
  onMoveDown,
  canMoveUp = false,
  canMoveDown = false,
  totalAggregateCarpetSqFt = 0,
}) => {
  const [isCustomName, setIsCustomName] = useState(() => {
    const allPredefined = Object.values(ROOM_CATEGORIES).flat();
    return !allPredefined.includes(room.name);
  });

  // Calculate formatted values from meters
  const getFeetInches = (meters: number) => {
    if (!meters || meters <= 0) return { feet: '', inches: '' };
    const totalInches = Math.round(DimensionParser.metersToInches(meters));
    return {
      feet: String(Math.floor(totalInches / 12)),
      inches: String(totalInches % 12),
    };
  };

  const getMeterCm = (meters: number) => {
    if (!meters || meters <= 0) return { m: '', cm: '' };
    const totalCm = Math.round(meters * 100);
    return {
      m: String(Math.floor(totalCm / 100)),
      cm: String(totalCm % 100),
    };
  };

  const getDecFeet = (meters: number) => {
    if (!meters || meters <= 0) return '';
    return (DimensionParser.metersToFeet(meters)).toFixed(2);
  };

  // Local state for inputs
  const initLenFI = getFeetInches(room.lengthMeters);
  const initWidFI = getFeetInches(room.widthMeters);
  const initLenMC = getMeterCm(room.lengthMeters);
  const initWidMC = getMeterCm(room.widthMeters);

  const [feetLen, setFeetLen] = useState<string | number>(initLenFI.feet);
  const [inchesLen, setInchesLen] = useState<string | number>(initLenFI.inches);
  const [feetWid, setFeetWid] = useState<string | number>(initWidFI.feet);
  const [inchesWid, setInchesWid] = useState<string | number>(initWidFI.inches);

  const [meterLen, setMeterLen] = useState<string | number>(initLenMC.m);
  const [cmLen, setCmLen] = useState<string | number>(initLenMC.cm);
  const [meterWid, setMeterWid] = useState<string | number>(initWidMC.m);
  const [cmWid, setCmWid] = useState<string | number>(initWidMC.cm);

  const [decFeetLen, setDecFeetLen] = useState<string>(getDecFeet(room.lengthMeters));
  const [decFeetWid, setDecFeetWid] = useState<string>(getDecFeet(room.widthMeters));

  // Sync inputs whenever room.lengthMeters or room.widthMeters changes from parent or presets
  useEffect(() => {
    const lenFI = getFeetInches(room.lengthMeters);
    const widFI = getFeetInches(room.widthMeters);
    const lenMC = getMeterCm(room.lengthMeters);
    const widMC = getMeterCm(room.widthMeters);

    setFeetLen(lenFI.feet);
    setInchesLen(lenFI.inches);
    setFeetWid(widFI.feet);
    setInchesWid(widFI.inches);

    setMeterLen(lenMC.m);
    setCmLen(lenMC.cm);
    setMeterWid(widMC.m);
    setCmWid(widMC.cm);

    setDecFeetLen(getDecFeet(room.lengthMeters));
    setDecFeetWid(getDecFeet(room.widthMeters));
  }, [room.lengthMeters, room.widthMeters]);

  // Synchronize room input unit mode with global displayUnit when displayUnit changes
  useEffect(() => {
    if (displayUnit === 'metric' && room.unit !== 'meterCm') {
      onUpdate({ ...room, unit: 'meterCm' });
    } else if (displayUnit === 'imperial' && room.unit === 'meterCm') {
      onUpdate({ ...room, unit: 'feetInches' });
    }
  }, [displayUnit]);

  // Handle unit tab toggle on card
  const handleUnitChange = (newUnit: DimensionUnit) => {
    onUpdate({
      ...room,
      unit: newUnit,
    });
  };

  // Direct dimension update handlers
  const handleLengthFeetInchesChange = (f: string, i: string) => {
    setFeetLen(f);
    setInchesLen(i);
    const fl = parseFloat(f) || 0;
    const il = parseFloat(i) || 0;
    const newLenMeters = DimensionParser.feetInchesToMeters(fl, il);
    onUpdate({
      ...room,
      lengthMeters: newLenMeters,
      isUserVerified: true,
    });
  };

  const handleWidthFeetInchesChange = (f: string, i: string) => {
    setFeetWid(f);
    setInchesWid(i);
    const fw = parseFloat(f) || 0;
    const iw = parseFloat(i) || 0;
    const newWidMeters = DimensionParser.feetInchesToMeters(fw, iw);
    onUpdate({
      ...room,
      widthMeters: newWidMeters,
      isUserVerified: true,
    });
  };

  const handleLengthMeterCmChange = (m: string, c: string) => {
    setMeterLen(m);
    setCmLen(c);
    const ml = parseFloat(m) || 0;
    const cl = parseFloat(c) || 0;
    const newLenMeters = DimensionParser.meterCmToMeters(ml, cl);
    onUpdate({
      ...room,
      lengthMeters: newLenMeters,
      isUserVerified: true,
    });
  };

  const handleWidthMeterCmChange = (m: string, c: string) => {
    setMeterWid(m);
    setCmWid(c);
    const mw = parseFloat(m) || 0;
    const cw = parseFloat(c) || 0;
    const newWidMeters = DimensionParser.meterCmToMeters(mw, cw);
    onUpdate({
      ...room,
      widthMeters: newWidMeters,
      isUserVerified: true,
    });
  };

  const handleLengthDecFeetChange = (val: string) => {
    setDecFeetLen(val);
    const dfl = parseFloat(val) || 0;
    const newLenMeters = dfl * 0.3048;
    onUpdate({
      ...room,
      lengthMeters: newLenMeters,
      isUserVerified: true,
    });
  };

  const handleWidthDecFeetChange = (val: string) => {
    setDecFeetWid(val);
    const dfw = parseFloat(val) || 0;
    const newWidMeters = dfw * 0.3048;
    onUpdate({
      ...room,
      widthMeters: newWidMeters,
      isUserVerified: true,
    });
  };

  const roomSqFt = DimensionParser.squareMetersToSquareFeet(room.lengthMeters * room.widthMeters);

  return (
    <div className="bg-white rounded-2xl p-5 border border-[#E2E8F0] shadow-xs hover:border-[#CBD5E1] transition-all duration-200">
      {/* Top Header Row */}
      <div className="flex items-center justify-between gap-3 pb-3.5 border-b border-[#F1F5F9]">
        <div className="flex items-center gap-2.5 flex-1 min-w-0">
          <span className="flex items-center justify-center w-6 h-6 rounded-full bg-[#F1F5F9] text-[#475569] font-black text-[12px] shrink-0">
            {index + 1}
          </span>

          {isCustomName ? (
            <div className="flex items-center gap-2 flex-1 max-w-xs">
              <input
                type="text"
                value={room.name}
                onChange={e => onUpdate({ ...room, name: e.target.value })}
                placeholder="Enter custom room name"
                className="w-full font-bold text-[#0F172A] text-sm px-2.5 py-1 rounded-lg border border-[#CBD5E1] focus:ring-2 focus:ring-blue-500 focus:outline-none"
              />
              <button
                type="button"
                onClick={() => setIsCustomName(false)}
                className="text-xs text-blue-600 hover:text-blue-800 shrink-0 font-medium underline"
              >
                Presets
              </button>
            </div>
          ) : (
            <div className="relative flex-1 max-w-xs">
              <select
                value={room.name}
                onChange={e => {
                  if (e.target.value === CUSTOM_ROOM_OPTION) {
                    setIsCustomName(true);
                  } else {
                    const newName = e.target.value;
                    onUpdate({ ...room, name: newName, spaceType: inferRoomSpaceType(newName) });
                  }
                }}
                className="w-full appearance-none font-bold text-[#0F172A] text-sm bg-[#F8FAFC] hover:bg-[#F1F5F9] px-3 py-1.5 pr-8 rounded-lg border border-[#E2E8F0] focus:ring-2 focus:ring-blue-500 focus:outline-none cursor-pointer"
              >
                {Object.entries(ROOM_CATEGORIES).map(([cat, rooms]) => (
                  <optgroup key={cat} label={cat}>
                    {rooms.map(r => (
                      <option key={r} value={r}>
                        {r}
                      </option>
                    ))}
                  </optgroup>
                ))}
                <option value={CUSTOM_ROOM_OPTION}>+ Other / Custom Name</option>
              </select>
              <ChevronDown className="w-4 h-4 text-[#64748B] absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            </div>
          )}
        </div>

        {/* Dimension Unit Toggle for this Room */}
        <div className="flex items-center gap-2">
          <div className="hidden sm:flex bg-[#F1F5F9] p-0.5 rounded-lg text-xs font-semibold">
            <button
              type="button"
              onClick={() => handleUnitChange('feetInches')}
              className={`px-2 py-1 rounded-md transition-all ${
                room.unit === 'feetInches'
                  ? 'bg-white text-blue-700 shadow-xs font-bold'
                  : 'text-[#64748B] hover:text-[#0F172A]'
              }`}
            >
              Ft & In
            </button>
            <button
              type="button"
              onClick={() => handleUnitChange('meterCm')}
              className={`px-2 py-1 rounded-md transition-all ${
                room.unit === 'meterCm'
                  ? 'bg-white text-blue-700 shadow-xs font-bold'
                  : 'text-[#64748B] hover:text-[#0F172A]'
              }`}
            >
              M & Cm
            </button>
            <button
              type="button"
              onClick={() => handleUnitChange('decimalFeet')}
              className={`px-2 py-1 rounded-md transition-all ${
                room.unit === 'decimalFeet'
                  ? 'bg-white text-blue-700 shadow-xs font-bold'
                  : 'text-[#64748B] hover:text-[#0F172A]'
              }`}
            >
              Dec Ft
            </button>
          </div>

          {onMoveUp && (
            <button
              type="button"
              onClick={onMoveUp}
              disabled={!canMoveUp}
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                canMoveUp
                  ? 'text-[#64748B] hover:text-[#0F172A] hover:bg-[#F1F5F9]'
                  : 'text-[#CBD5E1] cursor-not-allowed opacity-40'
              }`}
              title="Move room up"
            >
              <ArrowUp className="w-3.5 h-3.5" />
            </button>
          )}

          {onMoveDown && (
            <button
              type="button"
              onClick={onMoveDown}
              disabled={!canMoveDown}
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                canMoveDown
                  ? 'text-[#64748B] hover:text-[#0F172A] hover:bg-[#F1F5F9]'
                  : 'text-[#CBD5E1] cursor-not-allowed opacity-40'
              }`}
              title="Move room down"
            >
              <ArrowDown className="w-3.5 h-3.5" />
            </button>
          )}

          {onDuplicate && (
            <button
              type="button"
              onClick={onDuplicate}
              className="p-1.5 text-[#64748B] hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors cursor-pointer"
              title="Duplicate this room"
            >
              <Copy className="w-3.5 h-3.5" />
            </button>
          )}

          <button
            type="button"
            onClick={onRemove}
            className="p-1.5 text-[#94A3B8] hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors cursor-pointer"
            title="Delete room"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* RERA Space Classification & Outer Wall Placement Inspector */}
      {(() => {
        const effectiveSpaceType = room.spaceType || inferRoomSpaceType(room.name);
        const nameLower = room.name.toLowerCase();
        const isUtility =
          nameLower.includes('utility') ||
          nameLower.includes('dry balcony') ||
          nameLower.includes('wash') ||
          nameLower.includes('yard');
        const isBalcony =
          !isUtility &&
          (nameLower.includes('balcony') ||
            nameLower.includes('balc') ||
            nameLower.includes('verandah') ||
            nameLower.includes('veranda') ||
            nameLower.includes('sitout') ||
            nameLower.includes('deck') ||
            nameLower.includes('terrace'));

        if (isUtility) {
          return (
            <div className="mt-3 p-2.5 bg-blue-50/80 border border-blue-200 rounded-xl text-xs">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div>
                  <div className="flex items-center gap-1.5 font-bold text-blue-950">
                    <Building2 className="w-3.5 h-3.5 text-blue-700" />
                    <span>Utility Space Location:</span>
                  </div>
                  <p className="text-[11px] text-blue-800 mt-0.5">
                    {effectiveSpaceType === 'utility_inside' ? (
                      <span className="font-semibold text-emerald-800">
                        ✓ Inside Outer Wall → Counted under <strong>RERA Carpet Area</strong> & Built-up
                      </span>
                    ) : (
                      <span className="font-semibold text-amber-800">
                        ✓ Outside Outer Wall (Dry Balcony) → Excluded from Carpet, in <strong>Built-up Area only</strong>
                      </span>
                    )}
                  </p>
                </div>

                <div className="flex items-center gap-1 bg-white p-1 rounded-lg border border-blue-200 shadow-2xs shrink-0">
                  <button
                    type="button"
                    onClick={() => onUpdate({ ...room, spaceType: 'utility_inside' })}
                    className={`px-2.5 py-1 rounded-md text-[11px] font-bold transition-all cursor-pointer ${
                      effectiveSpaceType === 'utility_inside'
                        ? 'bg-blue-600 text-white shadow-xs'
                        : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                    }`}
                    title="Enclosed within external perimeter wall: Counted in RERA Carpet Area!"
                  >
                    Inside Outer Wall (Carpet)
                  </button>
                  <button
                    type="button"
                    onClick={() => onUpdate({ ...room, spaceType: 'utility_outside' })}
                    className={`px-2.5 py-1 rounded-md text-[11px] font-bold transition-all cursor-pointer ${
                      effectiveSpaceType === 'utility_outside'
                        ? 'bg-amber-600 text-white shadow-xs'
                        : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                    }`}
                    title="Cantilevered / outside perimeter wall: Excluded from Carpet, added to Built-up."
                  >
                    Outside Outer Wall (Built-up)
                  </button>
                </div>
              </div>
            </div>
          );
        }

        if (isBalcony) {
          return (
            <div className="mt-3 px-3 py-2 bg-amber-50/80 border border-amber-200 rounded-xl text-xs flex items-center justify-between gap-2">
              <div className="flex items-center gap-2 text-amber-950 font-medium text-[11px]">
                <span className="w-2 h-2 rounded-full bg-amber-500 shrink-0" />
                <span>
                  <strong>Balcony / Verandah:</strong> Excluded from statutory RERA Carpet Area; Included in <strong>Built-up Area</strong>.
                </span>
              </div>
              <span className="px-2 py-0.5 text-[10px] font-extrabold bg-amber-100 text-amber-900 border border-amber-300 rounded shrink-0">
                Built-up Only
              </span>
            </div>
          );
        }

        return (
          <div className="mt-2.5 px-2 py-1 bg-slate-50 border border-slate-200/80 rounded-lg flex items-center justify-between text-[11px] text-[#64748B]">
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-500 shrink-0" />
              <span>
                <strong>Enclosed Interior Room:</strong> Net usable floor inside outer wall (Counted in <strong>RERA Carpet Area</strong> & <strong>Built-up Area</strong>).
              </span>
            </div>
            <span className="px-1.5 py-0.5 text-[10px] font-bold bg-emerald-50 text-emerald-800 border border-emerald-200 rounded">
              RERA Carpet
            </span>
          </div>
        );
      })()}

      {/* Input Dimensions Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4">
        {/* Length Input */}
        <div>
          <label className="block text-xs font-bold text-[#475569] mb-1.5 uppercase tracking-wide">
            Length
          </label>
          {room.unit === 'feetInches' && (
            <div className="grid grid-cols-2 gap-2">
              <div className="relative">
                <input
                  type="number"
                  min="0"
                  step="1"
                  value={feetLen}
                  onChange={e => handleLengthFeetInchesChange(e.target.value, String(inchesLen))}
                  placeholder="0"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
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
                  step="1"
                  value={inchesLen}
                  onChange={e => handleLengthFeetInchesChange(String(feetLen), e.target.value)}
                  placeholder="0"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
                />
                <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                  in
                </span>
              </div>
            </div>
          )}

          {room.unit === 'meterCm' && (
            <div className="grid grid-cols-2 gap-2">
              <div className="relative">
                <input
                  type="number"
                  min="0"
                  step="1"
                  value={meterLen}
                  onChange={e => handleLengthMeterCmChange(e.target.value, String(cmLen))}
                  placeholder="0"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
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
                  step="1"
                  value={cmLen}
                  onChange={e => handleLengthMeterCmChange(String(meterLen), e.target.value)}
                  placeholder="0"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
                />
                <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                  cm
                </span>
              </div>
            </div>
          )}

          {room.unit === 'decimalFeet' && (
            <div className="relative">
              <input
                type="number"
                min="0"
                step="0.1"
                value={decFeetLen}
                onChange={e => handleLengthDecFeetChange(e.target.value)}
                placeholder="0.0"
                className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-10"
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                feet
              </span>
            </div>
          )}
        </div>

        {/* Width Input */}
        <div>
          <label className="block text-xs font-bold text-[#475569] mb-1.5 uppercase tracking-wide">
            Width
          </label>
          {room.unit === 'feetInches' && (
            <div className="grid grid-cols-2 gap-2">
              <div className="relative">
                <input
                  type="number"
                  min="0"
                  step="1"
                  value={feetWid}
                  onChange={e => handleWidthFeetInchesChange(e.target.value, String(inchesWid))}
                  placeholder="0"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
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
                  step="1"
                  value={inchesWid}
                  onChange={e => handleWidthFeetInchesChange(String(feetWid), e.target.value)}
                  placeholder="0"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
                />
                <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                  in
                </span>
              </div>
            </div>
          )}

          {room.unit === 'meterCm' && (
            <div className="grid grid-cols-2 gap-2">
              <div className="relative">
                <input
                  type="number"
                  min="0"
                  step="1"
                  value={meterWid}
                  onChange={e => handleWidthMeterCmChange(e.target.value, String(cmWid))}
                  placeholder="0"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
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
                  step="1"
                  value={cmWid}
                  onChange={e => handleWidthMeterCmChange(String(meterWid), e.target.value)}
                  placeholder="0"
                  className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:bg-white focus:ring-2 focus:ring-blue-500 focus:outline-none pr-8"
                />
                <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-xs font-bold text-[#94A3B8]">
                  cm
                </span>
              </div>
            </div>
          )}

          {room.unit === 'decimalFeet' && (
            <div className="relative">
              <input
                type="number"
                min="0"
                step="0.1"
                value={decFeetWid}
                onChange={e => handleWidthDecFeetChange(e.target.value)}
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

      {/* Card Footer: Computed Area & Verification Status */}
      <div className="flex flex-wrap items-center justify-between gap-2 pt-3 mt-3 border-t border-[#F8FAFC] text-xs">
        <div className="flex items-center gap-2 text-[#64748B]">
          <Ruler className="w-3.5 h-3.5 text-blue-600" />
          <span>
            {DimensionParser.formatLength(room.lengthMeters, displayUnit)} ×{' '}
            {DimensionParser.formatLength(room.widthMeters, displayUnit)}
          </span>
        </div>

        <div className="flex items-center gap-2">
          {totalAggregateCarpetSqFt > 0 && (
            <span
              className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-blue-50 text-blue-700 border border-blue-100"
              title={`${((roomSqFt / totalAggregateCarpetSqFt) * 100).toFixed(1)}% of total aggregate carpet area`}
            >
              {((roomSqFt / totalAggregateCarpetSqFt) * 100).toFixed(1)}% of total
            </span>
          )}

          <div className="flex items-center gap-1.5">
            <span className="text-[#64748B]">Area:</span>
            <span className="font-extrabold text-[#1E293B] text-sm">
              {DimensionParser.formatArea(roomSqFt, displayUnit)}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
