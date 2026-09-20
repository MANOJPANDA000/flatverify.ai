import React, { useState } from 'react';
import { CheckCircle2, AlertCircle, Edit2, Trash2, Check, X, Building2 } from 'lucide-react';
import { AreaDisplayUnit, RoomData, inferRoomSpaceType } from '../types';
import { DimensionParser } from '../utils/dimensionParser';

interface ScanRoomCardProps {
  room: RoomData;
  displayUnit: AreaDisplayUnit;
  onUpdate: (updated: RoomData) => void;
  onRemove: () => void;
}

export const ScanRoomCard: React.FC<ScanRoomCardProps> = ({
  room,
  displayUnit,
  onUpdate,
  onRemove,
}) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editName, setEditName] = useState(room.name);
  const [editLengthStr, setEditLengthStr] = useState(
    DimensionParser.formatFeetInches(room.lengthMeters)
  );
  const [editWidthStr, setEditWidthStr] = useState(
    DimensionParser.formatFeetInches(room.widthMeters)
  );

  const roomSqFt = DimensionParser.squareMetersToSquareFeet(room.lengthMeters * room.widthMeters);
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

  const handleSaveEdit = () => {
    const newLenMeters = DimensionParser.parseDimensionToMeters(editLengthStr);
    const newWidMeters = DimensionParser.parseDimensionToMeters(editWidthStr);
    const trimmedName = editName.trim() || room.name;

    onUpdate({
      ...room,
      name: trimmedName,
      spaceType: room.spaceType || inferRoomSpaceType(trimmedName),
      lengthMeters: newLenMeters > 0 ? newLenMeters : room.lengthMeters,
      widthMeters: newWidMeters > 0 ? newWidMeters : room.widthMeters,
      isUserVerified: true,
    });
    setIsEditing(false);
  };

  const toggleVerified = () => {
    onUpdate({
      ...room,
      isUserVerified: !room.isUserVerified,
    });
  };

  return (
    <div
      className={`rounded-2xl p-4 border transition-all duration-150 ${
        room.isUserVerified
          ? 'bg-white border-[#E2E8F0] shadow-xs'
          : 'bg-[#FFFDF7] border-[#FDE68A]'
      }`}
    >
      {isEditing ? (
        <div className="space-y-3">
          <div>
            <label className="block text-xs font-bold text-[#475569] mb-1">
              Room / Space Name
            </label>
            <input
              type="text"
              value={editName}
              onChange={e => setEditName(e.target.value)}
              className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-lg px-2.5 py-1.5 text-sm font-bold text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-[#475569] mb-1">
                Length (e.g. 12' 6" or 3.8m)
              </label>
              <input
                type="text"
                value={editLengthStr}
                onChange={e => setEditLengthStr(e.target.value)}
                className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-lg px-2.5 py-1.5 text-sm font-bold text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#475569] mb-1">
                Width (e.g. 10' 0" or 3.0m)
              </label>
              <input
                type="text"
                value={editWidthStr}
                onChange={e => setEditWidthStr(e.target.value)}
                className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-lg px-2.5 py-1.5 text-sm font-bold text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => setIsEditing(false)}
              className="px-3 py-1.5 text-xs font-semibold text-[#64748B] hover:text-[#0F172A] rounded-lg"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleSaveEdit}
              className="px-3.5 py-1.5 text-xs font-bold bg-blue-600 text-white hover:bg-blue-700 rounded-lg flex items-center gap-1.5"
            >
              <Check className="w-3.5 h-3.5" />
              Save Changes
            </button>
          </div>
        </div>
      ) : (
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3 min-w-0">
            <button
              type="button"
              onClick={toggleVerified}
              title={room.isUserVerified ? 'Click to mark unverified' : 'Click to verify dimension'}
              className="shrink-0 cursor-pointer"
            >
              {room.isUserVerified ? (
                <CheckCircle2 className="w-5 h-5 text-emerald-600" />
              ) : (
                <AlertCircle className="w-5 h-5 text-amber-500" />
              )}
            </button>

            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <h4 className="font-bold text-sm text-[#0F172A] truncate">
                  {room.name}
                </h4>
                {room.isUserVerified ? (
                  <span className="text-[10px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200">
                    Verified
                  </span>
                ) : (
                  <span className="text-[10px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 border border-amber-200">
                    Estimate
                  </span>
                )}
              </div>

              <div className="text-xs text-[#64748B] mt-0.5 font-medium">
                {DimensionParser.formatLength(room.lengthMeters, displayUnit)} ×{' '}
                {DimensionParser.formatLength(room.widthMeters, displayUnit)}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3 shrink-0">
            <div className="text-right">
              <div className="font-black text-sm text-[#0F172A]">
                {DimensionParser.formatArea(roomSqFt, displayUnit)}
              </div>
            </div>

            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => setIsEditing(true)}
                className="p-1.5 text-[#64748B] hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                title="Edit dimensions"
              >
                <Edit2 className="w-3.5 h-3.5" />
              </button>
              <button
                type="button"
                onClick={onRemove}
                className="p-1.5 text-[#94A3B8] hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                title="Remove room"
              >
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* RERA Space Classification & Outer Wall Placement */}
      <div className="mt-2.5 pt-2 border-t border-slate-100">
        {isUtility ? (
          <div className="p-2 bg-blue-50/80 border border-blue-200 rounded-xl text-xs">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1.5">
              <div>
                <div className="flex items-center gap-1.5 font-bold text-blue-950 text-[11px]">
                  <Building2 className="w-3 h-3 text-blue-700" />
                  <span>Utility Location:</span>
                </div>
                <p className="text-[10px] text-blue-850">
                  {effectiveSpaceType === 'utility_inside' ? (
                    <span className="font-semibold text-emerald-800">
                      ✓ Inside Outer Wall → Counted under <strong>RERA Carpet Area</strong> & Built-up
                    </span>
                  ) : (
                    <span className="font-semibold text-amber-850">
                      ✓ Outside Outer Wall (Dry Balcony) → Excluded from Carpet, in <strong>Built-up Area only</strong>
                    </span>
                  )}
                </p>
              </div>

              <div className="flex items-center gap-1 bg-white p-0.5 rounded-lg border border-blue-200 shrink-0">
                <button
                  type="button"
                  onClick={() => onUpdate({ ...room, spaceType: 'utility_inside' })}
                  className={`px-2 py-0.5 rounded text-[10px] font-bold transition-all cursor-pointer ${
                    effectiveSpaceType === 'utility_inside'
                      ? 'bg-blue-600 text-white shadow-2xs'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                  title="Inside outer wall: Enclosed within flat boundary. Counted in RERA Carpet Area!"
                >
                  Inside (Carpet)
                </button>
                <button
                  type="button"
                  onClick={() => onUpdate({ ...room, spaceType: 'utility_outside' })}
                  className={`px-2 py-0.5 rounded text-[10px] font-bold transition-all cursor-pointer ${
                    effectiveSpaceType === 'utility_outside'
                      ? 'bg-amber-600 text-white shadow-2xs'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                  title="Outside outer wall: Cantilevered / service balcony. Excluded from Carpet, added to Built-up."
                >
                  Outside (Built-up)
                </button>
              </div>
            </div>
          </div>
        ) : isBalcony ? (
          <div className="px-2 py-1 bg-amber-50 border border-amber-200/80 rounded-lg flex items-center justify-between text-[11px]">
            <span className="text-amber-950 font-medium text-[10px]">
              Balcony / Outdoor Space: Excluded from RERA Carpet; Included in <strong>Built-up (Plinth) Area</strong>.
            </span>
            <span className="px-1.5 py-0.2 text-[9px] font-extrabold bg-amber-100 text-amber-900 border border-amber-300 rounded">
              Built-up Only
            </span>
          </div>
        ) : (
          <div className="flex items-center justify-between text-[10px] text-[#64748B]">
            <span className="flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
              <span>Enclosed Interior Space (Inside Outer Wall → <strong>RERA Carpet & Built-up</strong>)</span>
            </span>
            <span className="text-[9px] font-bold text-emerald-700 bg-emerald-50 px-1 py-0.2 rounded border border-emerald-200">
              RERA Carpet
            </span>
          </div>
        )}
      </div>
    </div>
  );
};
