export const ROOM_CATEGORIES: Record<string, string[]> = {
  'Living & Dining': [
    'Living Room',
    'Dining Room',
    'Drawing Room',
    'Family Room',
    'Foyer / Entry',
    'Lounge',
  ],
  'Bedrooms': [
    'Master Bedroom',
    'Bedroom 1',
    'Bedroom 2',
    'Bedroom 3',
    'Guest Bedroom',
    'Kid\'s Bedroom',
    'Dress / Wardrobe',
  ],
  'Kitchen & Utility': [
    'Kitchen',
    'Dry Kitchen',
    'Wet Kitchen',
    'Utility Area (Inside Outer Wall)',
    'Dry Balcony (Outside Outer Wall)',
    'Utility Area',
    'Dry Balcony / Yard',
    'Pantry',
    'Store Room',
  ],
  'Bathrooms': [
    'Master Bathroom',
    'Common Bathroom',
    'Attached Bathroom 1',
    'Attached Bathroom 2',
    'Powder Room',
    'Guest Toilet',
  ],
  'Outdoor & Balcony': [
    'Living Balcony',
    'Master Balcony',
    'Balcony',
    'Open Terrace',
    'Sitout',
    'Deck',
  ],
  'Other Spaces': [
    'Study Room / Office',
    'Pooja Room / Mandir',
    'Servant Room',
    'Servant Bathroom',
    'Passage / Corridor',
    'Staircase',
  ],
};

export const ALL_STANDARD_ROOM_NAMES = Object.values(ROOM_CATEGORIES).flat();

export const CUSTOM_ROOM_OPTION = 'Other / Custom';
