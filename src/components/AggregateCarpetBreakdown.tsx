import React, { useState } from 'react';
import {
  Layers,
  PieChart,
  Ruler,
  Building2,
  Scale,
  Maximize2,
  ChevronDown,
  ChevronUp,
  Percent,
  CheckCircle2,
  Sparkles,
} from 'lucide-react';
import { RoomData, AreaDisplayUnit, ReraPropertyType, inferRoomSpaceType } from '../types';
import { DimensionParser } from '../utils/dimensionParser';

export interface AggregateCarpetBreakdownProps {
  rooms: RoomData[];
  usableAreaSqFt: number;
  carpetAreaSqFt: number;
  internalWallPercent: number;
  internalWallAreaSqFt: number;
  builtUpAreaSqFt: number;
  externalWallPercent: number;
  externalWallAreaSqFt: number;
  loadingPercent: number;
  loadingAreaSqFt: number;
  superBuiltUpAreaSqFt: number;
  displayUnit: AreaDisplayUnit;
  propertyType?: ReraPropertyType;
  className?: string;
}

// Visual color palette for room distribution segments
const ROOM_PALETTE = [
  'bg-blue-500 text-white',
  'bg-emerald-500 text-white',
  'bg-amber-500 text-white',
  'bg-purple-500 text-white',
  'bg-rose-500 text-white',
  'bg-indigo-500 text-white',
  'bg-teal-500 text-white',
  'bg-cyan-500 text-white',
  'bg-orange-500 text-white',
  'bg-pink-500 text-white',
];

const ROOM_BORDER_COLORS = [
  '#3B82F6',
  '#10B981',
  '#F59E0B',
  '#A855F7',
  '#F43F5E',
  '#6366F1',
  '#14B8A6',
  '#06B6D4',
  '#F97316',
  '#EC4899',
];

