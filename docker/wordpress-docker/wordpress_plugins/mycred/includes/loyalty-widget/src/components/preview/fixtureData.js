import { __ } from '@wordpress/i18n';

export const fixtureGuestUser = {
    is_logged_in: false,
    all_balances: [],
};

export const fixtureMemberUser = {
    is_logged_in: true,
    display_name: 'Alex Morgan',
    avatar: '',
    avatar_url: '',
    balance: 21,
    rank: __('Bronze', 'mycred'),
    rank_min: 0,
    rank_max: 99,
    all_balances: [
        { type: 'mycred_default', label: __('Points', 'mycred'), formatted: '21' },
        { type: 'mycred_gold', label: __('Gold', 'mycred'), formatted: '5' },
    ],
    badges: [],
};

export const fixtureHooks = [
    { id: 'registration', title: __('Register an account', 'mycred'), points: 50, category: 'wordpress', plural: __('points', 'mycred'), singular: __('point', 'mycred') },
    { id: 'daily_login', title: __('Daily login', 'mycred'), points: 10, category: 'wordpress', plural: __('points', 'mycred'), singular: __('point', 'mycred') },
    { id: 'woocommerce_purchase', title: __('Place an order', 'mycred'), points: 100, category: 'woocommerce', plural: __('points', 'mycred'), singular: __('point', 'mycred') },
];

export const fixtureLeaderboard = [
    { id: 1, position: 1, name: 'Sarah K.', avatar: '', rank: __('Gold', 'mycred'), raw_balance: 1250, is_current_user: false, top_badge_image: '', top_badge_title: '' },
    { id: 2, position: 2, name: 'James L.', avatar: '', rank: __('Silver', 'mycred'), raw_balance: 980, is_current_user: false, top_badge_image: '', top_badge_title: '' },
    { id: 3, position: 3, name: 'Alex Morgan', avatar: '', rank: __('Bronze', 'mycred'), raw_balance: 21, is_current_user: true, top_badge_image: '', top_badge_title: '' },
    { id: 4, position: 4, name: 'Emma W.', avatar: '', rank: '', raw_balance: 15, is_current_user: false, top_badge_image: '', top_badge_title: '' },
];

export const fixtureLogs = [
    { id: 1, amount: '+10', reason: __('Daily login', 'mycred'), date: __('Today', 'mycred'), type: 'credit' },
    { id: 2, amount: '+50', reason: __('Registration', 'mycred'), date: __('Yesterday', 'mycred'), type: 'credit' },
    { id: 3, amount: '-5', reason: __('Redeemed coupon', 'mycred'), date: __('2 days ago', 'mycred'), type: 'debit' },
];

export const fixtureBadges = [
    {
        id: 1,
        title: __('First Steps', 'mycred'),
        levels: [{ image_url: '', label: __('Level 1', 'mycred'), earned: true, progress: 100 }],
    },
    {
        id: 2,
        title: __('Shopper', 'mycred'),
        levels: [{ image_url: '', label: __('Level 1', 'mycred'), earned: false, progress: 60 }],
    },
    {
        id: 3,
        title: __('Social Star', 'mycred'),
        levels: [{ image_url: '', label: __('Level 1', 'mycred'), earned: false, progress: 20 }],
    },
];

export const fixtureRanks = [
    { id: 1, title: __('Explorer', 'mycred'), minimum: 0, maximum: 99, is_current: true, image_url: '' },
    { id: 2, title: __('Collector', 'mycred'), minimum: 100, maximum: 499, is_current: false, image_url: '' },
    { id: 3, title: __('Connoisseur', 'mycred'), minimum: 500, maximum: 999, is_current: false, image_url: '' },
    { id: 4, title: __('Elite', 'mycred'), minimum: 1000, maximum: null, is_current: false, image_url: '' },
];

export const fixtureTiers = [
    { id: 1, title: __('Explorer', 'mycred'), requirement: __('Spend $0', 'mycred') },
    { id: 2, title: __('Collector', 'mycred'), requirement: __('Spend $500', 'mycred') },
    { id: 3, title: __('Connoisseur', 'mycred'), requirement: __('Spend $2,000', 'mycred') },
];

export const fixtureCoupons = [
    { id: 1, code: 'SAVE10', description: __('10% off your order', 'mycred'), date_expires: __('Dec 31', 'mycred'), formatted_amount: '10%', status: __('Active', 'mycred') },
    { id: 2, code: 'WELCOME20', description: __('Welcome discount', 'mycred'), date_expires: __('Jan 15', 'mycred'), formatted_amount: '$20', status: __('Active', 'mycred') },
];

export const fixtureAddons = {
    ranks_enabled: true,
    badges_enabled: true,
    is_toolkit_pro_active: true,
};
