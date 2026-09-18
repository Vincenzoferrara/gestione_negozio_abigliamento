import { useState } from '@wordpress/element';
import {
    Box,
    Typography,
    FormControl,
    Select,
    MenuItem,
    Paper,
    Button,
    TextField,
    Divider,
    Checkbox,
    ListItemText,
} from '@mui/material';
import { styled, alpha } from '@mui/material/styles';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { TimePicker } from '@mui/x-date-pickers/TimePicker';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDayjs } from '@mui/x-date-pickers/AdapterDayjs';
import { __ } from '@wordpress/i18n';
import SettingsIcon from '@mui/icons-material/Settings';
import SaveIcon from '@mui/icons-material/Save';
import RestartAltIcon from '@mui/icons-material/RestartAlt';
import dayjs from 'dayjs';
import customParseFormat from 'dayjs/plugin/customParseFormat';
dayjs.extend(customParseFormat);
import { saveSectionSettings } from '../services/api';
import { toast } from 'react-hot-toast';
import ToggleSwitch from '../components/admin/ToggleSwitch';

const SectionHeader = ({ icon: Icon, title, desc, action }) => (
    <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                <Icon sx={{ color: '#5E2CED', fontSize: 20 }} />
                <Typography sx={{ fontSize: '18px', fontWeight: 600, color: '#1a1a1a' }}>{title}</Typography>
            </Box>
            {desc && <Typography sx={{ fontSize: '14px', color: '#666' }}>{desc}</Typography>}
        </Box>
        {action && <Box>{action}</Box>}
    </Box>
);

