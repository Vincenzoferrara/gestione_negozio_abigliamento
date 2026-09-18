import { useState, useEffect, useMemo } from '@wordpress/element';
import { Box, Typography, CircularProgress, IconButton, Paper } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CloseIcon from '@mui/icons-material/Close';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { getRanks } from '../services/frontend-api';
import { __, sprintf } from '@wordpress/i18n';

export default function Ranks({ settings, currentContent, user, onBack, onClose, previewMode = false, previewData }) {
    currentContent = currentContent || {};
    const isRtl = document?.documentElement?.dir === 'rtl';
    
    // Get unique point types from localized data
    const availableTypes = useMemo(() => {
        const types = window.mycredLoyaltyWidget?.point_types || {};
        if (Object.keys(types).length === 0) {
            types['mycred_default'] = __('Points', 'mycred');
        }
        return types;
    }, []);

    const pointTypeKeys = Object.keys(availableTypes);

    const [ranks, setRanks]             = useState([]);
    const [pointLabel, setPointLabel]   = useState(__('Points', 'mycred'));
    const [loading, setLoading]         = useState(true);
    const [isOpen, setIsOpen]           = useState(false);
    const [pointType, setPointType]     = useState(pointTypeKeys[0] || 'mycred_default');

    const design    = settings.design || {};
    const btnColor  = design.buttonColor  || '#5E2CED';
    const bgColor   = design.backgroundColor || '#2D1572';

    useEffect(() => {
        if (previewMode) {
            setRanks(previewData || []);
            setLoading(false);
            return;
        }

        setLoading(true);
        getRanks(pointType)
            .then(res => { 
                if (res.success) {
                    setRanks(res.data);
                    if (res.point_label) setPointLabel(res.point_label);
                }
            })
            .catch(console.error)
            .finally(() => setLoading(false));
    }, [pointType, previewMode, previewData]);

    // Find if user has a rank
    const currentRankIndex = ranks.findIndex(r => r.is_current);

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
                            {currentContent.ranksMessage || __('Ranks', 'mycred')}
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

                {/* ── Point Type Switcher (If multiple) ───────────────── */}
                {pointTypeKeys.length > 1 && (
                    <Box sx={{ position: 'relative', mb: '20px' }}>
                        <Box
                            onClick={() => setIsOpen(!isOpen)}
                            sx={{
                                height: '44px',
                                borderRadius: '12px',
                                bgcolor: '#fff',
                                border: '1px solid',
                                borderColor: isOpen ? btnColor : '#E8E8F0',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'space-between',
                                px: '14px',
                                cursor: 'pointer',
                                boxShadow: isOpen ? `0 0 0 3px ${btnColor}22` : '0px 2px 6px rgba(0,0,0,0.04)',
                                transition: 'all 0.2s',
                                userSelect: 'none',
                            }}
                        >
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                {/* Coin icon placeholder */}
                                <Box sx={{
                                    width: '20px', height: '20px', borderRadius: '50%',
                                    bgcolor: `${btnColor}22`,
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                }}>
                                    <Box sx={{
                                        width: '10px', height: '10px', borderRadius: '50%',
                                        bgcolor: btnColor,
                                    }} />
                                </Box>
                                <Typography sx={{
                                    fontSize: '14px',
                                    fontWeight: 500,
                                    color: btnColor,
                                    fontFamily: "'Instrument Sans', sans-serif",
                                }}>
                                    {availableTypes[pointType] || __('Points', 'mycred')}
                                </Typography>
                            </Box>
                            {/* Chevron */}
                            <Box sx={{
                                transform: isOpen ? 'rotate(180deg)' : 'rotate(0deg)',
                                transition: 'transform 0.2s',
                                display: 'flex',
                                alignItems: 'center',
                            }}>
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                                    <path d="M6 9l6 6 6-6" stroke={btnColor} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                                </svg>
                            </Box>
                        </Box>

                        {/* Dropdown Menu */}
                        {isOpen && (
                            <Paper sx={{
                                position: 'absolute',
                                top: '50px',
                                left: 0,
                                right: 0,
                                zIndex: 100,
                                borderRadius: '12px',
                                overflow: 'hidden',
                                boxShadow: '0px 10px 30px rgba(0,0,0,0.1)',
                                border: '1px solid #F0F0F0',
                            }}>
                                {pointTypeKeys.map((key) => (
                                    <Box
                                        key={key}
                                        onClick={() => {
                                            setPointType(key);
                                            setIsOpen(false);
                                        }}
                                        sx={{
                                            p: '12px 16px',
                                            cursor: 'pointer',
                                            display: 'flex',
                                            alignItems: 'center',
                                            gap: '10px',
                                            bgcolor: pointType === key ? 'rgba(94,44,237,0.05)' : '#fff',
                                            '&:hover': { bgcolor: 'rgba(94,44,237,0.08)' },
                                            transition: 'background-color 0.2s',
                                        }}
                                    >
                                        <Box sx={{
                                            width: '8px', height: '8px', borderRadius: '50%',
                                            bgcolor: pointType === key ? btnColor : '#D8D8E8'
                                        }} />
                                        <Typography sx={{
                                            fontSize: '14px',
                                            fontWeight: pointType === key ? 600 : 400,
                                            color: pointType === key ? btnColor : '#444',
                                            fontFamily: "'Instrument Sans', sans-serif",
                                        }}>
                                            {availableTypes[key]}
                                        </Typography>
                                    </Box>
                                ))}
                            </Paper>
                        )}
                    </Box>
                )}

                {/* Loading */}
                {loading && (
                    <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
                        <CircularProgress size={28} sx={{ color: btnColor }} />
                    </Box>
                )}

                {/* Empty */}
                {!loading && ranks.length === 0 && (
                    <Box sx={{ textAlign: 'center', py: 8 }}>
                        <Typography sx={{ fontSize: '32px', mb: 1 }}>🎖️</Typography>
                        <Typography sx={{ fontSize: '14px', color: '#888', fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('No ranks found.', 'mycred')}
                        </Typography>
                    </Box>
                )}

                {/* Rank Timeline UI */}
                {!loading && ranks.length > 0 && (
                    <Paper elevation={0} sx={{ 
                        borderRadius: '20px', 
                        bgcolor: '#fff', 
                        overflow: 'hidden',
                        boxShadow: '0px 2px 12px rgba(0,0,0,0.06)'
                    }}>
                        <Box sx={{ px: '16px', py: '20px', position: 'relative' }}>
                            {ranks.map((rank, idx) => {
                                const isEarned = currentRankIndex !== -1 && idx <= currentRankIndex;
                                const isCurrent = rank.is_current;
                                const isLast = idx === ranks.length - 1;
                                const circleColor = isEarned ? btnColor : '#D8D8E8';

                                return (
                                    <Box key={rank.id} sx={{ display: 'flex', gap: '14px', position: 'relative' }}>
                                        
                                        {/* Left col: Image + Line */}
                                        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0, width: '56px' }}>
                                            <Box sx={{
                                                width: 56, height: 56, borderRadius: '50%',
                                                border: `2.5px solid ${circleColor}`,
                                                bgcolor: isEarned ? `${btnColor}08` : '#F4F5F8',
                                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                position: 'relative', overflow: 'hidden'
                                            }}>
                                                {rank.image_url ? (
                                                    <Box component="img" src={rank.image_url} alt={rank.title} sx={{
                                                        width: '100%', height: '100%', objectFit: 'cover',
                                                        filter: isEarned ? 'none' : 'grayscale(100%)',
                                                        opacity: isEarned ? 1 : 0.5
                                                    }} />
                                                ) : (
                                                    <Typography sx={{ fontSize: '24px', opacity: isEarned ? 1 : 0.5 }}>🏆</Typography>
                                                )}
                                                
                                                {/* Ensure checkmark is visible for earned ranks */}
                                                {isEarned && (
                                                    <Box sx={{
                                                        position: 'absolute', bottom: -2, right: -2,
                                                        bgcolor: '#fff', borderRadius: '50%',
                                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                    }}>
                                                        <CheckCircleIcon sx={{ fontSize: '16px', color: '#10B981', bgcolor: '#fff', borderRadius: '50%' }} />
                                                    </Box>
                                                )}
                                            </Box>

                                            {/* Connector line */}
                                            {!isLast && (
                                                <Box sx={{
                                                    width: '2px', flex: 1, minHeight: '34px',
                                                    bgcolor: (currentRankIndex !== -1 && idx < currentRankIndex) ? btnColor : '#EBEBF2',
                                                    my: '4px',
                                                    borderRadius: '4px'
                                                }} />
                                            )}
                                        </Box>

                                        {/* Right col: Info */}
                                        <Box sx={{ flex: 1, pb: isLast ? 0 : '24px', pt: '6px' }}>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: '8px', mb: '4px' }}>
                                                {isCurrent && (
                                                    <Box sx={{ px: '8px', py: '3px', bgcolor: `${btnColor}15`, borderRadius: '6px' }}>
                                                        <Typography sx={{ fontSize: '10px', fontWeight: 800, color: btnColor, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                                            {__('Current Rank', 'mycred')}
                                                        </Typography>
                                                    </Box>
                                                )}
                                                {isEarned && !isCurrent && (
                                                    <Box sx={{ px: '8px', py: '3px', bgcolor: '#F0FDF4', borderRadius: '6px' }}>
                                                        <Typography sx={{ fontSize: '10px', fontWeight: 800, color: '#16A34A', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                                            {__('Unlocked', 'mycred')}
                                                        </Typography>
                                                    </Box>
                                                )}
                                                {!isEarned && (
                                                    <Box sx={{ px: '8px', py: '3px', bgcolor: '#F4F5F8', borderRadius: '6px' }}>
                                                        <Typography sx={{ fontSize: '10px', fontWeight: 800, color: '#7A7A9A', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                                            {__('Locked', 'mycred')}
                                                        </Typography>
                                                    </Box>
                                                )}
                                            </Box>
                                            
                                            <Typography sx={{
                                                fontSize: '16px', fontWeight: 800, color: isEarned ? btnColor : '#8A8A9A',
                                                fontFamily: "'Instrument Sans', sans-serif", mb: '4px'
                                            }}>
                                                {rank.title}
                                            </Typography>
                                            
                                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
                                                <Typography sx={{ fontSize: '12px', color: '#7A7A9A', fontFamily: "'Instrument Sans', sans-serif" }}>
                                                    {sprintf(__('Minimum %s:', 'mycred'), pointLabel)} <strong style={{ color: isEarned ? btnColor : '#8A8A9A' }}>{rank.minimum}</strong>
                                                </Typography>
                                                {rank.maximum && (
                                                    <Typography sx={{ fontSize: '12px', color: '#7A7A9A', fontFamily: "'Instrument Sans', sans-serif" }}>
                                                        {sprintf(__('Maximum %s:', 'mycred'), pointLabel)} <strong style={{ color: isEarned ? btnColor : '#8A8A9A' }}>{rank.maximum}</strong>
                                                    </Typography>
                                                )}
                                            </Box>
                                        </Box>
                                    </Box>
                                );
                            })}
                        </Box>
                    </Paper>
                )}
            </Box>
        </Box>
    );
}
