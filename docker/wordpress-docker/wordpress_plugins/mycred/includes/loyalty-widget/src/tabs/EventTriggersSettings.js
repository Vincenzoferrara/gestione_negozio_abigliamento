import { useState } from '@wordpress/element';
import {
    Box,
    Typography,
    Paper,
    Button,
    Tabs,
    Tab,
    Accordion,
    AccordionSummary,
    AccordionDetails,
} from '@mui/material';
import { __ } from '@wordpress/i18n';
import FlashOnIcon from '@mui/icons-material/FlashOn';
import InfoOutlinedIcon from '@mui/icons-material/InfoOutlined';
import SaveIcon from '@mui/icons-material/Save';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { saveSectionSettings } from '../services/api';
import { toast } from 'react-hot-toast';
import ToggleSwitch from '../components/admin/ToggleSwitch';

const SectionHeader = ({ icon: Icon, title, desc }) => (
    <Box sx={{ mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
            <Icon sx={{ color: '#5E2CED', fontSize: 20 }} />
            <Typography sx={{ fontSize: '18px', fontWeight: 600, color: '#1a1a1a' }}>{title}</Typography>
        </Box>
        {desc && <Typography sx={{ fontSize: '14px', color: '#666' }}>{desc}</Typography>}
    </Box>
);

const HookItem = ({ title, description, checked, onChange, displayLabel, onLabelChange, pointTypeLabel, isPro }) => {

    return (
        <Box sx={{
            border: '1px solid #E0E0E0',
            borderRadius: '8px',
            p: 2,
            mb: 2,
            bgcolor: checked ? '#F8F6FF' : '#fff'
        }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <Box sx={{ flex: 1 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                        <Typography sx={{ fontWeight: 600, fontSize: '15px', color: '#1a1a1a' }}>
                            {title}
                        </Typography>
                        <Typography
                            sx={{
                                fontSize: '12px',
                                color: '#5E2CED',
                                bgcolor: '#F0EBFF',
                                px: 1,
                                py: 0.25,
                                borderRadius: '4px',
                                fontWeight: 600
                            }}
                        >
                            {pointTypeLabel || __('Points', 'mycred')}
                        </Typography>
                    </Box>
                    <Typography sx={{ fontSize: '13px', color: '#666', mb: 2 }}>
                        {description}
                    </Typography>

                    {checked && (
                        <Box sx={{ mt: 2, pl: 0, opacity: !isPro ? 0.7 : 1 }}>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                                <Typography sx={{ fontSize: '12px', fontWeight: 700, color: '#1a1a1a', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                    {__('Display Label in Widget', 'mycred')}
                                </Typography>
                                {!isPro && (
                                    <Box sx={{
                                        bgcolor: '#F5F3FF',
                                        color: '#5E2CED',
                                        fontSize: '10px',
                                        fontWeight: 700,
                                        px: 1,
                                        py: 0.25,
                                        borderRadius: '4px',
                                        textTransform: 'uppercase',
                                        border: '1px solid #DDD6FE'
                                    }}>
                                        {__('Pro', 'mycred')}
                                    </Box>
                                )}
                            </Box>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                <Box sx={{
                                    flex: 1,
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: 1.5,
                                    bgcolor: !isPro ? '#f9f9f9' : '#fff',
                                    border: '1px solid #E0E0E0',
                                    borderRadius: '8px',
                                    px: 2,
                                    py: 1,
                                    cursor: !isPro ? 'not-allowed' : 'default'
                                }}>
                                    <Box
                                        component="input"
                                        value={displayLabel || ''}
                                        onChange={(e) => isPro && onLabelChange(e.target.value)}
                                        placeholder={!isPro ? __('Upgrade to Pro to customize label', 'mycred') : __('Enter custom label...', 'mycred')}
                                        disabled={!isPro}
                                        sx={{
                                            border: 'none',
                                            outline: 'none',
                                            fontSize: '14px',
                                            width: '100%',
                                            px: 2,
                                            py: 1.2,
                                            fontFamily: 'inherit',
                                            bgcolor: 'transparent',
                                            cursor: !isPro ? 'not-allowed' : 'text',
                                            '&::placeholder': { color: '#ccc' }
                                        }}
                                    />
                                </Box>
                            </Box>
                        </Box>
                    )}
                </Box>
                <ToggleSwitch checked={checked} onChange={onChange} />
            </Box>
        </Box>
    );
};


export default function EventTriggersSettings() {
    const isPro = window.mycredLoyaltyWidgetData?.is_toolkit_pro_active || false;
    const initialTriggers = window.mycredLoyaltyWidgetData?.settings?.eventtriggers || {};
    const activeHooksData = window.mycredLoyaltyWidgetData?.active_hooks || [];

    // Extract unique point types
    const availablePointTypes = [
        { id: 'all', label: __('All Type', 'mycred') },
        ...Array.from(new Set(activeHooksData.map(h => JSON.stringify({ id: h.point_type, label: h.type_label }))))
            .map(s => JSON.parse(s))
    ];

    const [selectedPointType, setSelectedPointType] = useState('all');
    const [enableHooks, setEnableHooks] = useState(initialTriggers.enableHooks !== undefined ? initialTriggers.enableHooks : true);
    const [loading, setLoading] = useState(false);

    // Filtered hooks based on dynamic data
    const [wordpressHooks, setWordpressHooks] = useState(() => {
        const saved = initialTriggers.wordpressHooks || [];
        return activeHooksData.filter(h => h.category === 'wordpress').map(hook => {
            const savedHook = saved.find(s => String(s.id) === String(hook.id) && String(s.point_type) === String(hook.point_type));
            return {
                ...hook,
                enabled: savedHook ? savedHook.enabled : true,
                displayLabel: savedHook ? savedHook.displayLabel : (hook.raw_title || hook.title)
            };
        });
    });

    const [woocommerceHooks, setWoocommerceHooks] = useState(() => {
        const saved = initialTriggers.woocommerceHooks || [];
        return activeHooksData.filter(h => h.category === 'woocommerce').map(hook => {
            const savedHook = saved.find(s => String(s.id) === String(hook.id) && String(s.point_type) === String(hook.point_type));
            return {
                ...hook,
                enabled: savedHook ? savedHook.enabled : true,
                displayLabel: savedHook ? savedHook.displayLabel : (hook.raw_title || hook.title)
            };
        });
    });


    const [buddypressHooks, setBuddypressHooks] = useState(() => {
        const saved = initialTriggers.buddypressHooks || [];
        return activeHooksData.filter(h => h.category === 'buddypress').map(hook => {
            const savedHook = saved.find(s => String(s.id) === String(hook.id) && String(s.point_type) === String(hook.point_type));
            return {
                ...hook,
                enabled: savedHook ? savedHook.enabled : true,
                displayLabel: savedHook ? savedHook.displayLabel : (hook.raw_title || hook.title)
            };
        });
    });

    const [forumHooks, setForumHooks] = useState(() => {
        const saved = initialTriggers.forumHooks || [];
        return activeHooksData.filter(h => h.category === 'forum').map(hook => {
            const savedHook = saved.find(s => String(s.id) === String(hook.id) && String(s.point_type) === String(hook.point_type));
            return {
                ...hook,
                enabled: savedHook ? savedHook.enabled : true,
                displayLabel: savedHook ? savedHook.displayLabel : (hook.raw_title || hook.title)
            };
        });
    });

    const handleHookChange = (category, hookId, pointType, enabled) => {
        const setters = {
            wordpress: setWordpressHooks,
            woocommerce: setWoocommerceHooks,
            buddypress: setBuddypressHooks,
            forum: setForumHooks
        };

        setters[category](prev => prev.map(hook =>
            (hook.id === hookId && hook.point_type === pointType) ? { ...hook, enabled } : hook
        ));
    };

    const handleLabelChange = (category, hookId, pointType, displayLabel) => {
        const setters = {
            wordpress: setWordpressHooks,
            woocommerce: setWoocommerceHooks,
            buddypress: setBuddypressHooks,
            forum: setForumHooks
        };

        setters[category](prev => prev.map(hook =>
            (hook.id === hookId && hook.point_type === pointType) ? { ...hook, displayLabel } : hook
        ));
    };


    const handleSave = async () => {
        setLoading(true);
        try {
            const dataToSave = {
                enableHooks,
                wordpressHooks,
                woocommerceHooks,
                buddypressHooks,
                forumHooks
            };
            const response = await saveSectionSettings('eventtriggers', dataToSave);
            if (response.success) {
                toast.success(__('Settings saved successfully!', 'mycred'));
                console.log('Settings saved:', response.message);
            } else {
                toast.error(response.message || __('Failed to save settings', 'mycred'));
            }
        } catch (error) {
            console.error('Failed to save settings:', error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <Box sx={{ p: 4 }}>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                {/* myCred Hooks */}
                <Accordion
                    defaultExpanded
                    sx={{
                        borderRadius: '12px !important',
                        boxShadow: 'none',
                        border: '1px solid #E0E0E0',
                        '&:before': { display: 'none' }
                    }}
                >
                    <AccordionSummary
                        expandIcon={<ExpandMoreIcon />}
                        sx={{ px: 3, py: 1 }}
                    >
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                            <FlashOnIcon sx={{ color: '#5E2CED', fontSize: 20 }} />
                            <Box>
                                <Typography sx={{ fontSize: '18px', fontWeight: 600, color: '#1a1a1a' }}>
                                    {__('myCred Hooks', 'mycred')}
                                </Typography>
                                <Typography sx={{ fontSize: '13px', color: '#666' }}>
                                    {__('Enable automatic point rewards based on user actions.', 'mycred')}
                                </Typography>
                            </Box>
                        </Box>
                    </AccordionSummary>
                    <AccordionDetails sx={{ px: 3, pb: 3, pt: 0 }}>
                        <Box sx={{ mb: 3, pb: 3, borderBottom: '1px solid #E0E0E0' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <Box>
                                    <Typography sx={{ fontWeight: 600, fontSize: '15px', color: '#1a1a1a' }}>
                                        {__('Show Triggers in widget', 'mycred')}
                                    </Typography>
                                    <Typography sx={{ fontSize: '13px', color: '#666', mt: 0.5 }}>
                                        {__('Select which myCred Hooks to display in the loyalty widget', 'mycred')}
                                    </Typography>
                                </Box>
                                <ToggleSwitch
                                    checked={enableHooks}
                                    onChange={(e) => setEnableHooks(e.target.checked)}
                                />
                            </Box>
                        </Box>

                        {enableHooks && (
                            <Box>
                                {availablePointTypes.length > 2 && (
                                    <Tabs
                                        value={selectedPointType}
                                        onChange={(e, val) => setSelectedPointType(val)}
                                        sx={{
                                            mb: 3,
                                            borderBottom: '1px solid #E0E0E0',
                                            '& .MuiTabs-indicator': { backgroundColor: '#5E2CED' },
                                            '& .MuiTab-root': {
                                                textTransform: 'none',
                                                fontWeight: 600,
                                                fontSize: '14px',
                                                color: '#666',
                                                minWidth: 'auto',
                                                px: 3,
                                                '&.Mui-selected': { color: '#5E2CED' }
                                            }
                                        }}
                                    >
                                        {availablePointTypes.map(type => (
                                            <Tab key={type.id} label={type.label} value={type.id} />
                                        ))}
                                    </Tabs>
                                )}

                                {[['wordpress', wordpressHooks, __('myCred Hooks', 'mycred')], 
                                  ['woocommerce', woocommerceHooks, __('WooCommerce Hooks', 'mycred')], 
                                  ['buddypress', buddypressHooks, __('BuddyPress Hooks', 'mycred')], 
                                  ['forum', forumHooks, __('Forum Hooks', 'mycred')]]
                                    .filter(([cat, hooks]) => hooks.filter(h => selectedPointType === 'all' || h.point_type === selectedPointType).length > 0)
                                    .map(([cat, hooks, catLabel]) => (
                                        <Box key={cat} sx={{ mb: 4 }}>
                                            <Typography sx={{ fontSize: '15px', fontWeight: 600, color: '#5E2CED', mb: 2 }}>
                                                {catLabel}
                                            </Typography>
                                            {hooks
                                                .filter(h => selectedPointType === 'all' || h.point_type === selectedPointType)
                                                .map((hook) => (
                                                    <HookItem
                                                        key={`${hook.id}-${hook.point_type}`}
                                                        title={hook.title}
                                                        description={hook.description}
                                                        checked={hook.enabled}
                                                        onChange={(e) => handleHookChange(cat, hook.id, hook.point_type, e.target.checked)}
                                                        displayLabel={hook.displayLabel}
                                                        onLabelChange={(val) => handleLabelChange(cat, hook.id, hook.point_type, val)}
                                                        pointTypeLabel={hook.type_label}
                                                        isPro={isPro}
                                                    />
                                                ))}
                                        </Box>
                                    ))}
                            </Box>
                        )}
                    </AccordionDetails>
                </Accordion>

                {/* Save Button */}
                <Box sx={{ mt: 3 }}>
                    <Button
                        variant="contained"
                        startIcon={<SaveIcon />}
                        onClick={handleSave}
                        disabled={loading}
                        sx={{
                            bgcolor: '#5E2CED',
                            color: '#fff',
                            textTransform: 'none',
                            px: 4,
                            py: 1.25,
                            fontSize: '14px',
                            fontWeight: 600,
                            borderRadius: '8px',
                            '&:hover': {
                                bgcolor: '#4E1CDD',
                            }
                        }}
                    >
                        {loading ? __('Saving...', 'mycred') : __('Save Settings', 'mycred')}
                    </Button>
                </Box>
            </Box>
        </Box>
    );
}
