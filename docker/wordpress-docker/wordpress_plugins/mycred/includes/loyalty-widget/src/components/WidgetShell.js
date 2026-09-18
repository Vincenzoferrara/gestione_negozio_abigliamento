import { Box, Typography } from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import { __ } from '@wordpress/i18n';
import { getThemeColors, getAnimationKeyframes, animationStyles, MYCRED_BRANDING_URL } from './preview/utils';

export const getAssetsUrl = () => window.mycredLoyaltyWidget?.assets_url || window.mycredLoyaltyWidgetData?.assets_url || '';

export default function WidgetShell({
    design = {},
    children,
    showFooter = true,
    showLauncher = true,
    launcherOpen = true,
    containerRadius = 24,
}) {
    const bgColor = design.backgroundColor || '#2D1572';
    const textColor = design.textColor || '#FFFFFF';
    const theme = getThemeColors(design);
    const borderRadius = design.borderRadius ?? 8;
    const assetsUrl = getAssetsUrl();
    const animation = getAnimationKeyframes(design.launcherAnimation || 'none');

    return (
        <Box sx={{ position: 'relative', pb: showLauncher ? '74px' : 0, ...animationStyles }}>
            <Box
                key={`widget-${design.launcherAnimation}`}
                sx={{
                    width: '420px',
                    height: '652px',
                    bgcolor: '#F8F6FF',
                    borderRadius: `${containerRadius}px`,
                    boxShadow: '0px 16px 32px 0px rgba(230, 225, 250, 0.5)',
                    overflow: 'hidden',
                    fontFamily: "'Instrument Sans', sans-serif",
                    position: 'relative',
                    animation,
                    border: `1px solid ${theme.footerBorder}`,
                    display: 'flex',
                    flexDirection: 'column',
                }}
            >
                <Box sx={{ flex: 1, overflow: 'hidden', position: 'relative', minHeight: 0, display: 'flex', flexDirection: 'column' }}>
                    {children}
                </Box>

                {showFooter && design.showBranding !== false && (
                    <Box sx={{
                        height: '50px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        bgcolor: '#F8F6FF',
                        borderTop: `1px solid ${theme.footerBorder}`,
                        flexShrink: 0,
                    }}>
                        <Box sx={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 0.75,
                            bgcolor: 'rgba(0, 0, 0, 0.05)',
                            px: 1.5,
                            py: 0.75,
                            borderRadius: '100px',
                            transition: 'all 0.2s',
                            '&:hover': {
                                bgcolor: 'rgba(0, 0, 0, 0.08)',
                            }
                        }}>
                            <Typography sx={{ fontSize: '12px', color: '#555', fontFamily: "'Instrument Sans', sans-serif", fontWeight: 500 }}>
                                {__('Powered by', 'mycred')}
                            </Typography>
                            <Box
                                component="a"
                                href={MYCRED_BRANDING_URL}
                                target="_blank"
                                rel="noopener noreferrer"
                                sx={{
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: 0.5,
                                    fontWeight: 700,
                                    color: '#1a1a1a',
                                    textDecoration: 'none',
                                    fontSize: '13px',
                                    fontFamily: "'Instrument Sans', sans-serif",
                                }}
                            >
                                {__('myCred', 'mycred')}
                            </Box>
                        </Box>
                    </Box>
                )}
            </Box>

            {showLauncher && launcherOpen && (
                <Box
                    key={design.launcherAnimation}
                    sx={{
                        position: 'absolute',
                        bottom: '10px',
                        right: 0,
                        display: 'flex',
                        alignItems: 'center',
                        gap: '12px',
                        zIndex: 2,
                        animation,
                    }}
                >
                    <Box sx={{
                        height: '48px',
                        px: '20px',
                        bgcolor: bgColor,
                        color: textColor,
                        borderRadius: `${design.launcherRadius ?? 45}px`,
                        display: 'flex',
                        alignItems: 'center',
                        gap: '10px',
                        boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                        cursor: 'pointer',
                        '@keyframes shakeKeyframe': {
                            '0%, 100%': { transform: 'translateX(0) rotate(0deg)' },
                            '15%': { transform: 'translateX(-4px) rotate(-2deg)' },
                            '30%': { transform: 'translateX(4px) rotate(2deg)' },
                            '45%': { transform: 'translateX(-3px) rotate(-1.5deg)' },
                            '60%': { transform: 'translateX(3px) rotate(1.5deg)' },
                            '75%': { transform: 'translateX(-2px) rotate(-1deg)' },
                            '90%': { transform: 'translateX(2px) rotate(1deg)' },
                        },
                        '&:hover': {
                            animation: 'shakeKeyframe 0.45s ease-in-out',
                        },
                    }}>
                        {design.showLogo && (
                            <Box component="img" src={design.logoUrl || (assetsUrl + 'widget-logo.png')} alt="Logo" sx={{ height: 24, objectFit: 'contain', maxWidth: 100 }} />
                        )}
                        <Typography sx={{ fontSize: '14px', fontWeight: 700, whiteSpace: 'nowrap', color: textColor }}>
                            {design.logoText || __('Rewards Hub', 'mycred')}
                        </Typography>
                    </Box>
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
                    }}>
                        <CloseIcon sx={{ fontSize: 24 }} />
                    </Box>
                </Box>
            )}
        </Box>
    );
}
