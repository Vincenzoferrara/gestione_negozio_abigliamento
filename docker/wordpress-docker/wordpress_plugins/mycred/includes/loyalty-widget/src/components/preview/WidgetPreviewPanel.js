import { useState, useEffect, useRef } from '@wordpress/element';
import {
    Box,
    Typography,
} from '@mui/material';
import { __ } from '@wordpress/i18n';
import WidgetShell from '../WidgetShell';
import HomeScreen from '../HomeScreen';
import EarnTab from '../tabs/EarnTab';
import BoardTab from '../tabs/BoardTab';
import LogsTab from '../tabs/LogsTab';
import ProfileTab from '../tabs/ProfileTab';
import RedeemTab from '../tabs/RedeemTab';
import FaqTab from '../tabs/FaqTab';
import Badges from '../Badges';
import Ranks from '../Ranks';
import {
    fixtureGuestUser,
    fixtureMemberUser,
    fixtureHooks,
    fixtureLeaderboard,
    fixtureLogs,
    fixtureBadges,
    fixtureRanks,
    fixtureCoupons,
    fixtureAddons,
    fixtureTiers,
} from './fixtureData';
import { usePreviewSettings } from '../../context/PreviewSettingsContext';

const SCREEN_OPTIONS = [
    { value: 'home', label: __('Home', 'mycred') },
    { value: 'earn', label: __('Earn', 'mycred') },
    { value: 'redeem', label: __('Redeem', 'mycred') },
    { value: 'board', label: __('Board', 'mycred') },
    { value: 'logs', label: __('History', 'mycred') },
    { value: 'profile', label: __('Profile', 'mycred') },
    { value: 'ranks', label: __('Ranks', 'mycred') },
    { value: 'badges', label: __('Badges', 'mycred') },
];