export default function GeneralSettings() {
    const initialSettings = window.mycredLoyaltyWidgetData?.settings?.general || {};

    const parseTime = (timeStr, fallback) => {
        if (!timeStr) return fallback;
        const d = dayjs(timeStr, 'HH:mm');
        return d.isValid() ? d : fallback;
    };

    const [settings, setSettings] = useState({
        enableWidget: initialSettings.enableWidget !== undefined ? initialSettings.enableWidget : true,
        widgetPosition: initialSettings.widgetPosition || 'bottom-right',
        displayMode: initialSettings.displayMode || 'popup',
        enableDateRange: initialSettings.enableDateRange !== undefined ? initialSettings.enableDateRange : false,
        startDate: initialSettings.campaignStart ? dayjs(initialSettings.campaignStart) : null,
        endDate: initialSettings.campaignEnd ? dayjs(initialSettings.campaignEnd) : null,
        startTime: parseTime(initialSettings.startTime, dayjs().startOf('day')),
        endTime: parseTime(initialSettings.endTime, dayjs().endOf('day')),
        marginTop: initialSettings.marginTop !== undefined ? initialSettings.marginTop : 24,
        marginRight: initialSettings.marginRight !== undefined ? initialSettings.marginRight : 24,
        marginBottom: initialSettings.marginBottom !== undefined ? initialSettings.marginBottom : 24,
        marginLeft: initialSettings.marginLeft !== undefined ? initialSettings.marginLeft : 24,
        visibility: initialSettings.visibility || 'all',
        visibilityRoles: initialSettings.visibilityRoles || [],
    });

    const availableRoles = window.mycredLoyaltyWidgetData?.available_roles || [];

    const [loading, setLoading] = useState(false);

    const handleChange = (field, value) => {
        setSettings(prev => ({
            ...prev,
            [field]: value
        }));
    };

    const handleResetPosition = () => {
        setSettings(prev => ({
            ...prev,
            widgetPosition: 'bottom-right',
            marginTop: 24,
            marginRight: 24,
            marginBottom: 24,
            marginLeft: 24,
        }));
        toast.success(__('Position reset to defaults!', 'mycred'));
    };

    const handleSave = async () => {
        setLoading(true);
        try {
            const dataToSave = {
                ...settings,
                campaignStart: settings.startDate ? settings.startDate.format('YYYY-MM-DD') : null,
                campaignEnd: settings.endDate ? settings.endDate.format('YYYY-MM-DD') : null,
                startTime: settings.startTime ? settings.startTime.format('HH:mm') : null,
                endTime: settings.endTime ? settings.endTime.format('HH:mm') : null
            };
            delete dataToSave.startDate;
            delete dataToSave.endDate;

            const response = await saveSectionSettings('general', dataToSave);
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
        <LocalizationProvider dateAdapter={AdapterDayjs}>
            <Box sx={{ p: 4 }}>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                    {/* Enable Widget */}
                    <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                        <SectionHeader
                            icon={SettingsIcon}
                            title={__('Enable Widget', 'mycred')}
                            desc={__('Enable or disable the loyalty widget on your site', 'mycred')}
                        />
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <Typography sx={{ fontWeight: 600, fontSize: '15px' }}>
                                {__('Status', 'mycred')}
                            </Typography>
                            <ToggleSwitch
                                checked={settings.enableWidget}
                                onChange={(e) => handleChange('enableWidget', e.target.checked)}
                            />
                        </Box>
                    </Paper>

                    {/* Widget Visibility */}
                    <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                        <SectionHeader
                            icon={SettingsIcon}
                            title={__('Widget Visibility', 'mycred')}
                            desc={__('Control which users can see the widget', 'mycred')}
                        />
                        <FormControl fullWidth size="small" sx={{ mb: settings.visibility === 'roles' ? 2 : 0 }}>
                            <Select
                                value={settings.visibility}
                                onChange={(e) => handleChange('visibility', e.target.value)}
                                sx={{
                                    borderRadius: '10px',
                                    height: 40,
                                    '& .MuiOutlinedInput-notchedOutline': {
                                        borderColor: '#E6E0F8 !important',
                                        borderWidth: '1px !important',
                                    },
                                    '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                        borderColor: '#5E2CED !important',
                                        borderWidth: '1px !important',
                                    },
                                    '&:hover .MuiOutlinedInput-notchedOutline': {
                                        borderColor: '#D9D0FF !important',
                                    },
                                    '& .MuiSelect-select': {
                                        padding: '10px 12px',
                                        fontSize: '14px',
                                        boxShadow: 'none !important',
                                        outline: 'none !important',
                                        backgroundColor: 'transparent !important',
                                    }
                                }}
                            >
                                <MenuItem value="all">{__('Show to All Users', 'mycred')}</MenuItem>
                                <MenuItem value="logged_in">{__('Logged-in Users Only', 'mycred')}</MenuItem>
                                <MenuItem value="guests">{__('Guest Users Only', 'mycred')}</MenuItem>
                                <MenuItem value="roles">{__('Restrict by Specific Roles', 'mycred')}</MenuItem>
                            </Select>
                        </FormControl>
                        {settings.visibility === 'roles' && (
                            <FormControl fullWidth size="small">
                                <Typography sx={{ fontSize: '13px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                    {__('Select Roles', 'mycred')}
                                </Typography>
                                <Select
                                    multiple
                                    value={settings.visibilityRoles}
                                    onChange={(e) => handleChange('visibilityRoles', typeof e.target.value === 'string' ? e.target.value.split(',') : e.target.value)}
                                    renderValue={(selected) => selected.map(k => {
                                        const r = availableRoles.find(ar => ar.key === k);
                                        return r ? r.name : k;
                                    }).join(', ')}
                                    sx={{
                                        borderRadius: '10px',
                                        '& .MuiOutlinedInput-notchedOutline': {
                                            borderColor: '#E6E0F8 !important',
                                            borderWidth: '1px !important',
                                        },
                                        '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                            borderColor: '#5E2CED !important',
                                            borderWidth: '1px !important',
                                        },
                                        '&:hover .MuiOutlinedInput-notchedOutline': {
                                            borderColor: '#D9D0FF !important',
                                        },
                                        '& .MuiSelect-select': {
                                            padding: '10px 12px',
                                            fontSize: '14px',
                                            boxShadow: 'none !important',
                                            outline: 'none !important',
                                            backgroundColor: 'transparent !important',
                                        }
                                    }}
                                >
                                    {availableRoles.map((role) => (
                                        <MenuItem key={role.key} value={role.key}>
                                            <Checkbox checked={settings.visibilityRoles.indexOf(role.key) > -1} />
                                            <ListItemText primary={role.name} />
                                        </MenuItem>
                                    ))}
                                </Select>
                            </FormControl>
                        )}
                    </Paper>

                    {/* Widget Position */}
                    <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                        <SectionHeader
                            icon={SettingsIcon}
                            title={__('Widget Position', 'mycred')}
                            desc={__('Choose where the widget appears on your site', 'mycred')}
                            action={
                                <Button
                                    size="small"
                                    startIcon={<RestartAltIcon />}
                                    onClick={handleResetPosition}
                                    sx={{ 
                                        color: '#666', 
                                        textTransform: 'none',
                                        fontSize: '13px',
                                        '&:hover': { bgcolor: 'rgba(0,0,0,0.04)' }
                                    }}
                                >
                                    {__('Reset Position', 'mycred')}
                                </Button>
                            }
                        />
                        <FormControl fullWidth size="small">
                            <Select
                                value={settings.widgetPosition}
                                onChange={(e) => handleChange('widgetPosition', e.target.value)}
                                sx={{
                                    borderRadius: '10px',
                                    height: 40,
                                    '& .MuiOutlinedInput-notchedOutline': {
                                        borderColor: '#E6E0F8 !important',
                                        borderWidth: '1px !important',
                                    },
                                    '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                        borderColor: '#5E2CED !important',
                                        borderWidth: '1px !important',
                                    },
                                    '&:hover .MuiOutlinedInput-notchedOutline': {
                                        borderColor: '#D9D0FF !important',
                                    },
                                    '& .MuiSelect-select': {
                                        padding: '10px 12px',
                                        fontSize: '14px',
                                        boxShadow: 'none !important',
                                        outline: 'none !important',
                                        backgroundColor: 'transparent !important',
                                    }
                                }}
                            >
                                <MenuItem value="bottom-right">{__('Bottom Right', 'mycred')}</MenuItem>
                                <MenuItem value="bottom-left">{__('Bottom Left', 'mycred')}</MenuItem>
                                <MenuItem value="top-right">{__('Top Right', 'mycred')}</MenuItem>
                                <MenuItem value="top-left">{__('Top Left', 'mycred')}</MenuItem>
                            </Select>
                        </FormControl>

                        <Box sx={{ display: 'flex', gap: 2, mt: 3 }}>
                            <Box sx={{ flex: 1 }}>
                                <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                    {__('Top Margin (px)', 'mycred')}
                                </Typography>
                                <TextField
                                    fullWidth
                                    size="small"
                                    type="number"
                                    value={settings.marginTop}
                                    onChange={(e) => handleChange('marginTop', parseInt(e.target.value) || 0)}
                                    sx={{ 
                                        '& .MuiOutlinedInput-root': { 
                                            height: 40,
                                            borderRadius: '10px',
                                            backgroundColor: '#fff !important',
                                            '& fieldset': {
                                                borderColor: '#E6E0F8 !important',
                                                borderWidth: '1px !important',
                                            },
                                            '&:hover fieldset': {
                                                borderColor: '#D9D0FF !important',
                                            },
                                            '&.Mui-focused fieldset': {
                                                borderColor: '#5E2CED !important',
                                                borderWidth: '1px !important',
                                            },
                                            '& .MuiOutlinedInput-input': {
                                                padding: '10px 12px',
                                                fontSize: '14px',
                                                boxShadow: 'none !important',
                                                outline: 'none !important',
                                                border: 'none !important',
                                                backgroundColor: 'transparent !important',
                                            }
                                        }
                                    }}
                                />
                            </Box>
                            <Box sx={{ flex: 1 }}>
                                <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                    {__('Right Margin (px)', 'mycred')}
                                </Typography>
                                <TextField
                                    fullWidth
                                    size="small"
                                    type="number"
                                    value={settings.marginRight}
                                    onChange={(e) => handleChange('marginRight', parseInt(e.target.value) || 0)}
                                    sx={{ 
                                        '& .MuiOutlinedInput-root': { 
                                            height: 40,
                                            borderRadius: '10px',
                                            backgroundColor: '#fff !important',
                                            '& fieldset': {
                                                borderColor: '#E6E0F8 !important',
                                                borderWidth: '1px !important',
                                            },
                                            '&:hover fieldset': {
                                                borderColor: '#D9D0FF !important',
                                            },
                                            '&.Mui-focused fieldset': {
                                                borderColor: '#5E2CED !important',
                                                borderWidth: '1px !important',
                                            },
                                            '& .MuiOutlinedInput-input': {
                                                padding: '10px 12px',
                                                fontSize: '14px',
                                                boxShadow: 'none !important',
                                                outline: 'none !important',
                                                border: 'none !important',
                                                backgroundColor: 'transparent !important',
                                            }
                                        }
                                    }}
                                />
                            </Box>
                            <Box sx={{ flex: 1 }}>
                                <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                    {__('Bottom Margin (px)', 'mycred')}
                                </Typography>
                                <TextField
                                    fullWidth
                                    size="small"
                                    type="number"
                                    value={settings.marginBottom}
                                    onChange={(e) => handleChange('marginBottom', parseInt(e.target.value) || 0)}
                                    sx={{ 
                                        '& .MuiOutlinedInput-root': { 
                                            height: 40,
                                            borderRadius: '10px',
                                            backgroundColor: '#fff !important',
                                            '& fieldset': {
                                                borderColor: '#E6E0F8 !important',
                                                borderWidth: '1px !important',
                                            },
                                            '&:hover fieldset': {
                                                borderColor: '#D9D0FF !important',
                                            },
                                            '&.Mui-focused fieldset': {
                                                borderColor: '#5E2CED !important',
                                                borderWidth: '1px !important',
                                            },
                                            '& .MuiOutlinedInput-input': {
                                                padding: '10px 12px',
                                                fontSize: '14px',
                                                boxShadow: 'none !important',
                                                outline: 'none !important',
                                                border: 'none !important',
                                                backgroundColor: 'transparent !important',
                                            }
                                        }
                                    }}
                                />
                            </Box>
                            <Box sx={{ flex: 1 }}>
                                <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                    {__('Left Margin (px)', 'mycred')}
                                </Typography>
                                <TextField
                                    fullWidth
                                    size="small"
                                    type="number"
                                    value={settings.marginLeft}
                                    onChange={(e) => handleChange('marginLeft', parseInt(e.target.value) || 0)}
                                    sx={{ 
                                        '& .MuiOutlinedInput-root': { 
                                            height: 40,
                                            borderRadius: '10px',
                                            backgroundColor: '#fff !important',
                                            '& fieldset': {
                                                borderColor: '#E6E0F8 !important',
                                                borderWidth: '1px !important',
                                            },
                                            '&:hover fieldset': {
                                                borderColor: '#D9D0FF !important',
                                            },
                                            '&.Mui-focused fieldset': {
                                                borderColor: '#5E2CED !important',
                                                borderWidth: '1px !important',
                                            },
                                            '& .MuiOutlinedInput-input': {
                                                padding: '10px 12px',
                                                fontSize: '14px',
                                                boxShadow: 'none !important',
                                                outline: 'none !important',
                                                border: 'none !important',
                                                backgroundColor: 'transparent !important',
                                            }
                                        }
                                    }}
                                />
                            </Box>
                        </Box>
                    </Paper>

                    {/* Date Range */}
                    <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                            <Box sx={{ flex: 1 }}>
                                <SectionHeader
                                    icon={SettingsIcon}
                                    title={__('Date Range (Optional)', 'mycred')}
                                    desc={__('Optionally set a date range and time for when the widget should be active', 'mycred')}
                                />
                            </Box>
                            <Box sx={{ pt: 1 }}>
                                <ToggleSwitch
                                    checked={settings.enableDateRange}
                                    onChange={(e) => handleChange('enableDateRange', e.target.checked)}
                                />
                            </Box>
                        </Box>

                        <Box sx={{
                            display: 'flex',
                            flexDirection: 'column',
                            gap: 3,
                            mt: 2,
                            opacity: settings.enableDateRange ? 1 : 0.5,
                            pointerEvents: settings.enableDateRange ? 'auto' : 'none',
                            transition: 'opacity 0.2s ease-in-out'
                        }}>
                            <Box sx={{ display: 'flex', gap: 3 }}>
                                <Box sx={{ flex: 1 }}>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                        {__('Start Date', 'mycred')}
                                    </Typography>
                                    <DatePicker
                                        value={settings.startDate}
                                        onChange={(newValue) => handleChange('startDate', newValue)}
                                        disabled={!settings.enableDateRange}
                                        slotProps={{
                                            textField: {
                                                fullWidth: true,
                                                size: 'small',
                                                sx: { 
                                                    '& .MuiOutlinedInput-root': { 
                                                        height: 40,
                                                        borderRadius: '10px',
                                                        backgroundColor: '#fff !important',
                                                        '& fieldset': {
                                                            borderColor: '#E6E0F8 !important',
                                                            borderWidth: '1px !important',
                                                        },
                                                        '&:hover fieldset': {
                                                            borderColor: '#D9D0FF !important',
                                                        },
                                                        '&.Mui-focused fieldset': {
                                                            borderColor: '#5E2CED !important',
                                                            borderWidth: '1px !important',
                                                        },
                                                        '& .MuiOutlinedInput-input': {
                                                            padding: '10px 12px',
                                                            fontSize: '14px',
                                                            boxShadow: 'none !important',
                                                            outline: 'none !important',
                                                            border: 'none !important',
                                                            backgroundColor: 'transparent !important',
                                                        }
                                                    }
                                                }
                                            }
                                        }}
                                    />
                                </Box>
                                <Box sx={{ flex: 1 }}>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                        {__('Start Time', 'mycred')}
                                    </Typography>
                                    <TimePicker
                                        value={settings.startTime}
                                        onChange={(newValue) => handleChange('startTime', newValue)}
                                        disabled={!settings.enableDateRange}
                                        slotProps={{
                                            textField: {
                                                fullWidth: true,
                                                size: 'small',
                                                sx: { 
                                                    '& .MuiOutlinedInput-root': { 
                                                        borderRadius: '8px',
                                                        '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                                            borderColor: '#5E2CED !important',
                                                            borderWidth: '1px !important',
                                                        }
                                                    },
                                                    '& input:focus': {
                                                        outline: 'none !important',
                                                        boxShadow: 'none !important',
                                                    }
                                                }
                                            }
                                        }}
                                    />
                                </Box>
                            </Box>

                            <Divider />

                            <Box sx={{ display: 'flex', gap: 3 }}>
                                <Box sx={{ flex: 1 }}>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                        {__('End Date', 'mycred')}
                                    </Typography>
                                    <DatePicker
                                        value={settings.endDate}
                                        onChange={(newValue) => handleChange('endDate', newValue)}
                                        minDate={settings.startDate}
                                        disabled={!settings.enableDateRange}
                                        slotProps={{
                                            textField: {
                                                fullWidth: true,
                                                size: 'small',
                                                sx: { 
                                                    '& .MuiOutlinedInput-root': { 
                                                        borderRadius: '8px',
                                                        '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                                            borderColor: '#5E2CED !important',
                                                            borderWidth: '1px !important',
                                                        }
                                                    },
                                                    '& input:focus': {
                                                        outline: 'none !important',
                                                        boxShadow: 'none !important',
                                                    }
                                                }
                                            }
                                        }}
                                    />
                                </Box>
                                <Box sx={{ flex: 1 }}>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                        {__('End Time', 'mycred')}
                                    </Typography>
                                    <TimePicker
                                        value={settings.endTime}
                                        onChange={(newValue) => handleChange('endTime', newValue)}
                                        disabled={!settings.enableDateRange}
                                        slotProps={{
                                            textField: {
                                                fullWidth: true,
                                                size: 'small',
                                                sx: { 
                                                    '& .MuiOutlinedInput-root': { 
                                                        borderRadius: '8px',
                                                        '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                                                            borderColor: '#5E2CED !important',
                                                            borderWidth: '1px !important',
                                                        }
                                                    },
                                                    '& input:focus': {
                                                        outline: 'none !important',
                                                        boxShadow: 'none !important',
                                                    }
                                                }
                                            }
                                        }}
                                    />
                                </Box>
                            </Box>
                        </Box>
                    </Paper>
                </Box>

                {/* Save Button */}
                <Box sx={{ mt: 4, pt: 3, borderTop: '1px solid #E0E0E0' }}>
                    <Button
                        variant="contained"
                        startIcon={<SaveIcon />}
                        disabled={loading}
                        onClick={handleSave}
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
        </LocalizationProvider>
    );
}