export const AggregateCarpetBreakdown: React.FC<AggregateCarpetBreakdownProps> = ({
  rooms,
  usableAreaSqFt,
  carpetAreaSqFt,
  internalWallPercent,
  internalWallAreaSqFt,
  builtUpAreaSqFt,
  externalWallPercent,
  externalWallAreaSqFt,
  loadingPercent,
  loadingAreaSqFt,
  superBuiltUpAreaSqFt,
  displayUnit,
  propertyType = 'apartment',
  className = '',
}) => {
  const [isDetailsExpanded, setIsDetailsExpanded] = useState(true);
  const [selectedRoomIndex, setSelectedRoomIndex] = useState<number | null>(null);

  // Compute individual room areas and percentages
  const roomContributions = rooms.map((room, idx) => {
    const areaSqM = room.lengthMeters * room.widthMeters;
    const areaSqFt = DimensionParser.squareMetersToSquareFeet(areaSqM);
    const percentage = usableAreaSqFt > 0 ? (areaSqFt / usableAreaSqFt) * 100 : 0;
    return {
      room,
      index: idx,
      areaSqFt,
      areaSqM,
      percentage,
      colorClass: ROOM_PALETTE[idx % ROOM_PALETTE.length],
      borderColor: ROOM_BORDER_COLORS[idx % ROOM_BORDER_COLORS.length],
    };
  });

  // Calculate aggregates and metrics
  const totalRooms = rooms.length;
  const avgRoomSqFt = totalRooms > 0 ? usableAreaSqFt / totalRooms : 0;
  const avgRoomSqM = DimensionParser.squareFeetToSquareMeters(avgRoomSqFt);

  // Largest and Smallest rooms
  let largestRoom = roomContributions[0];
  let smallestRoom = roomContributions[0];

  roomContributions.forEach(item => {
    if (!largestRoom || item.areaSqFt > largestRoom.areaSqFt) largestRoom = item;
    if (!smallestRoom || item.areaSqFt < smallestRoom.areaSqFt) smallestRoom = item;
  });

  const usableAreaSqM = DimensionParser.squareFeetToSquareMeters(usableAreaSqFt);
  const carpetAreaSqM = DimensionParser.squareFeetToSquareMeters(carpetAreaSqFt);
  const internalWallAreaSqM = DimensionParser.squareFeetToSquareMeters(internalWallAreaSqFt);
  const builtUpAreaSqM = DimensionParser.squareFeetToSquareMeters(builtUpAreaSqFt);
  const superSqM = DimensionParser.squareFeetToSquareMeters(superBuiltUpAreaSqFt);

  return (
    <div
      id="aggregate-carpet-breakdown"
      className={`bg-white rounded-3xl border border-[#CBD5E1] shadow-xs overflow-hidden ${className}`}
    >
      {/* Header Banner */}
      <div className="p-5 bg-gradient-to-r from-[#0F172A] to-[#1E293B] text-white flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-blue-500/20 border border-blue-400/30 flex items-center justify-center text-blue-400 shrink-0">
            <Layers className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-extrabold text-base tracking-tight">
                Total Aggregate Carpet Area
              </h3>
              <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-blue-500/20 text-blue-300 border border-blue-400/30">
                {totalRooms} {totalRooms === 1 ? 'Room' : 'Rooms'} Aggregated
              </span>
            </div>
            <p className="text-xs text-slate-300">
              Sum of all individual enclosed room floor plates under RERA Sec 2(k)
            </p>
          </div>
        </div>

        {/* Hero Aggregate Number */}
        <div className="text-left sm:text-right bg-white/10 sm:bg-transparent p-3 sm:p-0 rounded-xl border border-white/10 sm:border-none">
          <div className="text-2xl font-black tracking-tight text-white">
            {DimensionParser.formatArea(carpetAreaSqFt, displayUnit)}
          </div>
          <div className="text-xs font-semibold text-blue-300">
            {displayUnit === 'imperial' && (
              <span>= {DimensionParser.format(carpetAreaSqM, 2)} sq meters</span>
            )}
            {displayUnit === 'metric' && (
              <span>= {DimensionParser.format(carpetAreaSqFt, 1)} sq feet</span>
            )}
            {displayUnit === 'hybrid' && <span>Official Statutory Net Usable Floor Area</span>}
          </div>
        </div>
      </div>

      {/* Aggregate Quick Metrics Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-px bg-[#E2E8F0] border-b border-[#E2E8F0] text-xs">
        <div className="bg-white p-3.5 flex flex-col justify-between">
          <span className="text-[11px] font-bold text-[#64748B]">Total Rooms</span>
          <span className="text-base font-black text-[#0F172A] mt-1">{totalRooms}</span>
          <span className="text-[10px] text-[#94A3B8]">Enclosed spaces</span>
        </div>

        <div className="bg-white p-3.5 flex flex-col justify-between">
          <span className="text-[11px] font-bold text-[#64748B]">Average Room</span>
          <span className="text-base font-black text-[#0F172A] mt-1">
            {DimensionParser.format(avgRoomSqFt, 1)}{' '}
            <span className="text-xs font-normal text-[#64748B]">sq ft</span>
          </span>
          <span className="text-[10px] text-[#94A3B8]">
            {DimensionParser.format(avgRoomSqM, 2)} sq m
          </span>
        </div>

        <div className="bg-white p-3.5 flex flex-col justify-between">
          <span className="text-[11px] font-bold text-[#64748B]">Largest Space</span>
          <span className="text-base font-black text-blue-700 mt-1 truncate">
            {largestRoom ? largestRoom.room.name : '—'}
          </span>
          <span className="text-[10px] text-[#94A3B8]">
            {largestRoom ? `${DimensionParser.format(largestRoom.areaSqFt, 1)} sq ft (${largestRoom.percentage.toFixed(1)}%)` : '—'}
          </span>
        </div>

        <div className="bg-white p-3.5 flex flex-col justify-between">
          <span className="text-[11px] font-bold text-[#64748B]">Smallest Space</span>
          <span className="text-base font-black text-slate-700 mt-1 truncate">
            {smallestRoom ? smallestRoom.room.name : '—'}
          </span>
          <span className="text-[10px] text-[#94A3B8]">
            {smallestRoom ? `${DimensionParser.format(smallestRoom.areaSqFt, 1)} sq ft (${smallestRoom.percentage.toFixed(1)}%)` : '—'}
          </span>
        </div>
      </div>

      {/* Proportional Carpet Area Distribution Bar */}
      <div className="p-5 border-b border-[#E2E8F0] space-y-3">
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-1.5 font-bold text-[#334155]">
            <PieChart className="w-4 h-4 text-blue-600" />
            <span>Room Area Distribution (% of Aggregate Carpet)</span>
          </div>
          <span className="text-[11px] text-[#64748B]">
            Click any segment to inspect
          </span>
        </div>

        {/* Stacked Percentage Bar */}
        <div className="h-6 w-full rounded-xl bg-slate-100 overflow-hidden flex border border-[#CBD5E1] shadow-inner">
          {roomContributions.map((item, idx) => (
            <div
              key={item.room.id}
              onClick={() =>
                setSelectedRoomIndex(selectedRoomIndex === idx ? null : idx)
              }
              style={{ width: `${item.percentage}%` }}
              className={`h-full ${item.colorClass} cursor-pointer transition-all hover:opacity-90 relative group flex items-center justify-center text-[10px] font-extrabold select-none ${
                selectedRoomIndex === idx ? 'ring-2 ring-blue-900 z-10' : ''
              }`}
              title={`${item.room.name}: ${DimensionParser.format(item.areaSqFt, 1)} sq ft (${item.percentage.toFixed(1)}%)`}
            >
              {item.percentage >= 8 && (
                <span className="truncate px-1 drop-shadow-xs">
                  {item.percentage.toFixed(0)}%
                </span>
              )}
            </div>
          ))}
        </div>

        {/* Room Color Legend Pills */}
        <div className="flex flex-wrap gap-1.5 pt-1">
          {roomContributions.map((item, idx) => (
            <button
              key={item.room.id}
              type="button"
              onClick={() =>
                setSelectedRoomIndex(selectedRoomIndex === idx ? null : idx)
              }
              className={`inline-flex items-center gap-1.5 px-2 py-1 rounded-lg text-xs transition-all cursor-pointer border ${
                selectedRoomIndex === idx
                  ? 'bg-blue-50 border-blue-400 font-extrabold shadow-xs text-blue-900'
                  : 'bg-[#F8FAFC] border-[#E2E8F0] text-[#475569] hover:bg-[#F1F5F9]'
              }`}
            >
              <span
                className="w-2.5 h-2.5 rounded-full shrink-0"
                style={{ backgroundColor: item.borderColor }}
              />
              <span className="font-semibold">{item.room.name}:</span>
              <span className="font-bold text-[#0F172A]">
                {item.percentage.toFixed(1)}%
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Aggregate Details Section Toggle */}
      <div className="p-4 bg-[#FAFCFF]">
        <button
          type="button"
          onClick={() => setIsDetailsExpanded(!isDetailsExpanded)}
          className="w-full flex items-center justify-between text-xs font-bold text-[#334155] cursor-pointer hover:text-blue-600 transition-colors"
        >
          <div className="flex items-center gap-2">
            <Scale className="w-4 h-4 text-blue-600" />
            <span>Individual Room Aggregation Matrix ({totalRooms} Items)</span>
          </div>
          {isDetailsExpanded ? (
            <ChevronUp className="w-4 h-4 text-[#64748B]" />
          ) : (
            <ChevronDown className="w-4 h-4 text-[#64748B]" />
          )}
        </button>

        {isDetailsExpanded && (
          <div className="mt-4 space-y-3">
            {/* Room Matrix Table */}
            <div className="border border-[#E2E8F0] rounded-2xl overflow-hidden bg-white">
              <div className="overflow-x-auto">
                <table className="w-full text-xs text-left">
                  <thead className="bg-[#F8FAFC] text-[#475569] font-extrabold uppercase tracking-wider text-[10px] border-b border-[#E2E8F0]">
                    <tr>
                      <th className="py-2.5 px-3">#</th>
                      <th className="py-2.5 px-3">Room Name</th>
                      <th className="py-2.5 px-3">Dimensions</th>
                      <th className="py-2.5 px-3 text-right">Floor Area (Sq. Ft.)</th>
                      <th className="py-2.5 px-3 text-right">Floor Area (Sq. M.)</th>
                      <th className="py-2.5 px-3 text-right">% of Carpet</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#F1F5F9]">
                    {roomContributions.map((item, idx) => (
                      <tr
                        key={item.room.id}
                        onClick={() =>
                          setSelectedRoomIndex(selectedRoomIndex === idx ? null : idx)
                        }
                        className={`hover:bg-blue-50/40 transition-colors cursor-pointer ${
                          selectedRoomIndex === idx ? 'bg-blue-50/70 font-semibold' : ''
                        }`}
                      >
                        <td className="py-2.5 px-3 text-[#64748B] font-bold">
                          <span
                            className="inline-flex items-center justify-center w-5 h-5 rounded-full text-[10px] text-white font-bold"
                            style={{ backgroundColor: item.borderColor }}
                          >
                            {idx + 1}
                          </span>
                        </td>
                        <td className="py-2.5 px-3">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="font-bold text-[#0F172A]">{item.room.name}</span>
                            {(() => {
                              const type = item.room.spaceType || inferRoomSpaceType(item.room.name);
                              if (type === 'utility_inside') {
                                return (
                                  <span className="px-1.5 py-0.5 text-[9px] font-black rounded bg-emerald-100 text-emerald-800 border border-emerald-200">
                                    Enclosed Utility (In Carpet)
                                  </span>
                                );
                              }
                              if (type === 'utility_outside') {
                                return (
                                  <span className="px-1.5 py-0.5 text-[9px] font-black rounded bg-amber-100 text-amber-800 border border-amber-200">
                                    Dry Balcony (Built-up Only)
                                  </span>
                                );
                              }
                              if (type === 'balcony') {
                                return (
                                  <span className="px-1.5 py-0.5 text-[9px] font-black rounded bg-amber-100 text-amber-800 border border-amber-200">
                                    Balcony (Built-up Only)
                                  </span>
                                );
                              }
                              return (
                                <span className="px-1.5 py-0.5 text-[9px] font-semibold rounded bg-slate-100 text-slate-700">
                                  In Carpet
                                </span>
                              );
                            })()}
                          </div>
                        </td>
                        <td className="py-2.5 px-3 text-[#64748B]">
                          {DimensionParser.formatLength(item.room.lengthMeters, displayUnit)} ×{' '}
                          {DimensionParser.formatLength(item.room.widthMeters, displayUnit)}
                        </td>
                        <td className="py-2.5 px-3 text-right font-extrabold text-[#0F172A]">
                          {DimensionParser.format(item.areaSqFt, 1)}
                        </td>
                        <td className="py-2.5 px-3 text-right font-bold text-blue-700">
                          {DimensionParser.format(item.areaSqM, 2)}
                        </td>
                        <td className="py-2.5 px-3 text-right font-extrabold text-[#0F172A]">
                          {item.percentage.toFixed(1)}%
                        </td>
                      </tr>
                    ))}
                  </tbody>

                  {/* Table Total Aggregate Row */}
                  <tfoot className="bg-[#F8FAFC] border-t-2 border-[#E2E8F0] font-black text-xs text-[#0F172A]">
                    <tr>
                      <td colSpan={3} className="py-3 px-3 uppercase text-[11px] text-[#475569]">
                        Total Aggregate Net Floor Area:
                      </td>
                      <td className="py-3 px-3 text-right text-sm text-[#0F172A]">
                        {DimensionParser.format(usableAreaSqFt, 1)} sq ft
                      </td>
                      <td className="py-3 px-3 text-right text-sm text-blue-700">
                        {DimensionParser.format(usableAreaSqM, 2)} sq m
                      </td>
                      <td className="py-3 px-3 text-right text-sm text-emerald-700">
                        100.0%
                      </td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </div>

            {/* RERA Section 2(k) Step-by-Step Aggregate Formula Card */}
            <div className="p-3.5 bg-white border border-[#E2E8F0] rounded-2xl space-y-2 text-xs">
              <div className="flex items-center gap-1.5 font-bold text-[#0F172A]">
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                <span>Statutory RERA Area Compilation Sequence</span>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2.5 pt-1 text-[11px]">
                <div className="p-2.5 rounded-xl bg-[#F8FAFC] border border-[#E2E8F0]">
                  <span className="text-[#64748B] block">1. Net Usable Floor</span>
                  <strong className="text-xs text-[#0F172A]">
                    {DimensionParser.format(usableAreaSqFt, 1)} sq ft
                  </strong>
                  <span className="text-[10px] text-[#64748B] block mt-0.5">
                    Sum of {totalRooms} rooms clear space
                  </span>
                </div>

                <div className="p-2.5 rounded-xl bg-[#F8FAFC] border border-[#E2E8F0]">
                  <span className="text-[#64748B] block">
                    2. Internal Walls ({internalWallPercent}%)
                  </span>
                  <strong className="text-xs text-blue-700">
                    + {DimensionParser.format(internalWallAreaSqFt, 1)} sq ft
                  </strong>
                  <span className="text-[10px] text-[#64748B] block mt-0.5">
                    Sec 2(k) mandated inclusion
                  </span>
                </div>

                <div className="p-2.5 rounded-xl bg-[#F8FAFC] border border-[#E2E8F0]">
                  <span className="text-[#64748B] block">
                    3. External Walls ({externalWallPercent}%)
                  </span>
                  <strong className="text-xs text-blue-700">
                    + {DimensionParser.format(externalWallAreaSqFt, 1)} sq ft
                  </strong>
                  <span className="text-[10px] text-[#64748B] block mt-0.5">
                    Perimeter façade boundary
                  </span>
                </div>

                <div className="p-2.5 rounded-xl bg-blue-50/70 border border-blue-200">
                  <span className="text-blue-900 block font-bold">
                    4. Built-Up Area (Plinth)
                  </span>
                  <strong className="text-xs text-blue-950 font-black">
                    = {DimensionParser.format(builtUpAreaSqFt, 1)} sq ft
                  </strong>
                  <span className="text-[10px] text-blue-700 block mt-0.5">
                    {DimensionParser.format(builtUpAreaSqM, 2)} sq m (1 + 2 + 3)
                  </span>
                </div>
              </div>

              {/* Step 5 & 6 Common Loading to Super Built-up */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-1 text-[11px]">
                <div className="p-2.5 rounded-xl bg-[#F8FAFC] border border-[#E2E8F0]">
                  <span className="text-[#64748B] block">
                    5. Common Facility Loading ({loadingPercent}%)
                  </span>
                  <strong className="text-xs text-purple-700 font-bold">
                    + {DimensionParser.format(loadingAreaSqFt, 1)} sq ft
                  </strong>
                  <span className="text-[10px] text-[#64748B] block mt-0.5">
                    Lobbies, elevators, & stairwells
                  </span>
                </div>

                <div className="p-2.5 rounded-xl bg-purple-50/70 border border-purple-200">
                  <span className="text-purple-900 block font-bold">
                    6. Super Built-Up (Saleable Area)
                  </span>
                  <strong className="text-xs text-purple-950 font-black">
                    = {DimensionParser.format(superBuiltUpAreaSqFt, 1)} sq ft
                  </strong>
                  <span className="text-[10px] text-purple-700 block mt-0.5">
                    Built-up (Step 4) + Loading (Step 5)
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