export default function WidgetPreviewPanel({ guestMode: externalGuestMode, onGuestModeChange }) {
    const { settings } = usePreviewSettings();
    const { design, content, tabs, general, faq } = settings;

    const containerRef = useRef(null);
    const [scale, setScale] = useState(1);

    useEffect(() => {
        if (!containerRef.current) return;
        const observer = new ResizeObserver((entries) => {
            for (let entry of entries) {
                const width = entry.contentRect.width;
                if (width < 380) setScale(0.7);
                else if (width < 430) setScale(0.8);
                else if (width < 480) setScale(0.9);
                else setScale(1);
            }
        });
        observer.observe(containerRef.current);
        return () => observer.disconnect();
    }, []);

    const [internalGuest, setInternalGuest] = useState(true);
    const [currentScreen, setCurrentScreen] = useState('home');
    const [launcherOpen, setLauncherOpen] = useState(true);

    const isGuestControlled = externalGuestMode !== undefined;
    const isGuest = isGuestControlled ? externalGuestMode : internalGuest;

    const setGuest = (value) => {
        if (onGuestModeChange) {
            onGuestModeChange(value);
        } else {
            setInternalGuest(value);
        }
    };

    const isPro = window.mycredLoyaltyWidgetData?.is_toolkit_pro_active || false;
    const assetsUrl = window.mycredLoyaltyWidgetData?.assets_url || '';

    useEffect(() => {
        window.mycredLoyaltyWidget = window.mycredLoyaltyWidget || {};
        window.mycredLoyaltyWidget.addons = fixtureAddons;
        window.mycredLoyaltyWidget.point_types = { mycred_default: __('Points', 'mycred') };
        window.mycredLoyaltyWidget.assets_url = assetsUrl;
        window.mycredLoyaltyWidget.is_toolkit_pro_active = isPro;
    }, [assetsUrl, isPro]);

    const currentContent = isGuest ? (content.guest || {}) : (content.member || {});
    const user = isGuest ? fixtureGuestUser : fixtureMemberUser;

    const previewSettings = {
        design,
        content,
        tabs,
        general,
        faq: faq || { screenTitle: __('FAQs', 'mycred'), items: [] },
        eventtriggers: settings.eventtriggers || window.mycredLoyaltyWidgetData?.settings?.eventtriggers || {},
    };

    const handleNavigate = (screen) => setCurrentScreen(screen);
    const handleBack = () => setCurrentScreen('home');
    const handleClose = () => {};

    const renderHome = () => (
        <HomeScreen
            design={design}
            content={currentContent}
            tabs={tabs}
            faq={faq}
            user={user}
            isGuest={isGuest}
            isPro={isPro}
            assetsUrl={assetsUrl}
            ranksEnabled={fixtureAddons.ranks_enabled}
            badgesEnabled={fixtureAddons.badges_enabled}
            onNavigate={handleNavigate}
            onClose={handleClose}
            previewMode
            previewTiers={fixtureTiers}
        />
    );

    const renderScreen = () => {
        const tabProps = {
            settings: previewSettings,
            currentContent,
            user,
            onBack: handleBack,
            onClose: handleClose,
            previewMode: true,
        };

        switch (currentScreen) {
            case 'earn':
                return <EarnTab {...tabProps} activeHooks={fixtureHooks} previewMode />;
            case 'board':
                return <BoardTab {...tabProps} previewMode previewData={fixtureLeaderboard} />;
            case 'logs':
                return <LogsTab {...tabProps} previewMode previewData={fixtureLogs} />;
            case 'profile':
                return <ProfileTab {...tabProps} previewMode />;
            case 'redeem':
                return <RedeemTab {...tabProps} previewMode previewData={fixtureCoupons} />;
            case 'faq':
                return <FaqTab {...tabProps} />;
            case 'badges':
                return <Badges {...tabProps} previewMode previewData={fixtureBadges} />;
            case 'ranks':
                return <Ranks {...tabProps} previewMode previewData={fixtureRanks} />;
            default:
                return renderHome();
        }
    };

    const position = general.widgetPosition || 'bottom-right';
    const isBottom = position.includes('bottom');
    const isRight = position.includes('right');
    const marginTop = general.marginTop ?? 24;
    const marginRight = general.marginRight ?? 24;
    const marginBottom = general.marginBottom ?? 24;
    const marginLeft = general.marginLeft ?? 24;

    return (
        <Box ref={containerRef}>
            <Box sx={{
                bgcolor: '#E8E8E8',
                borderRadius: '12px',
                border: '1px solid #D0D0D0',
                minHeight: 820 * scale,
                position: 'relative',
                overflow: 'hidden',
                backgroundImage: 'linear-gradient(180deg, #f0f0f0 0%, #e4e4e4 100%)',
            }}>
                <Box sx={{ height: 28, bgcolor: '#D8D8D8', borderBottom: '1px solid #ccc', display: 'flex', alignItems: 'center', px: 1.5, gap: 0.75 }}>
                    {['#ff5f57', '#febc2e', '#28c840'].map((c) => (
                        <Box key={c} sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: c }} />
                    ))}
                    <Typography sx={{ fontSize: '10px', color: '#888', ml: 1 }}>{__('Store preview', 'mycred')}</Typography>
                </Box>

                <Box sx={{
                    position: 'absolute',
                    ...(isBottom ? { bottom: marginBottom } : { top: marginTop + 28 }),
                    ...(isRight ? { right: marginRight } : { left: marginLeft }),
                    transformOrigin: isRight ? (isBottom ? 'bottom right' : 'top right') : (isBottom ? 'bottom left' : 'top left'),
                    transform: `scale(${scale})`,
                    transition: 'transform 0.1s ease-in-out',
                }}>
                    <WidgetShell
                        design={design}
                        launcherOpen={launcherOpen}
                        containerRadius={24}
                    >
                        {renderScreen()}
                    </WidgetShell>
                </Box>
            </Box>

            <Typography sx={{ fontSize: '12px', color: '#888', mt: 1.5, textAlign: 'center' }}>
                {__('Preview uses sample data. Save settings to apply on your site.', 'mycred')}
            </Typography>
        </Box>
    );
}
