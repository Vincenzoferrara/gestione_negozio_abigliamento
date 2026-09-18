import { useState } from '@wordpress/element';
import {
    Box,
    Typography,
    IconButton,
    Paper,
    Button,
} from '@mui/material';

import CloseIcon from '@mui/icons-material/Close';
import LoginIcon from '@mui/icons-material/Login';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import LeaderboardIcon from '@mui/icons-material/Leaderboard';
import { __, sprintf } from '@wordpress/i18n';

const hexToRgba = (hex, opacity) => {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? `rgba(${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(result[3], 16)}, ${opacity})` : hex;
};

// Trophy SVG component
const TrophyIllustration = ({ color }) => {
    const assetsUrl = window.mycredLoyaltyWidgetData?.assets_url || '';
    return (
        <Box
            component="img"
            src={assetsUrl + 'trophy.svg'}
            alt="Trophy"
            sx={{
                width: 120,
                height: 120,
                position: 'absolute',
                top: '76px',
                left: '126px'
            }}
        />
    );
};

const NavButton = ({ icon: Icon, label, color, textColor, svgSrc, active }) => (
    <Paper
        elevation={0}
        sx={{
            width: '100%',
            height: '44px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '8px',
            borderRadius: '12px',
            bgcolor: active ? color : '#fff',
            color: active ? textColor : color,
            cursor: 'pointer',
            border: active ? `1px solid ${color}` : '1px solid transparent',
            boxShadow: '0px 8px 16px -8px #EDE8FF',
            transition: '0.2s',
            '&:hover': {
                bgcolor: active ? color : hexToRgba(color || '#5E2CED', 0.04),
                borderColor: color || '#5E2CED',
                color: active ? textColor : color,
            }
        }}
    >
        {svgSrc ? (
            <Box
                sx={{
                    width: 20,
                    height: 20,
                    bgcolor: 'currentColor',
                    maskImage: `url(${svgSrc})`,
                    maskRepeat: 'no-repeat',
                    maskPosition: 'center',
                    maskSize: 'contain',
                    WebkitMaskImage: `url(${svgSrc})`,
                    WebkitMaskRepeat: 'no-repeat',
                    WebkitMaskPosition: 'center',
                    WebkitMaskSize: 'contain',
                }}
            />
        ) : Icon ? (
            <Icon sx={{ color: 'inherit', fontSize: 20 }} />
        ) : null}
        <Typography sx={{ fontSize: '14px', fontWeight: 600, color: 'inherit', fontFamily: "'Instrument Sans', sans-serif" }}>{label}</Typography>
    </Paper>
);
const WidgetPreview = ({ settings = {}, activePreviewTab = 0, content = {} }) => {
    const isPro = window.mycredLoyaltyWidgetData?.is_toolkit_pro_active || false;
    const bgColor = settings.backgroundColor || '#2D1572';
    const textColor = settings.textColor || '#5E2CED';
    const btnColor = settings.buttonColor || '#5E2CED';
    const btnTextColor = settings.buttonTextColor || '#FFFFFF';
    const assetsUrl = window.mycredLoyaltyWidgetData?.assets_url || '';

    // Determine current content based on tab
    const isGuest = activePreviewTab === 2; // In Content tab, 2 is Guest
    const currentContent = isGuest ? (content.guest || {}) : (content.member || {});

    // Animation helper
    const getAnimation = () => {
        const type = settings.launcherAnimation || 'none';
        if (type === 'none') return 'none';
        return `${type}Keyframe 0.5s cubic-bezier(0.4, 0, 0.2, 1) forwards`;
    };

    return (
        <Box sx={{
            position: 'relative',
            pb: '100px',
            // Keyframes for launcher animations
            '@keyframes fadeKeyframe': {
                '0%': { opacity: 0 },
                '100%': { opacity: 1 }
            },
            '@keyframes slideKeyframe': {
                '0%': { transform: 'translateY(20px)', opacity: 0 },
                '100%': { transform: 'translateY(0)', opacity: 1 }
            },
            '@keyframes zoomKeyframe': {
                '0%': { transform: 'scale(0.5)', opacity: 0 },
                '100%': { transform: 'scale(1)', opacity: 1 }
            }
        }}> {/* Root wrapper to allow absolute children outside overflow */}
            <Box
                key={`widget-${settings.launcherAnimation}`} // Re-trigger entry animation when setting changes
                sx={{
                    width: '420px',
                    height: '652px',
                    bgcolor: '#F8F6FF', // Updated to match Figma background
                    borderRadius: '24px',
                    boxShadow: '0px 16px 32px 0px rgba(230, 225, 250, 0.5)', // Updated shadow
                    overflow: 'hidden',
                    fontFamily: "'Instrument Sans', sans-serif",
                    position: 'relative',
                    animation: getAnimation(),
                    border: '1px solid #ECE7FF' // Matching border
                }}
            >
                {/* Header */}
                <Box sx={{
                    width: '420px',
                    height: '164px',
                    bgcolor: bgColor,
                    p: '24px',
                    color: textColor,
                    position: 'relative',
                    borderTopLeftRadius: '24px',
                    borderTopRightRadius: '24px',
                    overflow: 'hidden'
                }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            {settings?.showLogo ? (
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                    <Box
                                        component="img"
                                        src={settings.logoUrl || (assetsUrl + 'default-logo.png')}
                                        alt="Logo"
                                        sx={{ height: 36, objectFit: 'contain', maxWidth: 192, display: 'block' }}
                                    />
                                </Box>
                            ) : (
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                    <Typography sx={{ fontSize: '18px', fontWeight: 700, lineHeight: 1 }}>
                                {settings.logoText || __('Reward Program', 'mycred')}
                                    </Typography>
                                </Box>
                            )}
                        </Box>
                        <IconButton size="small" sx={{ color: textColor }}>
                            <CloseIcon />
                        </IconButton>
                    </Box>
                </Box>

                {/* Main Content Card (Center Box) */}
                <Paper
                    elevation={0}
                    sx={{
                        width: '372px',
                        height: '334px',
                        borderRadius: '12px',
                        bgcolor: '#fff',
                        boxShadow: '0px 8px 16px -8px #EDE8FF', // Updated shadow
                        position: 'absolute',
                        top: '108px',
                        left: '24px',
                        overflow: 'hidden',
                        zIndex: 1
                    }}
                >
                    {/* Welcome Text */}
                    <Box sx={{
                        position: 'absolute',
                        top: '28px',
                        left: '24px',
                        right: '24px',
                        textAlign: 'center'
                    }}>
                        <Typography
                            sx={{
                                fontSize: '14px',
                                fontWeight: 600,
                                color: textColor,
                                fontFamily: "'Instrument Sans', sans-serif",
                                lineHeight: '20px',
                                display: 'inline'
                            }}
                        >
                            {isGuest ? (currentContent.welcomeMessage || __('Welcome! Sign up to start earning rewards', 'mycred')) : (currentContent.welcomeMessage || __('Welcome back! Keep earning rewards', 'mycred'))}
                        </Typography>
                    </Box>

                    <TrophyIllustration color={btnColor} />

                    <Button
                        variant="contained"
                        sx={{
                            width: '324px',
                            height: '48px',
                            position: 'absolute',
                            top: '224px',
                            left: '24px',
                            bgcolor: btnColor,
                            color: btnTextColor,
                            textTransform: 'none',
                            px: '24px',
                            py: '12px',
                            borderRadius: '8px',
                            fontSize: '14px',
                            fontWeight: 600,
                            gap: '8px',
                            fontFamily: "'Instrument Sans', sans-serif",
                            '&:hover': {
                                bgcolor: btnColor,
                                opacity: 0.9
                            }
                        }}
                    >
                        <LoginIcon sx={{ width: 24, height: 24, color: 'inherit' }} />
                        {isGuest ? (currentContent.joinButtonText || __('Join Now', 'mycred')) : (currentContent.dashboardButtonText || __('Dashboard', 'mycred'))}
                    </Button>

                    <Box sx={{
                        position: 'absolute',
                        top: '286px',
                        left: '0',
                        right: '0',
                        textAlign: 'center'
                    }}>
                        <Typography
                            sx={{
                                fontSize: '14px',
                                fontWeight: 400,
                                color: hexToRgba(textColor, 0.7), // Updated color
                                fontFamily: "'Instrument Sans', sans-serif",
                                lineHeight: '20px',
                                display: 'inline'
                            }}
                        >
                            {isGuest ? __('Already have an account? ', 'mycred') : ''}
                        </Typography>
                        {isGuest && (
                            <Typography
                                sx={{
                                    fontSize: '14px',
                                    fontWeight: 600,
                                    color: btnColor,
                                    fontFamily: "'Instrument Sans', sans-serif",
                                    lineHeight: '20px',
                                    display: 'inline',
                                    cursor: 'pointer'
                                }}
                            >
                                {currentContent.loginButtonText || __('Sign in', 'mycred')}
                            </Typography>
                        )}
                    </Box>
                </Paper>

                {/* Navigation Grid (Positioned below the main card) */}
                <Box sx={{
                    position: 'absolute',
                    top: '454px',
                    left: '24px',
                    width: '372px',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '12px'
                }}>
                    <Box sx={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(3, 1fr)',
                        columnGap: '12px',
                        rowGap: '12px',
                        width: '100%'
                    }}>
                        {(settings.tabControls?.earn !== false) && <NavButton svgSrc={assetsUrl + 'earn-icon.svg'} label={currentContent.earnLabel || __('Earn', 'mycred')} color={btnColor} textColor={btnTextColor} />}
                        {(settings.tabControls?.redeem !== false && isPro) && <NavButton svgSrc={assetsUrl + 'redeem-icon.svg'} label={currentContent.redeemLabel || __('Redeem', 'mycred')} color={btnColor} textColor={btnTextColor} />}
                        {(settings.tabControls?.board !== false) && <NavButton svgSrc={assetsUrl + 'board-icon.svg'} label={currentContent.boardLabel || __('Board', 'mycred')} color={btnColor} textColor={btnTextColor} />}
                        {(settings.tabControls?.logs !== false) && <NavButton svgSrc={assetsUrl + 'logs-icon.svg'} label={currentContent.logsLabel || __('History', 'mycred')} color={btnColor} textColor={btnTextColor} />}
                        {(settings.tabControls?.profile !== false) && <NavButton svgSrc={assetsUrl + 'profile-icon.svg'} label={currentContent.profileLabel || __('Profile', 'mycred')} color={btnColor} textColor={btnTextColor} />}
                        {(settings.tabControls?.ranks !== false) && <NavButton icon={LeaderboardIcon} label={currentContent.ranksLabel || __('Ranks', 'mycred')} color={btnColor} textColor={btnTextColor} />}
                        {(settings.tabControls?.badges !== false) && <NavButton icon={EmojiEventsIcon} label={currentContent.badgesLabel || __('Badges', 'mycred')} color={btnColor} textColor={btnTextColor} />}
                    </Box>
                </Box>

                {/* Footer Branding */}
                {settings.showBranding !== false && (
                    <Box sx={{
                        position: 'absolute',
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: '50px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        bgcolor: '#F8F6FF',
                        borderTop: '1px solid #ECE7FF'
                    }}>
                        <Typography sx={{
                            fontSize: '12px',
                            color: hexToRgba(textColor, 0.6),
                            fontFamily: "'Instrument Sans', sans-serif"
                        }}>
                            {__('Powered by ', 'mycred')}
                            <Box component="span" sx={{ fontWeight: 600 }}>
                                {__('myCred', 'mycred')}
                            </Box>
                        </Typography>
                    </Box>
                )}
            </Box>

            {/* Launcher Button Preview (Now visible!) */}
            <Box
                key={settings.launcherAnimation} // Force re-mount to trigger animation on change
                sx={{
                    position: 'absolute',
                    bottom: '10px',
                    right: '0',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '12px',
                    zIndex: 2,
                    animation: getAnimation()
                }}
            >
                {/* Launcher Pill */}
                <Box sx={{
                    height: '48px',
                    px: '20px',
                    bgcolor: bgColor,
                    color: textColor,
                    borderRadius: `${settings.launcherRadius || 45}px`,
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                    cursor: 'pointer',
                    transition: '0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    '&:hover': { transform: 'scale(1.02)' }
                }}>
                    {settings?.showLogo ? (
                        <Box
                            component="img"
                            src={settings.logoUrl || (assetsUrl + 'default-logo.png')}
                            alt="Logo"
                            sx={{ height: 24, objectFit: 'contain', maxWidth: 100 }}
                        />
                    ) : (
                        <Typography sx={{ fontSize: '14px', fontWeight: 700, whiteSpace: 'nowrap' }}>
                            {settings.logoText || __('Rewards Hub', 'mycred')}
                        </Typography>
                    )}
                </Box>

                {/* Close Launcher Button */}
                <Box sx={{
                    width: '48px',
                    height: '48px',
                    bgcolor: bgColor,
                    color: textColor,
                    borderRadius: '50%',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                    cursor: 'pointer'
                }}>
                    <CloseIcon sx={{ fontSize: 24 }} />
                </Box>
            </Box>
        </Box>
    );
};

export default WidgetPreview;

