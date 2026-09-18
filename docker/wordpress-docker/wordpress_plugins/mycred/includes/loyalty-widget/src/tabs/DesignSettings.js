import { useState, useRef } from '@wordpress/element';
import {
    Box,
    Typography,
    TextField,
    Button,
    Grid,
    Paper,
    Divider,
    Slider,
    Select,
    MenuItem,
    FormControl,
} from '@mui/material';
import { styled } from '@mui/material/styles';
import { __ } from '@wordpress/i18n';
import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome';
import BrandingWatermarkIcon from '@mui/icons-material/BrandingWatermark';
import SaveIcon from '@mui/icons-material/Save';
import RestartAltIcon from '@mui/icons-material/RestartAlt';
import WidgetPreviewPanel from '../components/preview/WidgetPreviewPanel';
import { usePreviewSettings } from '../context/PreviewSettingsContext';
import { saveSectionSettings } from '../services/api';
import { toast } from 'react-hot-toast';
import ToggleSwitch from '../components/admin/ToggleSwitch';
import { TEMPLATE_OPTIONS, getTemplatePreset, normalizeLayoutTemplate } from '../components/preview/templatePresets';
import ViewQuiltIcon from '@mui/icons-material/ViewQuilt';

const ColorInput = ({ label, value, onChange }) => {
    const [isFocused, setIsFocused] = useState(false);
    return (
        <Box sx={{ mb: 2.5 }}>
            <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>{label}</Typography>
            <Box
                sx={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 0,
                    border: isFocused ? '1px solid #5E2CED !important' : '1px solid #E6E0F8 !important',
                    borderRadius: '10px',
                    overflow: 'hidden',
                    height: 44,
                    transition: 'all 0.2s ease-in-out',
                    backgroundColor: '#fff !important',
                    '&:hover': {
                        borderColor: isFocused ? '#5E2CED !important' : '#D9D0FF !important',
                    }
                }}
            >
                <Box
                    sx={{
                        width: 44,
                        height: 44,
                        bgcolor: value,
                        flexShrink: 0,
                        position: 'relative',
                        cursor: 'pointer',
                        borderRight: '1px solid #E6E0F8',
                        '& input[type="color"]': {
                            position: 'absolute',
                            top: -10,
                            left: -10,
                            width: '200%',
                            height: '200%',
                            cursor: 'pointer',
                            opacity: 0,
                            border: 'none',
                            padding: 0
                        }
                    }}
                >
                    <input
                        type="color"
                        value={value}
                        onChange={(e) => onChange(e.target.value)}
                    />
                </Box>
                <TextField
                    fullWidth
                    size="small"
                    value={value}
                    onChange={(e) => onChange(e.target.value)}
                    onFocus={() => setIsFocused(true)}
                    onBlur={() => setIsFocused(false)}
                    sx={{
                        height: '100%',
                        '& .MuiOutlinedInput-root': {
                            height: '100%',
                            borderRadius: 0,
                            '& fieldset': { border: 'none !important' },
                            '&:hover fieldset': { border: 'none !important' },
                            '&.Mui-focused fieldset': { border: 'none !important' },
                            '& .MuiOutlinedInput-notchedOutline': { border: 'none !important' }
                        },
                        '& .MuiInputBase-input': {
                            fontSize: '14px',
                            height: '100%',
                            boxSizing: 'border-box',
                            py: 0,
                            boxShadow: 'none !important',
                            outline: 'none !important',
                            border: 'none !important',
                            backgroundColor: 'transparent !important',
                        }
                    }}
                />
            </Box>
        </Box>
    );
};

