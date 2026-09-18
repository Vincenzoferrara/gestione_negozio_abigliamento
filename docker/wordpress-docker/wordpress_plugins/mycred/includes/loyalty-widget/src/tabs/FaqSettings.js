import { useState } from '@wordpress/element';
import {
    Box,
    Typography,
    TextField,
    Button,
    Paper,
    IconButton,
} from '@mui/material';
import { __ } from '@wordpress/i18n';
import HelpOutlineIcon from '@mui/icons-material/HelpOutline';
import AddIcon from '@mui/icons-material/Add';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import SaveIcon from '@mui/icons-material/Save';
import { toast } from 'react-hot-toast';
import { usePreviewSettings } from '../context/PreviewSettingsContext';
import { saveSectionSettings } from '../services/api';

const SectionHeader = ({ icon: Icon, title, desc }) => (
    <Box sx={{ mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
            <Icon sx={{ color: '#5E2CED', fontSize: 20 }} />
            <Typography sx={{ fontSize: '18px', fontWeight: 600, color: '#1a1a1a' }}>{title}</Typography>
        </Box>
        {desc && <Typography sx={{ fontSize: '14px', color: '#666' }}>{desc}</Typography>}
    </Box>
);

const createFaqId = () => `faq_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

export default function FaqSettings() {
    const { faq, setFaq, updateFaq } = usePreviewSettings();
    const [loading, setLoading] = useState(false);

    const items = Array.isArray(faq?.items) ? faq.items : [];
    const screenTitle = faq?.screenTitle || __('FAQs', 'mycred');

    const handleTitleChange = (value) => {
        updateFaq({ screenTitle: value });
    };

    const handleItemChange = (id, field, value) => {
        updateFaq({
            items: items.map((item) => (item.id === id ? { ...item, [field]: value } : item)),
        });
    };

    const handleAdd = () => {
        if (items.length >= 20) {
            toast.error(__('You can add up to 20 FAQs.', 'mycred'));
            return;
        }
        updateFaq({
            items: [
                ...items,
                { id: createFaqId(), title: '', answer: '' },
            ],
        });
    };

    const handleRemove = (id) => {
        updateFaq({
            items: items.filter((item) => item.id !== id),
        });
    };

    const handleSave = async () => {
        setLoading(true);
        try {
            const payload = {
                screenTitle: screenTitle || __('FAQs', 'mycred'),
                items: items
                    .map((item) => ({
                        id: item.id || createFaqId(),
                        title: (item.title || '').trim(),
                        answer: (item.answer || '').trim(),
                    }))
                    .filter((item) => item.title || item.answer),
            };
            const response = await saveSectionSettings('faq', payload);
            if (response.success) {
                setFaq(payload);
                if (window.mycredLoyaltyWidgetData) {
                    if (!window.mycredLoyaltyWidgetData.settings) window.mycredLoyaltyWidgetData.settings = {};
                    window.mycredLoyaltyWidgetData.settings.faq = payload;
                }
                toast.success(__('Settings saved successfully!', 'mycred'));
            } else {
                toast.error(response.message || __('Failed to save settings', 'mycred'));
            }
        } catch (error) {
            console.error('Failed to save FAQ settings:', error);
            toast.error(__('Failed to save settings', 'mycred'));
        } finally {
            setLoading(false);
        }
    };

    return (
        <Box sx={{ p: 4, maxWidth: 720 }}>
            <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0', mb: 3 }}>
                <SectionHeader
                    icon={HelpOutlineIcon}
                    title={__('FAQs', 'mycred')}
                    desc={__('Shown on the Modern template as a header pill. Visitors open a dedicated FAQ screen.', 'mycred')}
                />

                <Typography sx={{ fontSize: 14, fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                    {__('Screen title', 'mycred')}
                </Typography>
                <TextField
                    fullWidth
                    size="small"
                    value={screenTitle}
                    onChange={(e) => handleTitleChange(e.target.value)}
                    placeholder={__('FAQs', 'mycred')}
                    sx={{
                        mb: 3,
                        '& .MuiOutlinedInput-root': {
                            borderRadius: '8px',
                            height: '40px',
                            '&.Mui-focused fieldset': { borderColor: '#5E2CED' },
                        },
                    }}
                />

                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    {items.length === 0 && (
                        <Box
                            sx={{
                                p: 3,
                                borderRadius: '12px',
                                bgcolor: '#F8F6FF',
                                border: '1px dashed #D9D0FF',
                                textAlign: 'center',
                            }}
                        >
                            <Typography sx={{ fontSize: 14, color: '#666' }}>
                                {__('No FAQs yet. Add your first question below.', 'mycred')}
                            </Typography>
                        </Box>
                    )}

                    {items.map((item, index) => (
                        <Paper
                            key={item.id || index}
                            sx={{
                                p: 2.5,
                                borderRadius: '12px',
                                boxShadow: 'none',
                                border: '1px solid #E8E4F5',
                                bgcolor: '#fff',
                            }}
                        >
                            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1.5 }}>
                                <Typography sx={{ fontSize: 13, fontWeight: 700, color: '#5E2CED' }}>
                                    {__('FAQ', 'mycred')} #{index + 1}
                                </Typography>
                                <IconButton size="small" onClick={() => handleRemove(item.id)} aria-label={__('Remove FAQ', 'mycred')}>
                                    <DeleteOutlineIcon sx={{ fontSize: 20, color: '#999' }} />
                                </IconButton>
                            </Box>
                            <Typography sx={{ fontSize: 13, fontWeight: 600, mb: 0.75, color: '#1a1a1a' }}>
                                {__('Question', 'mycred')}
                            </Typography>
                            <TextField
                                fullWidth
                                size="small"
                                value={item.title || ''}
                                onChange={(e) => handleItemChange(item.id, 'title', e.target.value)}
                                placeholder={__('How do I earn points?', 'mycred')}
                                sx={{
                                    mb: 2,
                                    '& .MuiOutlinedInput-root': {
                                        borderRadius: '8px',
                                        height: '40px',
                                        '&.Mui-focused fieldset': { borderColor: '#5E2CED' },
                                    },
                                }}
                            />
                            <Typography sx={{ fontSize: 13, fontWeight: 600, mb: 0.75, color: '#1a1a1a' }}>
                                {__('Answer', 'mycred')}
                            </Typography>
                            <TextField
                                fullWidth
                                multiline
                                minRows={3}
                                value={item.answer || ''}
                                onChange={(e) => handleItemChange(item.id, 'answer', e.target.value)}
                                placeholder={__('Complete actions listed under Earn to collect points.', 'mycred')}
                                sx={{
                                    '& .MuiOutlinedInput-root': {
                                        borderRadius: '8px',
                                        '&.Mui-focused fieldset': { borderColor: '#5E2CED' },
                                    },
                                }}
                            />
                        </Paper>
                    ))}
                </Box>

                <Button
                    startIcon={<AddIcon />}
                    onClick={handleAdd}
                    sx={{
                        mt: 2,
                        textTransform: 'none',
                        fontWeight: 600,
                        color: '#5E2CED',
                        borderRadius: '8px',
                        border: '1px dashed #D9D0FF',
                        px: 2,
                        py: 1,
                        width: '100%',
                        '&:hover': { bgcolor: 'rgba(94,44,237,0.04)', borderColor: '#5E2CED' },
                    }}
                >
                    {__('Add FAQ', 'mycred')}
                </Button>
            </Paper>

            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                <Button
                    variant="contained"
                    startIcon={<SaveIcon />}
                    disabled={loading}
                    onClick={handleSave}
                    sx={{
                        textTransform: 'none',
                        fontWeight: 600,
                        bgcolor: '#5E2CED',
                        borderRadius: '10px',
                        px: 3,
                        py: 1.25,
                        boxShadow: 'none',
                        '&:hover': { bgcolor: '#4B22C0', boxShadow: 'none' },
                    }}
                >
                    {loading ? __('Saving…', 'mycred') : __('Save FAQs', 'mycred')}
                </Button>
            </Box>
        </Box>
    );
}
