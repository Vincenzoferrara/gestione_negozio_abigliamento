export const LUXURY_PRESET = {
    layoutTemplate: 'luxury',
    headerStyle: 'image',
    backgroundColor: '#1A1A1A',
    textColor: '#FFFFFF',
    buttonColor: '#8B6F47',
    buttonTextColor: '#FFFFFF',
    navLayout: 'list',
    showReferralOnHome: false,
    borderRadius: 12,
};

export const MODERN_PRESET = {
    layoutTemplate: 'modern',
    headerStyle: 'solid',
    backgroundColor: '#1A1A1A',
    textColor: '#FFFFFF',
    buttonColor: '#8B6F47',
    buttonTextColor: '#FFFFFF',
    navLayout: 'grid',
    showReferralOnHome: false,
    borderRadius: 16,
};

export const TEMPLATE_OPTIONS = [
    {
        id: 'luxury',
        label: 'Classic list style',
        description: 'Classic list home layout',
        preset: LUXURY_PRESET,
    },
    {
        id: 'modern',
        label: 'Card Based',
        description: 'Card-based home layout',
        preset: MODERN_PRESET,
    },
];

export const getTemplatePreset = (id) => {
    if (id === 'modern') {
        return { ...MODERN_PRESET };
    }
    return { ...LUXURY_PRESET };
};

export const normalizeLayoutTemplate = (id) => (id === 'modern' ? 'modern' : 'luxury');
