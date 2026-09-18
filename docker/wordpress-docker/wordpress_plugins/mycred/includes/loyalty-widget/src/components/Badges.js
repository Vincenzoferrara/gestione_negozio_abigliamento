import { useState, useEffect } from '@wordpress/element';
import { Box, Typography, CircularProgress, IconButton } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CloseIcon from '@mui/icons-material/Close';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { getBadges } from '../services/frontend-api';
import { __ } from '@wordpress/i18n';

export default function Badges({ settings, currentContent, onBack, onClose, previewMode = false, previewData }) {
    currentContent = currentContent || {};
    const isRtl = document?.documentElement?.dir === 'rtl';
    const [badges, setBadges] = useState([]);
    const [loading, setLoading] = useState(true);

    const design    = settings.design || {};
    const btnColor  = design.buttonColor  || '#5E2CED';
    const bgColor   = design.backgroundColor || '#2D1572';

    useEffect(() => {
        if (previewMode) {
            setBadges(previewData || []);
            setLoading(false);
            return;
        }

        getBadges()
            .then(res => { if (res.success) setBadges(res.data); })
            .catch(console.error)
            .finally(() => setLoading(false));
    }, [previewMode, previewData]);

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: bgColor }}>

            {/* ── Header ────────────────────────────────────────── */}
            <Box sx={{ p: '20px 24px', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <IconButton size="small" onClick={onBack} sx={{ color: '#fff', p: 0.5 }}>
                        <ArrowBackIcon sx={{ transform: isRtl ? 'scaleX(-1)' : 'none' }} />
                    </IconButton>
                    <Box>
                        <Typography sx={{ fontSize: '18px', fontWeight: 700, fontFamily: "'Instrument Sans', sans-serif" }}>
                            {currentContent.badgesMessage || __('Badges', 'mycred')}
                        </Typography>
                    </Box>
                </Box>
                <IconButton size="small" onClick={onClose} sx={{ color: '#fff' }}>
                    <CloseIcon />
                </IconButton>
            </Box>

            {/* ── Body ──────────────────────────────────────────── */}
            <Box sx={{
                flex: 1,
                bgcolor: '#F4F5F8',
                borderRadius: '24px 24px 0 0',
                overflowY: 'auto',
                p: '20px 16px',
                scrollbarWidth: 'none',
                '&::-webkit-scrollbar': { display: 'none' },
            }}>

                {/* Loading */}
                {loading && (
                    <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
                        <CircularProgress size={28} sx={{ color: btnColor }} />
                    </Box>
                )}

                {/* Empty */}
                {!loading && badges.length === 0 && (
                    <Box sx={{ textAlign: 'center', py: 8 }}>
                        <Typography sx={{ fontSize: '32px', mb: 1 }}>🏆</Typography>
                        <Typography sx={{ fontSize: '14px', color: '#888', fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('No badges found.', 'mycred')}
                        </Typography>
                    </Box>
                )}

                {/* Badge List */}
                {!loading && badges.map((badgeItem) => (
                    <Box
                        key={badgeItem.id}
                        sx={{
                            bgcolor: '#fff',
                            borderRadius: '20px',
                            mb: '16px',
                            overflow: 'hidden',
                            boxShadow: '0px 2px 12px rgba(0,0,0,0.06)',
                        }}
                    >
                        {/* Badge title bar */}
                        <Box sx={{
                            px: '20px',
                            py: '14px',
                            borderBottom: '1px solid #F0F0F8',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '10px',
                        }}>
                            {/* Badge main image */}
                            {badgeItem.levels?.[0]?.image_url && (
                                <Box
                                    component="img"
                                    src={badgeItem.levels[0].image_url}
                                    alt={badgeItem.title}
                                    sx={{ width: 32, height: 32, objectFit: 'contain', borderRadius: '8px' }}
                                />
                            )}
                            <Typography sx={{
                                fontSize: '15px',
                                fontWeight: 800,
                                color: btnColor,
                                textTransform: 'uppercase',
                                letterSpacing: '0.5px',
                                fontFamily: "'Instrument Sans', sans-serif",
                            }}>
                                {badgeItem.title}
                            </Typography>
                        </Box>

                        {/* Levels timeline */}
                        <Box sx={{ px: '16px', py: '12px', position: 'relative' }}>
                            {(badgeItem.levels || []).map((level, lvlIndex) => {
                                const isLast    = lvlIndex === (badgeItem.levels.length - 1);
                                const isEarned  = level.is_earned;
                                const circleColor = isEarned ? btnColor : '#D8D8E8';

                                return (
                                    <Box key={lvlIndex} sx={{ display: 'flex', gap: '14px', position: 'relative' }}>

                                        {/* ── Left column: circle + connector line ── */}
                                        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0, width: '52px' }}>
                                            {/* Badge image circle */}
                                            <Box sx={{
                                                width: 52,
                                                height: 52,
                                                borderRadius: '50%',
                                                border: `2.5px solid ${circleColor}`,
                                                bgcolor: isEarned ? `${btnColor}10` : '#F4F5F8',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                flexShrink: 0,
                                                position: 'relative',
                                                overflow: 'hidden',
                                            }}>
                                                {level.image_url ? (
                                                    <Box
                                                        component="img"
                                                        src={level.image_url}
                                                        alt={level.label}
                                                        sx={{
                                                            width: '100%',
                                                            height: '100%',
                                                            objectFit: 'cover',
                                                            filter: isEarned ? 'none' : 'grayscale(100%)',
                                                            opacity: isEarned ? 1 : 0.45,
                                                        }}
                                                    />
                                                ) : (
                                                    <Typography sx={{ fontSize: '22px' }}>🏅</Typography>
                                                )}

                                                {/* Earned checkmark badge */}
                                                {isEarned && (
                                                    <Box sx={{
                                                        position: 'absolute',
                                                        bottom: -2,
                                                        right: -2,
                                                        bgcolor: '#fff',
                                                        borderRadius: '50%',
                                                        lineHeight: 0,
                                                    }}>
                                                        <CheckCircleIcon sx={{ fontSize: 16, color: btnColor }} />
                                                    </Box>
                                                )}
                                            </Box>

                                            {/* Vertical connector line */}
                                            {!isLast && (
                                                <Box sx={{
                                                    flex: 1,
                                                    width: '2px',
                                                    my: '4px',
                                                    minHeight: '24px',
                                                    bgcolor: isEarned ? `${btnColor}40` : '#E4E4F0',
                                                    borderRadius: '1px',
                                                }} />
                                            )}
                                        </Box>

                                        {/* ── Right column: text content ── */}
                                        <Box sx={{ flex: 1, pb: isLast ? '8px' : '20px', pt: '4px' }}>
                                            {/* Level number small tag */}
                                            <Typography sx={{
                                                fontSize: '11px',
                                                fontWeight: 600,
                                                color: isEarned ? btnColor : '#A0A0B8',
                                                fontFamily: "'Instrument Sans', sans-serif",
                                                textTransform: 'uppercase',
                                                letterSpacing: '0.4px',
                                                mb: '2px',
                                            }}>
                                                {__('Level', 'mycred')} {lvlIndex + 1}
                                            </Typography>

                                            {/* Level name */}
                                            <Typography sx={{
                                                fontSize: '15px',
                                                fontWeight: 700,
                                                color: isEarned ? btnColor : '#8888A8',
                                                fontFamily: "'Instrument Sans', sans-serif",
                                                mb: '6px',
                                            }}>
                                                {level.label}
                                            </Typography>

                                            {/* Requirements */}
                                            {level.requirements && level.requirements.length > 0 && (
                                                <Box sx={{ mb: '8px' }}>
                                                    {level.requirements.map((req, rIdx) => (
                                                        <Box key={rIdx} sx={{ display: 'flex', alignItems: 'flex-start', gap: '6px', mb: '3px' }}>
                                                            <Box sx={{
                                                                width: 5, height: 5,
                                                                borderRadius: '50%',
                                                                bgcolor: isEarned ? btnColor : '#B0B0C8',
                                                                mt: '6px',
                                                                flexShrink: 0,
                                                            }} />
                                                            <Typography sx={{
                                                                fontSize: '12px',
                                                                color: isEarned ? '#4A4468' : '#A0A0B8',
                                                                fontFamily: "'Instrument Sans', sans-serif",
                                                                lineHeight: 1.5,
                                                            }}>
                                                                {req}
                                                            </Typography>
                                                        </Box>
                                                    ))}
                                                </Box>
                                            )}

                                            {/* Reward / Benefits row */}
                                            {level.reward_text && (
                                                <Box sx={{
                                                    display: 'inline-flex',
                                                    alignItems: 'center',
                                                    gap: '6px',
                                                    bgcolor: isEarned ? '#FFF5EC' : '#F4F5F8',
                                                    borderRadius: '8px',
                                                    px: '10px',
                                                    py: '5px',
                                                    mt: '2px',
                                                }}>
                                                    <Typography sx={{
                                                        fontSize: '11px',
                                                        fontWeight: 700,
                                                        color: isEarned ? '#E07000' : '#A0A0B8',
                                                        textTransform: 'uppercase',
                                                        letterSpacing: '0.3px',
                                                        fontFamily: "'Instrument Sans', sans-serif",
                                                    }}>
                                                        {__('Benefits', 'mycred')}
                                                    </Typography>
                                                    <Box sx={{ width: '1px', height: '12px', bgcolor: isEarned ? '#FFCF96' : '#D0D0E0' }} />
                                                    <Typography sx={{
                                                        fontSize: '12px',
                                                        fontWeight: 700,
                                                        color: isEarned ? btnColor : '#A0A0B8',
                                                        fontFamily: "'Instrument Sans', sans-serif",
                                                    }}>
                                                        {level.reward_text}
                                                    </Typography>
                                                </Box>
                                            )}
                                        </Box>
                                    </Box>
                                );
                            })}
                        </Box>
                    </Box>
                ))}
            </Box>
        </Box>
    );
}
