import React, { useState } from 'react';
import { X, Building2, Save, FileText } from 'lucide-react';

interface AuditDetailsModalProps {
  isOpen: boolean;
  defaultName: string;
  onClose: () => void;
  onSave: (details: {
    auditName: string;
    builder: string;
    project: string;
    tower: string;
    flat: string;
    floor: string;
    configuration: string;
    notes: string;
  }) => void;
}

export const AuditDetailsModal: React.FC<AuditDetailsModalProps> = ({
  isOpen,
  defaultName,
  onClose,
  onSave,
}) => {
  const [auditName, setAuditName] = useState(defaultName);
  const [builder, setBuilder] = useState('');
  const [project, setProject] = useState('');
  const [tower, setTower] = useState('');
  const [flat, setFlat] = useState('');
  const [floor, setFloor] = useState('');
  const [configuration, setConfiguration] = useState('2 BHK');
  const [notes, setNotes] = useState('');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave({
      auditName: auditName.trim() || 'Property Area Audit',
      builder: builder.trim(),
      project: project.trim(),
      tower: tower.trim(),
      flat: flat.trim(),
      floor: floor.trim(),
      configuration: configuration.trim(),
      notes: notes.trim(),
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
      <div className="bg-white rounded-2xl w-full max-w-lg shadow-2xl border border-[#E2E8F0] overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        {/* Modal Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#F1F5F9] bg-[#F8FAFC]">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center">
              <Building2 className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-base text-[#0F172A]">Save Property Audit</h3>
              <p className="text-xs text-[#64748B]">Document property specs for your verified PDF report</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 text-[#94A3B8] hover:text-[#0F172A] rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4 max-h-[80vh] overflow-y-auto">
          <div>
            <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
              Audit Title <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              value={auditName}
              onChange={e => setAuditName(e.target.value)}
              placeholder="e.g. Sobha Windsor - 3BHK Carpet Audit"
              className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-bold text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
                Builder / Developer
              </label>
              <input
                type="text"
                value={builder}
                onChange={e => setBuilder(e.target.value)}
                placeholder="e.g. Prestige, Godrej, DLF"
                className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
                Project Name
              </label>
              <input
                type="text"
                value={project}
                onChange={e => setProject(e.target.value)}
                placeholder="e.g. Palm Meadows"
                className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
                Tower / Wing
              </label>
              <input
                type="text"
                value={tower}
                onChange={e => setTower(e.target.value)}
                placeholder="Tower B"
                className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
                Flat / Unit #
              </label>
              <input
                type="text"
                value={flat}
                onChange={e => setFlat(e.target.value)}
                placeholder="1004"
                className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
                Floor
              </label>
              <input
                type="text"
                value={floor}
                onChange={e => setFloor(e.target.value)}
                placeholder="10th"
                className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
              Configuration
            </label>
            <select
              value={configuration}
              onChange={e => setConfiguration(e.target.value)}
              className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="1 BHK">1 BHK</option>
              <option value="2 BHK">2 BHK</option>
              <option value="2.5 BHK">2.5 BHK</option>
              <option value="3 BHK">3 BHK</option>
              <option value="3.5 BHK">3.5 BHK</option>
              <option value="4 BHK">4 BHK</option>
              <option value="Penthouse">Penthouse</option>
              <option value="Villa / Independent House">Villa / Independent House</option>
              <option value="Commercial / Studio">Commercial / Studio</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold text-[#475569] mb-1 uppercase tracking-wide">
              Audit Notes / Observations
            </label>
            <textarea
              rows={3}
              value={notes}
              onChange={e => setNotes(e.target.value)}
              placeholder="e.g. Scanned from sales brochure. External walls excluded. Balcony measured separately as per RERA rule 2(k)."
              className="w-full bg-[#F8FAFC] border border-[#CBD5E1] rounded-xl px-3 py-2 text-sm font-medium text-[#0F172A] focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white resize-none"
            />
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end gap-3 pt-3 border-t border-[#F1F5F9]">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-bold text-[#64748B] hover:text-[#0F172A] rounded-xl transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-5 py-2.5 bg-[#1D4ED8] hover:bg-[#1E40AF] text-white font-bold text-sm rounded-xl shadow-xs shadow-blue-500/20 flex items-center gap-2 transition-colors cursor-pointer"
            >
              <Save className="w-4 h-4" />
              Save Audit
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
