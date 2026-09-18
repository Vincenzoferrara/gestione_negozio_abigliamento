import { Box, Typography, Paper } from '@mui/material';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';

export const MYCRED_BRANDING_URL = 'https://mycred.me/?utm_source=plugin&utm_medium=mycred-loyaltywidget';

export const hexToRgba = (hex, opacity) => {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result
        ? `rgba(${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(result[3], 16)}, ${opacity})`
        : hex;
};

/** Light panel tint from accent on white — keeps tab bodies readable on dark headers. */
export const blendWithWhite = (hex, ratio = 0.06) => {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (!result) return '#F8F6FF';
    const mix = (ch) => Math.round(parseInt(ch, 16) * ratio + 255 * (1 - ratio));
    return `rgb(${mix(result[1])}, ${mix(result[2])}, ${mix(result[3])})`;
};

/** Design tokens for widget surfaces (header vs light cards/footer). */
export const getThemeColors = (design = {}) => {
    const accent = design.buttonColor || '#5E2CED';
    const surface = design.backgroundColor || '#2D1572';
    const headerText = design.textColor || '#FFFFFF';

    return {
        accent,
        surface,
        headerText,
        surfaceText: surface,
        surfaceMuted: hexToRgba(surface, 0.65),
        accentMuted: hexToRgba(accent, 0.65),
        accentSoft: hexToRgba(accent, 0.08),
        accentSoftBg: hexToRgba(accent, 0.05),
        accentBorder: hexToRgba(accent, 0.35),
        accentBorderLight: hexToRgba(accent, 0.12),
        borderSoft: hexToRgba(surface, 0.12),
        footerText: hexToRgba(surface, 0.55),
        footerBorder: hexToRgba(surface, 0.1),
        panelBg: blendWithWhite(accent, 0.06),
    };
};

export const getRankStyle = (rankName, accent = '#5E2CED') => {
    if (!rankName || typeof rankName !== 'string') {
        return { bg: hexToRgba(accent, 0.12), text: accent };
    }
    const lower = rankName.toLowerCase();
    if (lower.includes('gold')) return { bg: '#FEF0AE', text: '#8B6713' };
    if (lower.includes('silver')) return { bg: '#E6E6E6', text: '#555555' };
    if (lower.includes('bronze')) return { bg: '#FDE4BA', text: '#8C3D27' };
    return { bg: hexToRgba(accent, 0.12), text: accent };
};

export const themedSvgIconSx = (src, size = 20) => ({
    width: size,
    height: size,
    bgcolor: 'currentColor',
    maskImage: `url(${src})`,
    maskRepeat: 'no-repeat',
    maskPosition: 'center',
    maskSize: 'contain',
    WebkitMaskImage: `url(${src})`,
    WebkitMaskRepeat: 'no-repeat',
    WebkitMaskPosition: 'center',
    WebkitMaskSize: 'contain',
    flexShrink: 0,
});

export const getAnimationKeyframes = (type) => {
    if (type === 'none') return 'none';
    return `${type}Keyframe 0.5s cubic-bezier(0.4, 0, 0.2, 1) forwards`;
};

export const animationStyles = {
    '@keyframes fadeKeyframe': {
        '0%': { opacity: 0 },
        '100%': { opacity: 1 },
    },
    '@keyframes slideKeyframe': {
        '0%': { transform: 'translateY(20px)', opacity: 0 },
        '100%': { transform: 'translateY(0)', opacity: 1 },
    },
    '@keyframes zoomKeyframe': {
        '0%': { transform: 'scale(0.5)', opacity: 0 },
        '100%': { transform: 'scale(1)', opacity: 1 },
    },
};

export const NavButton = ({ icon: Icon, label, color, textColor, svgSrc, active, onClick, layout = 'grid', borderRadius = 12 }) => {
    const isList = layout === 'list';

    return (
        <Paper
            elevation={0}
            onClick={onClick}
            sx={{
                width: '100%',
                height: isList ? '52px' : '44px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: isList ? 'flex-start' : 'center',
                gap: '8px',
                px: isList ? '16px' : 0,
                borderRadius: `${borderRadius}px`,
                bgcolor: active ? color : '#fff',
                color: active ? textColor : color,
                cursor: onClick ? 'pointer' : 'default',
                border: active ? `1px solid ${color}` : `1px solid ${hexToRgba(color || '#5E2CED', 0.15)}`,
                boxShadow: `0px 8px 16px -8px ${hexToRgba(color || '#5E2CED', 0.12)}`,
                transition: '0.2s',
                '&:hover': onClick ? {
                    bgcolor: active ? color : hexToRgba(color || '#5E2CED', 0.04),
                    borderColor: color || '#5E2CED',
                } : {},
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
                        flexShrink: 0,
                    }}
                />
            ) : Icon ? (
                <Icon sx={{ color: 'inherit', fontSize: 20, flexShrink: 0 }} />
            ) : null}
            <Typography sx={{ fontSize: '14px', fontWeight: 600, color: 'inherit', fontFamily: "'Instrument Sans', sans-serif", flex: isList ? 1 : 'unset' }}>
                {label}
            </Typography>
            {isList && <ChevronRightIcon sx={{ fontSize: 18, opacity: 0.5 }} />}
        </Paper>
    );
};

export const TrophyIllustration = ({ assetsUrl, size = 90, top = '68px', left = '141px' }) => (
    <Box
        component="img"
        src={assetsUrl + 'trophy.svg'}
        alt="Trophy"
        sx={{ width: size, height: size, position: 'absolute', top, left }}
    />
);

/** Brand image/GIF above Join/Dashboard CTA; falls back to trophy (classic/cards) or nothing (luxury inline). */
export const HeroIllustration = ({
    heroImageUrl,
    assetsUrl,
    variant = 'absolute',
    size = 90,
    top = '68px',
    left = '141px',
}) => {
    if (heroImageUrl) {
        if (variant === 'inline') {
            return (
                <Box sx={{ display: 'flex', justifyContent: 'center' }}>
                    <Box
                        component="img"
                        src={heroImageUrl}
                        alt=""
                        sx={{ width: size, height: size, maxWidth: '100%', objectFit: 'contain' }}
                    />
                </Box>
            );
        }
        return (
            <Box
                component="img"
                src={heroImageUrl}
                alt=""
                sx={{ width: size, height: size, objectFit: 'contain', position: 'absolute', top, left }}
            />
        );
    }

    if (variant === 'inline') {
        return null;
    }

    return <TrophyIllustration assetsUrl={assetsUrl} size={size} top={top} left={left} />;
};
