import React, { createContext, useContext, useState, useEffect } from 'react';
import { AreaDisplayUnit, PropertyAudit, UserProfile } from '../types';
import { DimensionParser } from '../utils/dimensionParser';

interface SessionContextType {
  user: UserProfile;
  audits: PropertyAudit[];
  displayUnit: AreaDisplayUnit;
  setDisplayUnit: (unit: AreaDisplayUnit) => void;
  defaultInternalWallPercent: number;
  setDefaultInternalWallPercent: (val: number) => void;
  defaultExternalWallPercent: number;
  setDefaultExternalWallPercent: (val: number) => void;
  defaultLoadingPercent: number;
  setDefaultLoadingPercent: (val: number) => void;
  saveAudit: (audit: Omit<PropertyAudit, 'id' | 'timestamp'> & { id?: string; timestamp?: string }) => Promise<PropertyAudit>;
  deleteAudit: (id: string) => Promise<boolean>;
  getAudit: (id: string) => PropertyAudit | undefined;
  login: (email: string, displayName?: string) => void;
  logout: () => void;
  continueAsGuest: () => void;
  clearAllData: () => void;
}

const GUEST_STORAGE_KEY = 'flatverify_guest_audits_v1';
const USER_STORAGE_KEY_PREFIX = 'flatverify_user_audits_v1_';
const SETTINGS_STORAGE_KEY = 'flatverify_settings_v1';

const INITIAL_SEED_AUDITS: PropertyAudit[] = [
  {
    id: 'seed_audit_1',
    type: 'scan',
    auditName: 'Sobha Dream Acres - 2BHK Floor Plan',
    builder: 'Sobha Developers',
    project: 'Sobha Dream Acres',
    tower: 'Tower 4 (Wing B)',
    flat: '802',
    floor: '8th Floor',
    configuration: '2 BHK (Regular)',
    notes: 'Floor plan scanned from builder brochure. Verified dimensions against master architectural drawings.',
    timestamp: new Date(Date.now() - 86400000 * 2).toISOString(),
    rawText: 'LIVING/DINING 16\'0"x12\'0" | MASTER BED 12\'0"x14\'0" | BEDROOM 11\'0"x12\'0" | KITCHEN 8\'6"x10\'0" | TOILET 5\'0"x8\'0" | BALCONY 10\'0"x4\'6"',
    parsedDimensions: {
      'Dimension 1': '16\' 0"',
      'Dimension 2': '12\' 0"',
      'Dimension 3': '12\' 0"',
      'Dimension 4': '14\' 0"',
      'Dimension 5': '11\' 0"',
      'Dimension 6': '12\' 0"',
      'Dimension 7': '8\' 6"',
      'Dimension 8': '10\' 0"',
      'Dimension 9': '5\' 0"',
      'Dimension 10': '8\' 0"',
      'Dimension 11': '10\' 0"',
      'Dimension 12': '4\' 6"',
    },
    rooms: [
      {
        name: 'Living / Dining Room',
        lengthMeters: DimensionParser.feetInchesToMeters(16, 0),
        widthMeters: DimensionParser.feetInchesToMeters(12, 0),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Master Bedroom',
        lengthMeters: DimensionParser.feetInchesToMeters(12, 0),
        widthMeters: DimensionParser.feetInchesToMeters(14, 0),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Bedroom 2',
        lengthMeters: DimensionParser.feetInchesToMeters(11, 0),
        widthMeters: DimensionParser.feetInchesToMeters(12, 0),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Kitchen',
        lengthMeters: DimensionParser.feetInchesToMeters(8, 6),
        widthMeters: DimensionParser.feetInchesToMeters(10, 0),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Master Bathroom',
        lengthMeters: DimensionParser.feetInchesToMeters(5, 0),
        widthMeters: DimensionParser.feetInchesToMeters(8, 0),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Living Balcony',
        lengthMeters: DimensionParser.feetInchesToMeters(10, 0),
        widthMeters: DimensionParser.feetInchesToMeters(4, 6),
        unit: 'feetInches',
        isUserVerified: true,
      },
    ],
    usableArea: 662.0,
    carpetArea: 662.0,
    internalWallPercent: 12.0,
    internalWallArea: 79.44,
    builtUpArea: 741.44,
    externalWallPercent: 0.0,
    externalWallArea: 0.0,
    loadingPercent: 30.0,
    loadingArea: 222.43,
    superBuiltUpArea: 963.87,
  },
  {
    id: 'seed_audit_2',
    type: 'calculator',
    auditName: 'Prestige Falcon City - 3BHK Area Audit',
    builder: 'Prestige Group',
    project: 'Prestige Falcon City',
    tower: 'Tower 2',
    flat: '1401',
    floor: '14th Floor',
    configuration: '3 BHK (Large)',
    notes: 'RERA carpet area verification calculation against agreement quote.',
    timestamp: new Date(Date.now() - 86400000 * 5).toISOString(),
    rooms: [
      {
        name: 'Living Room',
        lengthMeters: DimensionParser.feetInchesToMeters(18, 0),
        widthMeters: DimensionParser.feetInchesToMeters(13, 6),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Dining Room',
        lengthMeters: DimensionParser.feetInchesToMeters(10, 6),
        widthMeters: DimensionParser.feetInchesToMeters(12, 0),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Master Bedroom',
        lengthMeters: DimensionParser.feetInchesToMeters(14, 0),
        widthMeters: DimensionParser.feetInchesToMeters(15, 0),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Bedroom 2',
        lengthMeters: DimensionParser.feetInchesToMeters(12, 0),
        widthMeters: DimensionParser.feetInchesToMeters(13, 0),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Bedroom 3',
        lengthMeters: DimensionParser.feetInchesToMeters(11, 0),
        widthMeters: DimensionParser.feetInchesToMeters(12, 6),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Kitchen',
        lengthMeters: DimensionParser.feetInchesToMeters(9, 0),
        widthMeters: DimensionParser.feetInchesToMeters(11, 6),
        unit: 'feetInches',
        isUserVerified: true,
      },
      {
        name: 'Master Bathroom',
        lengthMeters: DimensionParser.feetInchesToMeters(6, 0),
        widthMeters: DimensionParser.feetInchesToMeters(9, 0),
        unit: 'feetInches',
        isUserVerified: true,
      },
    ],
    usableArea: 1113.5,
    carpetArea: 1113.5,
    internalWallPercent: 12.0,
    internalWallArea: 133.62,
    builtUpArea: 1247.12,
    externalWallPercent: 0.0,
    externalWallArea: 0.0,
    loadingPercent: 32.0,
    loadingArea: 399.08,
    superBuiltUpArea: 1646.2,
  },
];

