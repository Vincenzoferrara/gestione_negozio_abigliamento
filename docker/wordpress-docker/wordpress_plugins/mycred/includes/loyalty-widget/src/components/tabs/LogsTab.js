import { useState, useEffect } from '@wordpress/element';
import { Box, Typography, IconButton, Skeleton, Chip } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CloseIcon from '@mui/icons-material/Close';
import LoginIcon from '@mui/icons-material/Login';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import CommentIcon from '@mui/icons-material/Comment';
import ShareIcon from '@mui/icons-material/Share';
import ThumbUpIcon from '@mui/icons-material/ThumbUp';
import { __ } from '@wordpress/i18n';
import { getLogs } from '../../services/frontend-api';

export default function LogsTab({ settings, currentContent, user, onBack, onClose, previewMode = false, previewData }) {
    currentContent = currentContent || {};
    const isRtl = document?.documentElement?.dir === 'rtl';
    const [logs, setLogs] = useState([]);
    const [pointLabel, setPointLabel] = useState(__('Points', 'mycred'));
    const [loading, setLoading] = useState(true);
    const [selectedType, setSelectedType] = useState('mycred_default');

    const design = settings.design || {};
    const btnColor = design.buttonColor || '#5E2CED';
    const bgColor = design.backgroundColor || '#2D1572';

    useEffect(() => {
        if (previewMode) {
            setLogs(previewData || []);
            setLoading(false);
            return;
        }

        const fetchLogs = async () => {
            setLoading(true);
            try {
                const response = await getLogs(selectedType);
                if (response.success) {
                    setLogs(response.data);
                    if (response.point_label) setPointLabel(response.point_label);
                }
            } catch (error) {
                console.error('Failed to fetch logs:', error);
            } finally {
                setLoading(false);
            }
        };
        fetchLogs();
    }, [selectedType, previewMode, previewData]);

    const getIcon = (type, reason) => {
        const lowerReason = (reason || '').toLowerCase();
        if (lowerReason.includes('register') || lowerReason.includes('signup')) return <PersonAddIcon sx={{ color: '#fff', fontSize: 20 }} />;
        if (lowerReason.includes('comment')) return <CommentIcon sx={{ color: '#fff', fontSize: 20 }} />;
        if (lowerReason.includes('share')) return <ShareIcon sx={{ color: '#fff', fontSize: 20 }} />;
        if (lowerReason.includes('like')) return <ThumbUpIcon sx={{ color: '#fff', fontSize: 20 }} />;
        return <LoginIcon sx={{ color: '#fff', fontSize: 20 }} />;
    };

    if (!user?.is_logged_in) {
        return (
            <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: '#fff' }}>
                <Box sx={{
                    p: '20px 24px',
                    bgcolor: btnColor,
                    color: '#fff',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    borderRadius: '24px 24px 0 0',
                    position: 'relative',
                    flexShrink: 0
                }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <IconButton size="small" onClick={onBack} sx={{ color: '#fff', p: 0.5, bgcolor: 'rgba(255,255,255,0.1)', '&:hover': { bgcolor: 'rgba(255,255,255,0.2)' } }}>
                            <ArrowBackIcon fontSize="small" sx={{ transform: isRtl ? 'scaleX(-1)' : 'none' }} />
                        </IconButton>
                        <Box sx={{ lineHeight: 1 }}>
                            <Typography sx={{ fontSize: '18px', fontWeight: 600, fontFamily: "'Instrument Sans', sans-serif" }}>
                                {currentContent.logsMessage || __('Point History', 'mycred')}
                            </Typography>
                        </Box>
                    </Box>
                    <IconButton size="small" onClick={onClose} sx={{ color: '#fff' }}>
                        <CloseIcon />
                    </IconButton>
                </Box>
                <Box sx={{ flex: 1, bgcolor: '#F8F9FB', p: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Typography sx={{ textAlign: 'center', color: '#666', fontFamily: "'Instrument Sans', sans-serif" }}>
                        {__('Please log in to view your activity.', 'mycred')}
                    </Typography>
                </Box>
            </Box>
        );
    }

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: '#fff' }}>
            {/* Header */}
            <Box sx={{
                p: '20px 24px',
                bgcolor: bgColor,
                color: '#fff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                borderRadius: '24px 24px 0 0',
                position: 'relative',
                flexShrink: 0
            }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <IconButton size="small" onClick={onBack} sx={{ color: '#fff', p: 0.5 }}>
                        <ArrowBackIcon fontSize="small" sx={{ transform: isRtl ? 'scaleX(-1)' : 'none' }} />
                    </IconButton>
                    <Typography sx={{ fontSize: '18px', fontWeight: 600, fontFamily: "'Instrument Sans', sans-serif", mt: 0.5 }}>
                        {currentContent.logsMessage || __('Point History', 'mycred')}
                    </Typography>
                </Box>
                <IconButton size="small" onClick={onClose} sx={{ color: '#fff' }}>
                    <CloseIcon />
                </IconButton>
            </Box>

            <Box sx={{ 
                p: '16px 24px 0', 
                bgcolor: '#F8F9FB',
                display: 'flex',
                gap: '8px',
                overflowX: 'auto',
                scrollbarWidth: 'none',
                '&::-webkit-scrollbar': { display: 'none' },
                flexShrink: 0
            }}>
                {user.all_balances?.map((b) => (
                    <Chip
                        key={b.type}
                        label={b.label}
                        onClick={() => setSelectedType(b.type)}
                        sx={{
                            bgcolor: selectedType === b.type ? btnColor : 'rgba(94, 44, 237, 0.05)',
                            color: selectedType === b.type ? '#fff' : btnColor,
                            fontWeight: 600,
                            fontFamily: "'Instrument Sans', sans-serif",
                            '&:hover': {
                                bgcolor: selectedType === b.type ? btnColor : 'rgba(94, 44, 237, 0.1)',
                            }
                        }}
                    />
                ))}
            </Box>

            {/* Content */}
            <Box sx={{
                flex: 1,
                bgcolor: '#F8F9FB', // Light background for content area
                p: '16px 24px 24px',
                overflowY: 'auto',
                scrollbarWidth: 'none',
                '&::-webkit-scrollbar': { display: 'none' },
                display: 'flex',
                flexDirection: 'column',
                gap: '12px'
            }}>

                {loading ? (
                    [1, 2, 3, 4, 5].map((i) => (
                        <Box key={i} sx={{ mb: 2 }}>
                            <Skeleton variant="rectangular" height={82} sx={{ borderRadius: '12px' }} />
                        </Box>
                    ))
                ) : (
                    <>
                        {logs.map((log) => (
                            <Box
                                key={log.id}
                                sx={{
                                    minHeight: '82px',
                                    borderRadius: '12px',
                                    border: '1px solid #ECE7FF',
                                    bgcolor: '#fff',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'space-between',
                                    px: '16px',
                                    py: '12px',
                                    gap: '12px',
                                    flexShrink: 0
                                }}
                            >
                                {/* Icon & Text Content */}
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: '10px', flex: 1, minWidth: 0 }}>
                                    <Box sx={{
                                        width: 40,
                                        height: 40,
                                        borderRadius: '6px',
                                        bgcolor: `${btnColor}22`,
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        flexShrink: 0
                                    }}>
                                        {getIcon(log.type, log.reason)}
                                    </Box>

                                    <Box sx={{ flex: 1, minWidth: 0 }}>
                                        <Typography sx={{
                                            fontSize: '15px',
                                            fontWeight: 600,
                                            color: btnColor,
                                            fontFamily: "'Instrument Sans', sans-serif",
                                            lineHeight: 1.2,
                                            mb: 0.5,
                                            wordBreak: 'break-word'
                                        }}>
                                            {log.reason}
                                        </Typography>
                                        <Typography sx={{
                                            fontSize: '11px',
                                            color: '#563BA1',
                                            fontFamily: "'Instrument Sans', sans-serif",
                                            letterSpacing: '0.24px'
                                        }}>
                                            {log.date}
                                        </Typography>
                                    </Box>
                                </Box>

                                <Box sx={{
                                    bgcolor: (String(log.amount).startsWith('-') || log.type === 'debit') ? '#FEE2E2' : '#F0FDF4',
                                    borderRadius: '100px',
                                    px: '10px',
                                    py: '4px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    flexShrink: 0
                                }}>
                                    <Typography sx={{
                                        fontSize: '12px',
                                        fontWeight: 600,
                                        color: (String(log.amount).startsWith('-') || log.type === 'debit') ? '#EF4444' : '#16A34A',
                                        fontFamily: "'Instrument Sans', sans-serif",
                                        lineHeight: 1
                                    }}>
                                        {(log.type === 'credit' && !String(log.amount).startsWith('-') && !String(log.amount).startsWith('+')) ? '+' : ''}{log.amount} {pointLabel}
                                    </Typography>
                                </Box>
                            </Box>
                        ))}

                        {logs.length === 0 && (
                            <Box sx={{ textAlign: 'center', py: 4 }}>
                                <Typography sx={{ color: '#666', fontFamily: "'Instrument Sans', sans-serif" }}>
                                    {__('No activity found yet.', 'mycred')}
                                </Typography>
                            </Box>
                        )}
                    </>
                )}
            </Box>
        </Box>
    );
}
