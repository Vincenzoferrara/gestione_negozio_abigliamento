import { Box, Typography, Paper, IconButton } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CloseIcon from '@mui/icons-material/Close';
import { __ } from '@wordpress/i18n';

export default function EarnTab({ settings, currentContent, user, activeHooks, onBack, onClose }) {
    currentContent = currentContent || {};
    const isRtl = document?.documentElement?.dir === 'rtl';
    const eventtriggers = settings.eventtriggers || {};
    const design = settings.design || {};
    const btnColor = design.buttonColor || '#5E2CED';
    const bgColor = design.backgroundColor || '#2D1572';

    const getHookLabel = (hook) => {
        const cat = hook.category ? `${hook.category}Hooks` : 'wordpressHooks';
        let label = hook.title;

        if (settings.eventtriggers && settings.eventtriggers[cat] && Array.isArray(settings.eventtriggers[cat])) {
            const match = settings.eventtriggers[cat].find(h => String(h.id) === String(hook.id) && String(h.point_type) === String(hook.point_type));
            if (match && match.displayLabel) {
                label = match.displayLabel;
            }
        }

        if (label) {
            label = label.replace(/%plural%/g, hook.plural || __('points', 'mycred'));
            label = label.replace(/%singular%/g, hook.singular || __('point', 'mycred'));
        }

        return label;
    };

    const isHookEnabled = (hook) => {
        const categories = ['wordpressHooks', 'woocommerceHooks', 'buddypressHooks', 'forumHooks'];
        for (const cat of categories) {
            if (eventtriggers[cat] && Array.isArray(eventtriggers[cat])) {
                const match = eventtriggers[cat].find(h => String(h.id) === String(hook.id) && String(h.point_type) === String(hook.point_type));
                if (match) {
                    return match.enabled !== false;
                }
            }
        }
        return true;
    };

    const filteredHooks = (activeHooks || []).filter(hook => isHookEnabled(hook));

    if (eventtriggers.enableHooks === false) {
        return (
            <Box sx={{ p: 4, textAlign: 'center' }}>
                <Typography sx={{ color: '#666' }}>{__('No earning opportunities available at the moment.', 'mycred')}</Typography>
            </Box>
        );
    }

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: bgColor }}>
            <Box sx={{ p: '20px 24px', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <IconButton size="small" onClick={onBack} sx={{ color: '#fff', p: 0.5 }}>
                        <ArrowBackIcon sx={{ transform: isRtl ? 'scaleX(-1)' : 'none' }} />
                    </IconButton>
                    <Box>
                        <Typography sx={{ fontSize: '18px', fontWeight: 700 }}>
                            {currentContent.earnMessage || __('Earn', 'mycred')}
                        </Typography>
                    </Box>
                </Box>
                <IconButton size="small" onClick={onClose} sx={{ color: '#fff' }}>
                    <CloseIcon />
                </IconButton>
            </Box>

            <Box sx={{
                flex: 1, bgcolor: '#F8F9FB', borderRadius: '24px 24px 0 0', p: '20px', overflowY: 'auto',
                scrollbarWidth: 'none', '&::-webkit-scrollbar': { display: 'none' }
            }}>
                {filteredHooks.length > 0 && (
                    <Typography sx={{ fontSize: '12px', fontWeight: 600, color: '#666', mb: 2, textTransform: 'uppercase' }}>
                        {__('All Challenges', 'mycred')}
                    </Typography>
                )}

                <Box sx={{
                    display: 'flex', flexDirection: 'column', gap: 2,
                    '& > *': {
                        animation: 'slideKeyframe 0.5s cubic-bezier(0.16, 1, 0.3, 1) both',
                    },
                    ...Array.from({ length: 15 }).reduce((acc, _, i) => ({
                        ...acc,
                        [`& > *:nth-of-type(${i + 1})`]: { animationDelay: `${i * 0.05}s` }
                    }), {})
                }}>
                    {filteredHooks.map((hook, index) => (
                        <Paper
                            key={`${hook.id}-${hook.point_type}-${index}`}
                            elevation={0}
                            sx={{
                                p: 2,
                                borderRadius: '12px',
                                border: '1px solid #E8E8E8',
                                bgcolor: '#fff'
                            }}
                        >
                            <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                                <Box sx={{
                                    width: 40,
                                    height: 40,
                                    borderRadius: '10px',
                                    bgcolor: `${btnColor}22`,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    flexShrink: 0
                                }}>
                                    <Typography sx={{ fontSize: '20px' }}>⭐</Typography>
                                </Box>
                                <Box sx={{ flex: 1 }}>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, color: btnColor, mb: 0.5 }}>
                                        {getHookLabel(hook)}
                                    </Typography>
                                    <Typography sx={{ fontSize: '12px', color: '#666' }}>
                                        {__('Earn points by participating', 'mycred')}
                                    </Typography>
                                </Box>
                                <Typography sx={{
                                    fontSize: '14px',
                                    fontWeight: 700,
                                    color: String(hook.formatted_amount || hook.amount || '0').startsWith('-') ? '#EF4444' : '#38A169',
                                    whiteSpace: 'nowrap',
                                    bgcolor: String(hook.formatted_amount || hook.amount || '0').startsWith('-') ? '#FEE2E2' : 'transparent',
                                    px: String(hook.formatted_amount || hook.amount || '0').startsWith('-') ? '8px' : 0,
                                    py: String(hook.formatted_amount || hook.amount || '0').startsWith('-') ? '2px' : 0,
                                    borderRadius: '100px'
                                }}>
                                    {(String(hook.formatted_amount || hook.amount || '0').startsWith('-') || String(hook.formatted_amount || hook.amount || '0').startsWith('+')) ? '' : '+'}{hook.formatted_amount || hook.amount || '0'} {user?.all_balances?.find(b => b.type === hook.point_type)?.label || user?.point_label || ''}
                                </Typography>
                            </Box>
                        </Paper>
                    ))}

                    {filteredHooks.length === 0 && (
                        <Box sx={{ textAlign: 'center', py: 4 }}>
                            <Typography sx={{ color: '#666', fontSize: '14px' }}>
                                {__('No earning opportunities available at the moment.', 'mycred')}
                            </Typography>
                        </Box>
                    )}
                </Box>
            </Box>
        </Box>
    );
}