const DEFAULT_USER: UserProfile = {
  uid: 'guest_user',
  email: '',
  displayName: 'Guest Auditor',
  isGuest: true,
  createdAt: new Date().toISOString(),
};

const SessionContext = createContext<SessionContextType | null>(null);

export const SessionProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile>(() => {
    try {
      const savedUser = localStorage.getItem('flatverify_user_session');
      if (savedUser) return JSON.parse(savedUser);
    } catch (_) {}
    return DEFAULT_USER;
  });

  const [displayUnit, setDisplayUnitState] = useState<AreaDisplayUnit>(() => {
    try {
      const settings = localStorage.getItem(SETTINGS_STORAGE_KEY);
      if (settings) {
        const parsed = JSON.parse(settings);
        if (parsed.displayUnit) return parsed.displayUnit;
      }
    } catch (_) {}
    return 'imperial';
  });

  const [defaultInternalWallPercent, setDefaultInternalWallPercentState] = useState<number>(12.0);
  const [defaultExternalWallPercent, setDefaultExternalWallPercentState] = useState<number>(0.0);
  const [defaultLoadingPercent, setDefaultLoadingPercentState] = useState<number>(30.0);

  const [audits, setAudits] = useState<PropertyAudit[]>(() => {
    try {
      const key = user.isGuest ? GUEST_STORAGE_KEY : `${USER_STORAGE_KEY_PREFIX}${user.uid}`;
      const saved = localStorage.getItem(key);
      if (saved) {
        return JSON.parse(saved);
      }
      return INITIAL_SEED_AUDITS;
    } catch (_) {
      return INITIAL_SEED_AUDITS;
    }
  });

  // Persist audits whenever user or audits change
  useEffect(() => {
    try {
      const key = user.isGuest ? GUEST_STORAGE_KEY : `${USER_STORAGE_KEY_PREFIX}${user.uid}`;
      localStorage.setItem(key, JSON.stringify(audits));
    } catch (_) {}
  }, [audits, user]);

  const setDisplayUnit = (unit: AreaDisplayUnit) => {
    setDisplayUnitState(unit);
    try {
      const settings = JSON.parse(localStorage.getItem(SETTINGS_STORAGE_KEY) || '{}');
      settings.displayUnit = unit;
      localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(settings));
    } catch (_) {}
  };

  const setDefaultInternalWallPercent = (val: number) => {
    setDefaultInternalWallPercentState(val);
  };

  const setDefaultExternalWallPercent = (val: number) => {
    setDefaultExternalWallPercentState(val);
  };

  const setDefaultLoadingPercent = (val: number) => {
    setDefaultLoadingPercentState(val);
  };

  const saveAudit = async (
    auditData: Omit<PropertyAudit, 'id' | 'timestamp'> & { id?: string; timestamp?: string }
  ): Promise<PropertyAudit> => {
    const newAudit: PropertyAudit = {
      ...auditData,
      id: auditData.id || `audit_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      timestamp: auditData.timestamp || new Date().toISOString(),
    };

    setAudits(prev => [newAudit, ...prev.filter(a => a.id !== newAudit.id)]);
    return newAudit;
  };

  const deleteAudit = async (id: string): Promise<boolean> => {
    setAudits(prev => prev.filter(a => a.id !== id));
    return true;
  };

  const getAudit = (id: string): PropertyAudit | undefined => {
    return audits.find(a => a.id === id);
  };

  const login = (email: string, displayName?: string) => {
    const newUser: UserProfile = {
      uid: `usr_${btoa(email).substring(0, 10)}`,
      email,
      displayName: displayName || email.split('@')[0],
      isGuest: false,
      createdAt: new Date().toISOString(),
    };
    setUser(newUser);
    localStorage.setItem('flatverify_user_session', JSON.stringify(newUser));

    // Load user audits if any, or seed with initial
    const userAuditsKey = `${USER_STORAGE_KEY_PREFIX}${newUser.uid}`;
    const userSaved = localStorage.getItem(userAuditsKey);
    if (userSaved) {
      setAudits(JSON.parse(userSaved));
    } else {
      // Migrate guest audits to user account
      setAudits(audits);
    }
  };

  const logout = () => {
    setUser(DEFAULT_USER);
    localStorage.removeItem('flatverify_user_session');
    // Reload guest audits
    const guestSaved = localStorage.getItem(GUEST_STORAGE_KEY);
    if (guestSaved) {
      setAudits(JSON.parse(guestSaved));
    } else {
      setAudits(INITIAL_SEED_AUDITS);
    }
  };

  const continueAsGuest = () => {
    setUser(DEFAULT_USER);
    localStorage.removeItem('flatverify_user_session');
  };

  const clearAllData = () => {
    setAudits([]);
    localStorage.removeItem(GUEST_STORAGE_KEY);
    if (!user.isGuest) {
      localStorage.removeItem(`${USER_STORAGE_KEY_PREFIX}${user.uid}`);
    }
  };

  return (
    <SessionContext.Provider
      value={{
        user,
        audits,
        displayUnit,
        setDisplayUnit,
        defaultInternalWallPercent,
        setDefaultInternalWallPercent,
        defaultExternalWallPercent,
        setDefaultExternalWallPercent,
        defaultLoadingPercent,
        setDefaultLoadingPercent,
        saveAudit,
        deleteAudit,
        getAudit,
        login,
        logout,
        continueAsGuest,
        clearAllData,
      }}
    >
      {children}
    </SessionContext.Provider>
  );
};

export const useSession = (): SessionContextType => {
  const context = useContext(SessionContext);
  if (!context) {
    throw new Error('useSession must be used within a SessionProvider');
  }
  return context;
};
