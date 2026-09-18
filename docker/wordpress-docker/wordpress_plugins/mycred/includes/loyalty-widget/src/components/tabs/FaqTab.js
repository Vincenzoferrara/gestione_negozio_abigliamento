import { useState } from '@wordpress/element';
import {
    Box,
    Typography,
    IconButton,
    Accordion,
    AccordionSummary,
    AccordionDetails,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CloseIcon from '@mui/icons-material/Close';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import HelpOutlineIcon from '@mui/icons-material/HelpOutline';
import { __ } from '@wordpress/i18n';
import { hexToRgba } from '../preview/utils';

export default function FaqTab({ settings, onBack, onClose }) {
    const design = settings?.design || {};
    const faq = settings?.faq || {};
    const isRtl = document?.documentElement?.dir === 'rtl';
    const bgColor = design.backgroundColor || '#1A1A1A';
    const textColor = design.textColor || '#FFFFFF';
    const btnColor = design.buttonColor || '#8B6F47';
    const screenTitle = faq.screenTitle || __('FAQs', 'mycred');
    const items = Array.isArray(faq.items) ? faq.items.filter((i) => i?.title || i?.answer) : [];
    const [expanded, setExpanded] = useState(false);

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: '#F8F8F8' }}>
            <Box
                sx={{
                    p: '18px 20px',
                    bgcolor: bgColor,
                    color: textColor,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    flexShrink: 0,
                    borderRadius: '24px 24px 0 0',
                }}
            >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <IconButton
                        size="small"
                        onClick={onBack}
                        sx={{
                            color: textColor,
                            p: 0.5,
                            bgcolor: 'rgba(255,255,255,0.14)',
                            '&:hover': { bgcolor: 'rgba(255,255,255,0.24)' },
                        }}
                    >
                        <ArrowBackIcon fontSize="small" sx={{ transform: isRtl ? 'scaleX(-1)' : 'none' }} />
                    </IconButton>
                    <Typography sx={{ fontSize: 18, fontWeight: 700, fontFamily: "'Instrument Sans', sans-serif", letterSpacing: '-0.02em' }}>
                        {screenTitle}
                    </Typography>
                </Box>
                <IconButton size="small" onClick={onClose} sx={{ color: textColor }}>
                    <CloseIcon />
                </IconButton>
            </Box>

            <Box sx={{ flex: 1, overflowY: 'auto', p: '16px' }}>
                {items.length === 0 ? (
                    <Box
                        sx={{
                            mt: 4,
                            textAlign: 'center',
                            px: 2,
                        }}
                    >
                        <Box
                            sx={{
                                width: 64,
                                height: 64,
                                borderRadius: '20px',
                                bgcolor: hexToRgba(btnColor, 0.12),
                                color: btnColor,
                                display: 'inline-flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                mb: 2,
                            }}
                        >
                            <HelpOutlineIcon sx={{ fontSize: 32 }} />
                        </Box>
                        <Typography sx={{ fontSize: 16, fontWeight: 700, color: btnColor, mb: 1, fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('No FAQs yet', 'mycred')}
                        </Typography>
                        <Typography sx={{ fontSize: 13, color: '#888', lineHeight: 1.5, fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('Check back soon for answers to common questions.', 'mycred')}
                        </Typography>
                    </Box>
                ) : (
                    items.map((item, index) => (
                        <Accordion
                            key={item.id || index}
                            disableGutters
                            elevation={0}
                            expanded={expanded === (item.id || index)}
                            onChange={(_, isExpanded) => setExpanded(isExpanded ? (item.id || index) : false)}
                            sx={{
                                mb: 1.25,
                                borderRadius: '14px !important',
                                bgcolor: '#fff',
                                border: '1px solid rgba(0,0,0,0.05)',
                                boxShadow: '0 4px 14px rgba(0,0,0,0.05)',
                                overflow: 'hidden',
                                '&:before': { display: 'none' },
                            }}
                        >
                            <AccordionSummary
                                expandIcon={<ExpandMoreIcon sx={{ color: btnColor }} />}
                                sx={{
                                    px: 2,
                                    py: 0.5,
                                    minHeight: 56,
                                    '& .MuiAccordionSummary-content': { my: 1.25 },
                                }}
                            >
                                <Typography sx={{ fontSize: 14, fontWeight: 600, color: btnColor, pr: 1, fontFamily: "'Instrument Sans', sans-serif", lineHeight: 1.35 }}>
                                    {item.title || __('Untitled question', 'mycred')}
                                </Typography>
                            </AccordionSummary>
                            <AccordionDetails sx={{ px: 2, pb: 2, pt: 0 }}>
                                <Typography
                                    sx={{
                                        fontSize: 13,
                                        color: '#666',
                                        lineHeight: 1.55,
                                        whiteSpace: 'pre-wrap',
                                        fontFamily: "'Instrument Sans', sans-serif",
                                    }}
                                >
                                    {item.answer || __('—', 'mycred')}
                                </Typography>
                            </AccordionDetails>
                        </Accordion>
                    ))
                )}
            </Box>
        </Box>
    );
}