const SectionHeader = ({ icon: Icon, title, desc }) => (
    <Box sx={{ mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
            <Icon sx={{ color: '#5E2CED', fontSize: 20 }} />
            <Typography sx={{ fontSize: '18px', fontWeight: 600, color: '#1a1a1a' }}>{title}</Typography>
        </Box>
        <Typography sx={{ fontSize: '14px', color: '#666' }}>{desc}</Typography>
    </Box>
);

const getDefaultDesignSettings = () => ({
    showLogo: true,
    backgroundColor: '#000000',
    textColor: '#FFFFFF',
    buttonColor: '#000000',
    buttonTextColor: '#FFFFFF',
    showBranding: true,
    logoUrl: window.mycredLoyaltyWidgetData?.assets_url ? window.mycredLoyaltyWidgetData.assets_url + 'widget-logo.png' : '',
    logoText: __('Reward Program', 'mycred'),
    launcherRadius: 45,
    launcherAnimation: 'fade',
    layoutTemplate: 'luxury',
    headerStyle: 'image',
    headerImageUrl: window.mycredLoyaltyWidgetData?.assets_url ? window.mycredLoyaltyWidgetData.assets_url + 'mycred_widget_header.png' : '',
    headerOverlayOpacity: 0,
    headerSubtitle: __('Welcome to', 'mycred'),
    programTitle: __('Rewards Hub', 'mycred'),
    borderRadius: 8,
    navLayout: 'list',
    heroImageUrl: window.mycredLoyaltyWidgetData?.assets_url ? window.mycredLoyaltyWidgetData.assets_url + 'default-logo1.svg' : '',
});

const DesignSettings = () => {
    const isPro = window.mycredLoyaltyWidgetData?.is_toolkit_pro_active || false;
    const { design: settings, setDesign, updateDesign } = usePreviewSettings();

    const frameRef = useRef(null);
    const headerFrameRef = useRef(null);
    const heroFrameRef = useRef(null);

    const handleUploadLogo = () => {
        if (typeof wp === 'undefined' || !wp.media) {
            return;
        }

        if (frameRef.current) {
            frameRef.current.open();
            return;
        }

        frameRef.current = wp.media({
            title: __('Select Logo', 'mycred'),
            button: {
                text: __('Use this logo', 'mycred')
            },
            multiple: false
        });

        frameRef.current.on('select', () => {
            const attachment = frameRef.current.state().get('selection').first().toJSON();
            handleChange('logoUrl', attachment.url);
        });

        frameRef.current.open();
    };

    const handleRemoveLogo = () => {
        handleChange('logoUrl', '');
    };

    const handleUploadHeroImage = () => {
        if (typeof wp === 'undefined' || !wp.media) return;

        if (heroFrameRef.current) {
            heroFrameRef.current.open();
            return;
        }

        heroFrameRef.current = wp.media({
            title: __('Select Brand Image', 'mycred'),
            button: { text: __('Use this image', 'mycred') },
            multiple: false,
        });

        heroFrameRef.current.on('select', () => {
            const attachment = heroFrameRef.current.state().get('selection').first().toJSON();
            handleChange('heroImageUrl', attachment.url);
        });

        heroFrameRef.current.open();
    };

    const handleRemoveHeroImage = () => {
        handleChange('heroImageUrl', '');
    };

    const [loading, setLoading] = useState(false);

    const handleChange = (field, value) => {
        updateDesign({ [field]: value });
    };

    const handleSelectTemplate = (templateId) => {
        const id = normalizeLayoutTemplate(templateId);
        if (normalizeLayoutTemplate(settings.layoutTemplate) === id) {
            return;
        }
        const preset = getTemplatePreset(id);
        updateDesign({
            ...preset,
            // Keep user colors and images / copy when switching templates.
            backgroundColor: settings.backgroundColor || preset.backgroundColor,
            textColor: settings.textColor || preset.textColor,
            buttonColor: settings.buttonColor || preset.buttonColor,
            buttonTextColor: settings.buttonTextColor || preset.buttonTextColor,
            logoUrl: settings.logoUrl,
            logoText: settings.logoText,
            showLogo: settings.showLogo,
            headerImageUrl: settings.headerImageUrl,
            headerSubtitle: settings.headerSubtitle,
            programTitle: settings.programTitle,
            heroImageUrl: settings.heroImageUrl,
            showBranding: settings.showBranding,
            launcherRadius: settings.launcherRadius,
            launcherAnimation: settings.launcherAnimation,
        });
    };

    const handleUploadHeaderImage = () => {
        if (typeof wp === 'undefined' || !wp.media) return;

        if (headerFrameRef.current) {
            headerFrameRef.current.open();
            return;
        }

        headerFrameRef.current = wp.media({
            title: __('Select Header Image', 'mycred'),
            button: { text: __('Use this image', 'mycred') },
            multiple: false,
        });

        headerFrameRef.current.on('select', () => {
            const attachment = headerFrameRef.current.state().get('selection').first().toJSON();
            handleChange('headerImageUrl', attachment.url);
            handleChange('headerStyle', 'image');
        });

        headerFrameRef.current.open();
    };

    const handleResetToDefaults = () => {
        setDesign(getDefaultDesignSettings());
        toast.success(__('Reset to defaults', 'mycred'));
    };

    const handleSave = async () => {
        setLoading(true);
        try {
            const payload = {
                ...settings,
                layoutTemplate: normalizeLayoutTemplate(settings.layoutTemplate),
            };
            const response = await saveSectionSettings('design', payload);
            if (response.success) {
                toast.success(__('Settings saved successfully!', 'mycred'));
                if (window.mycredLoyaltyWidgetData) {
                    if (!window.mycredLoyaltyWidgetData.settings) window.mycredLoyaltyWidgetData.settings = {};
                    window.mycredLoyaltyWidgetData.settings.design = payload;
                }
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
            <Box sx={{ display: 'flex', gap: 4, flexWrap: { xs: 'wrap', lg: 'nowrap' }, alignItems: 'flex-start' }}>
                {/* Left Column: Settings - 50% Width */}
                <Box sx={{ flex: '1', minWidth: { xs: '100%', lg: '0' }, maxWidth: { xs: '100%', lg: '500px' } }}>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                        {/* Template picker */}
                        <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                            <SectionHeader
                                icon={ViewQuiltIcon}
                                title={__('Templates', 'mycred')}
                                desc={__('Choose a home layout. Content and design options below apply to every template.', 'mycred')}
                            />
                            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 1.5 }}>
                                {TEMPLATE_OPTIONS.map((opt) => {
                                    const selected = normalizeLayoutTemplate(settings.layoutTemplate) === opt.id;
                                    return (
                                        <Box
                                            key={opt.id}
                                            onClick={() => handleSelectTemplate(opt.id)}
                                            sx={{
                                                p: 2,
                                                borderRadius: '12px',
                                                border: selected ? '2px solid #5E2CED' : '1px solid #E0E0E0',
                                                bgcolor: selected ? 'rgba(94,44,237,0.04)' : '#fff',
                                                cursor: 'pointer',
                                                transition: 'border-color 0.15s ease, background 0.15s ease',
                                                '&:hover': {
                                                    borderColor: selected ? '#5E2CED' : '#D9D0FF',
                                                },
                                            }}
                                        >
                                            <Typography sx={{ fontSize: 15, fontWeight: 700, color: '#1a1a1a', mb: 0.5 }}>
                                                {__(opt.label, 'mycred')}
                                            </Typography>
                                            <Typography sx={{ fontSize: 12, color: '#666', lineHeight: 1.4 }}>
                                                {__(opt.description, 'mycred')}
                                            </Typography>
                                        </Box>
                                    );
                                })}
                            </Box>
                        </Paper>

                        {/* Logo Settings */}
                        <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                            <SectionHeader
                                icon={AutoAwesomeIcon}
                                title={__('Logo Settings', 'mycred')}
                                desc={__('Customize your widget logo', 'mycred')}
                            />
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                                <Box>
                                    <Typography sx={{ fontWeight: 600, fontSize: '15px' }}>{__('Show Logo', 'mycred')}</Typography>
                                    <Typography sx={{ fontSize: '13px', color: '#666' }}>{__('Display logo in the widget', 'mycred')}</Typography>
                                </Box>
                                <ToggleSwitch checked={settings.showLogo} onChange={(e) => handleChange('showLogo', e.target.checked)} />
                            </Box>
                            <Divider sx={{ my: 3 }} />
                            {settings.showLogo && (
                                <Box sx={{ mb: 3 }}>
                                    <Typography sx={{ fontWeight: 600, fontSize: '15px', mb: 1.5 }}>{__('Upload Logo', 'mycred')}</Typography>
                                    <Box
                                        sx={{
                                            display: 'flex',
                                            alignItems: 'center',
                                            border: '1px solid #E0E0E0',
                                            borderRadius: '8px',
                                            overflow: 'hidden',
                                            height: 44
                                        }}
                                    >
                                        <Button
                                            onClick={handleUploadLogo}
                                            size="small"
                                            sx={{
                                                textTransform: 'none',
                                                color: '#1a1a1a',
                                                fontWeight: 600,
                                                px: 2,
                                                height: '100%',
                                                bgcolor: '#f5f5f5',
                                                borderRadius: 0,
                                                borderRight: '1px solid #E0E0E0',
                                                flexShrink: 0,
                                                '&:hover': { bgcolor: '#ececec' }
                                            }}>
                                            {__('Choose file', 'mycred')}
                                        </Button>
                                        <TextField
                                            fullWidth
                                            placeholder={__('No file chosen', 'mycred')}
                                            disabled
                                            size="small"
                                            value={settings.logoUrl || ''}
                                            sx={{
                                                '& .MuiOutlinedInput-root': {
                                                    height: 44,
                                                    '& fieldset': { border: 'none' },
                                                    '&.Mui-disabled fieldset': { border: 'none' }
                                                },
                                                '& .MuiInputBase-input.Mui-disabled': {
                                                    WebkitTextFillColor: '#666',
                                                    fontSize: '14px'
                                                }
                                            }}
                                        />
                                    </Box>
                                    <Button
                                        onClick={handleRemoveLogo}
                                        size="small"
                                        sx={{ mt: 2, textTransform: 'none', color: '#666', border: '1px solid #E0E0E0', borderRadius: '4px' }}>
                                        {__('Restore Default', 'mycred')}
                                    </Button>
                                </Box>
                            )}
                            <Box>
                                <Typography sx={{ fontWeight: 600, fontSize: '15px', mb: 1.5 }}>{__('Widget Name', 'mycred')}</Typography>
                                    <TextField
                                        fullWidth
                                        size="small"
                                        value={settings.logoText}
                                        onChange={(e) => handleChange('logoText', e.target.value)}
                                        placeholder={__('Enter widget name...', 'mycred')}
                                        sx={{
                                            '& .MuiOutlinedInput-root': {
                                                borderRadius: '8px',
                                                height: '40px',
                                                '&.Mui-focused fieldset': { borderColor: '#5E2CED' }
                                            }
                                        }}
                                    />
                                    <Typography sx={{ fontSize: '13px', color: '#666', mt: 1 }}>
                                        {__('This name will appear in the widget launcher alongside your logo.', 'mycred')}
                                    </Typography>
                                </Box>
                        </Paper>

                        {/* Hero card brand image */}
                        <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                            <SectionHeader
                                icon={BrandingWatermarkIcon}
                                title={__('Hero Card Brand Image', 'mycred')}
                                desc={__('Optional image or GIF shown above the Join button for guests. Logged-in members see their point balances instead.', 'mycred')}
                            />
                            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', flexWrap: 'wrap' }}>
                                <Button onClick={handleUploadHeroImage} variant="outlined" size="small" sx={{ textTransform: 'none' }}>
                                    {__('Upload Image / GIF', 'mycred')}
                                </Button>
                                {settings.heroImageUrl && (
                                    <Button onClick={handleRemoveHeroImage} size="small" sx={{ textTransform: 'none', color: '#666' }}>
                                        {__('Remove', 'mycred')}
                                    </Button>
                                )}
                            </Box>
                            {settings.heroImageUrl && (
                                <Box sx={{ mt: 2, p: 2, bgcolor: '#FAFAFA', borderRadius: '8px', border: '1px solid #E0E0E0', textAlign: 'center' }}>
                                    <Box
                                        component="img"
                                        src={settings.heroImageUrl}
                                        alt=""
                                        sx={{ maxWidth: '100%', maxHeight: 120, objectFit: 'contain' }}
                                    />
                                </Box>
                            )}
                        </Paper>

                        {/* Layout Settings */}
                        <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                            <SectionHeader
                                icon={AutoAwesomeIcon}
                                title={__('Layout Settings', 'mycred')}
                                desc={__('Customize the widget header and home layout', 'mycred')}
                            />

                            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2, mb: 2 }}>
                                <Box>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, color: '#1a1a1a', mb: 1 }}>{__('Header Subtitle', 'mycred')}</Typography>
                                    <TextField
                                        fullWidth
                                        size="small"
                                        value={settings.headerSubtitle || ''}
                                        onChange={(e) => handleChange('headerSubtitle', e.target.value)}
                                        sx={{
                                            '& .MuiOutlinedInput-root': {
                                                borderRadius: '8px',
                                                height: '40px',
                                                '&.Mui-focused fieldset': { borderColor: '#5E2CED' }
                                            }
                                        }}
                                    />
                                </Box>
                                <Box>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, color: '#1a1a1a', mb: 1 }}>{__('Program Title', 'mycred')}</Typography>
                                    <TextField
                                        fullWidth
                                        size="small"
                                        value={settings.programTitle || ''}
                                        onChange={(e) => handleChange('programTitle', e.target.value)}
                                        sx={{
                                            '& .MuiOutlinedInput-root': {
                                                borderRadius: '8px',
                                                height: '40px',
                                                '&.Mui-focused fieldset': { borderColor: '#5E2CED' }
                                            }
                                        }}
                                    />
                                </Box>
                            </Box>

                            <Box sx={{ mb: 2 }}>
                                <Typography sx={{ fontWeight: 600, fontSize: '14px', mb: 1 }}>{__('Header Image', 'mycred')}</Typography>
                                <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                                    <Button onClick={handleUploadHeaderImage} variant="outlined" size="small" sx={{ textTransform: 'none' }}>
                                        {__('Upload Image', 'mycred')}
                                    </Button>
                                    {settings.headerImageUrl && (
                                        <Button onClick={() => handleChange('headerImageUrl', '')} size="small" sx={{ textTransform: 'none', color: '#666' }}>
                                            {__('Remove', 'mycred')}
                                        </Button>
                                    )}
                                </Box>
                                <Box sx={{ mt: 1.5 }}>
                                    <Typography sx={{ fontSize: '13px', mb: 1 }}>{__('Overlay Opacity', 'mycred')}</Typography>
                                    <Slider
                                        value={settings.headerOverlayOpacity ?? 0}
                                        onChange={(_, v) => handleChange('headerOverlayOpacity', v)}
                                        min={0}
                                        max={1}
                                        step={0.05}
                                        valueLabelDisplay="auto"
                                        sx={{ color: '#5E2CED' }}
                                    />
                                </Box>
                            </Box>
                            <Box sx={{ mb: 2 }}>
                                <Typography sx={{ fontSize: '13px', fontWeight: 600, mb: 1 }}>{__('Border Radius (px)', 'mycred')}</Typography>
                                <Slider
                                    value={settings.borderRadius ?? 8}
                                    onChange={(_, v) => handleChange('borderRadius', v)}
                                    min={8}
                                    max={24}
                                    step={1}
                                    valueLabelDisplay="auto"
                                    sx={{ color: '#5E2CED' }}
                                />
                            </Box>
                        </Paper>

                        {/* Appearance */}
                        <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                            <SectionHeader
                                icon={AutoAwesomeIcon}
                                title={__('Appearance', 'mycred')}
                                desc={__('Customize colors for your widget', 'mycred')}
                            />
                            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
                                <Box>
                                    <ColorInput label={__('Background Color', 'mycred')} value={settings.backgroundColor} onChange={(v) => handleChange('backgroundColor', v)} />
                                </Box>
                                <Box>
                                    <ColorInput label={__('Text Color', 'mycred')} value={settings.textColor} onChange={(v) => handleChange('textColor', v)} />
                                </Box>
                                <Box>
                                    <ColorInput label={__('Button Color', 'mycred')} value={settings.buttonColor} onChange={(v) => handleChange('buttonColor', v)} />
                                </Box>
                                <Box>
                                    <ColorInput label={__('Button Text Color', 'mycred')} value={settings.buttonTextColor} onChange={(v) => handleChange('buttonTextColor', v)} />
                                </Box>
                            </Box>
                        </Paper>

                        {/* Branding */}
                        <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                            <SectionHeader
                                icon={BrandingWatermarkIcon}
                                title={__('Branding', 'mycred')}
                                desc={__('Pro version feature', 'mycred')}
                            />
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                                <Box>
                                    <Typography sx={{ fontWeight: 600, fontSize: '15px' }}>{__('Show "Powered by myCred"', 'mycred')}</Typography>
                                    <Typography sx={{ fontSize: '13px', color: '#666' }}>{__('Display branding footer (Pro version)', 'mycred')}</Typography>
                                </Box>
                                <ToggleSwitch
                                    checked={settings.showBranding}
                                    onChange={(e) => {
                                        if (!isPro) return;
                                        handleChange('showBranding', e.target.checked);
                                    }}
                                    sx={{
                                        opacity: isPro ? 1 : 0.9,
                                        cursor: isPro ? 'pointer' : 'not-allowed'
                                    }}
                                />
                            </Box>
                            {!isPro && (
                                <Box sx={{ p: 2, bgcolor: '#FFFBEB', borderRadius: '8px', border: '1px solid #FEF3C7', display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <Typography sx={{ color: '#92400E', fontSize: '13px' }}>
                                        👑 {__('Upgrade to Pro version to hide branding footer.', 'mycred')}
                                    </Typography>
                                </Box>
                            )}
                        </Paper>

                        {/* Save Buttons */}
                        <Box sx={{ mt: 1, pt: 3, borderTop: '1px solid #E0E0E0', display: 'flex', gap: 2 }}>
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
                            <Button
                                variant="outlined"
                                startIcon={<RestartAltIcon />}
                                onClick={handleResetToDefaults}
                                disabled={loading}
                                sx={{
                                    borderColor: '#E0E0E0',
                                    color: '#666',
                                    textTransform: 'none',
                                    px: 3,
                                    py: 1.25,
                                    fontSize: '14px',
                                    fontWeight: 600,
                                    borderRadius: '8px',
                                    '&:hover': {
                                        borderColor: '#ccc',
                                        bgcolor: 'rgba(0,0,0,0.02)'
                                    }
                                }}
                            >
                                {__('Reset to Default', 'mycred')}
                            </Button>
                        </Box>
                    </Box>
                </Box>

                {/* Right Column: Preview & Launcher Settings - 50% Width */}
                <Box sx={{ flex: '1', minWidth: { xs: '100%', lg: '0' }, maxWidth: { xs: '100%', lg: '520px' } }}>
                    <Box sx={{ position: 'sticky', top: 24, display: 'flex', flexDirection: 'column', gap: 4 }}>
                        <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                            <SectionHeader
                                icon={AutoAwesomeIcon}
                                title={__('Live Widget Preview', 'mycred')}
                                desc={__('See your design changes in real-time', 'mycred')}
                            />
                            <Box sx={{ mt: 2 }}>
                                <WidgetPreviewPanel />
                            </Box>
                        </Paper>

                        {/* Launcher Button Settings (Below Preview) */}
                        <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                            <SectionHeader
                                icon={AutoAwesomeIcon}
                                title={__('Launcher Button Settings', 'mycred')}
                                desc={__('Customize the button that opens the widget', 'mycred')}
                            />

                            <Box sx={{ mb: 3 }}>
                                <Typography sx={{ fontWeight: 600, fontSize: '14px', mb: 2 }}>
                                    {__('Button Radius (px)', 'mycred')}
                                </Typography>
                                <Box sx={{ px: 1 }}>
                                    <Slider
                                        value={settings.launcherRadius}
                                        onChange={(e, newValue) => handleChange('launcherRadius', newValue)}
                                        min={0}
                                        max={50}
                                        step={1}
                                        valueLabelDisplay="auto"
                                        sx={{ color: '#5E2CED' }}
                                    />
                                </Box>
                            </Box>

                            <Box>
                                <Typography sx={{ fontWeight: 600, fontSize: '14px', mb: 1 }}>
                                    {__('Opening Animation', 'mycred')}
                                </Typography>
                                <FormControl fullWidth size="small">
                                    <Select
                                        value={settings.launcherAnimation}
                                        onChange={(e) => handleChange('launcherAnimation', e.target.value)}
                                        sx={{
                                            borderRadius: '8px',
                                            '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                                borderColor: '#5E2CED'
                                            }
                                        }}
                                    >
                                        <MenuItem value="none">{__('None', 'mycred')}</MenuItem>
                                        <MenuItem value="fade">{__('Fade', 'mycred')}</MenuItem>
                                        <MenuItem value="slide">{__('Slide Up', 'mycred')}</MenuItem>
                                        <MenuItem value="zoom">{__('Zoom', 'mycred')}</MenuItem>
                                    </Select>
                                </FormControl>
                            </Box>
                        </Paper>
                    </Box>
                </Box>
            </Box>
        </Box>
    );
};

export default DesignSettings;
