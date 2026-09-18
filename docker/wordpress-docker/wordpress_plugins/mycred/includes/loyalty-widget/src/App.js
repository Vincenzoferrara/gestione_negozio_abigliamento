import { useState } from '@wordpress/element';
import { Box, Tabs, Tab, Typography, createTheme, ThemeProvider, ScopedCssBaseline, GlobalStyles } from '@mui/material';
import { __ } from '@wordpress/i18n';
import Header from './components/Header';
import GeneralSettings from './tabs/GeneralSettings';
import DesignSettings from './tabs/DesignSettings';
import ContentSettings from './tabs/ContentSettings';
import TabsSettings from './tabs/TabsSettings';
import EventTriggersSettings from './tabs/EventTriggersSettings';
import FaqSettings from './tabs/FaqSettings';
import { PreviewSettingsProvider } from './context/PreviewSettingsContext';
import SettingsIcon from '@mui/icons-material/Settings';
import PaletteIcon from '@mui/icons-material/Palette';
import ArticleIcon from '@mui/icons-material/Article';
import ViewListIcon from '@mui/icons-material/ViewList';
import EventIcon from '@mui/icons-material/Event';
import HelpOutlineIcon from '@mui/icons-material/HelpOutline';
import { Toaster } from 'react-hot-toast';

// Create a theme instance matching the dashboard.
const theme = createTheme({
    palette: {
        primary: {
            main: '#5E2CED',
        },
        background: {
            default: '#F8F6FF'
        }
    },
    typography: {
        fontFamily: 'Poppins, sans-serif',
    },
    components: {
        MuiScopedCssBaseline: {
            styleOverrides: {
                root: {
                    fontFamily: 'Poppins, sans-serif',
                    '& .mycred-react-root': {
                        backgroundColor: '#F8F6FF',
                        minHeight: '100vh',
                    }
                }
            }
        }
    }
});

function TabPanel(props) {
    const { children, value, index, ...other } = props;

    return (
        <div
            role="tabpanel"
            hidden={value !== index}
            id={`vertical-tabpanel-${index}`}
            aria-labelledby={`vertical-tab-${index}`}
            {...other}
            style={{ width: '100%' }}
        >
            {value === index && (
                <Box sx={{ p: 0 }}>
                    {children}
                </Box>
            )}
        </div>
    );
}

function a11yProps(index) {
    return {
        id: `vertical-tab-${index}`,
        'aria-controls': `vertical-tabpanel-${index}`,
    };
}

export default function App() {
    const tabHashes = ['#general', '#design', '#content', '#tabs', '#faqs', '#event-triggers'];
    
    const getInitialTab = () => {
        const hash = window.location.hash;
        const index = tabHashes.indexOf(hash);
        return index !== -1 ? index : 0;
    };

    const [value, setValue] = useState(getInitialTab);

    const handleChange = (event, newValue) => {
        setValue(newValue);
        if (window.history.replaceState) {
            window.history.replaceState(null, null, tabHashes[newValue]);
        } else {
            window.location.hash = tabHashes[newValue];
        }
    };

    return (
        <ThemeProvider theme={theme}>
            <ScopedCssBaseline>
                <GlobalStyles
                    styles={{
                        '#wpcontent, #wpbody-content, #wpfooter': {
                            backgroundColor: '#F8F6FF !important',
                        },
                        '.mycred-react-root': {
                            fontFamily: 'Poppins, sans-serif !important',
                        },
                        '.mycred-react-root input[type="text"], .mycred-react-root input[type="number"], .mycred-react-root textarea, .mycred-react-root select, .mycred-react-root input[type="email"], .mycred-react-root input[type="password"]': {
                            border: 'none !important',
                            boxShadow: 'none !important',
                            backgroundColor: 'transparent !important',
                            minHeight: 'auto !important',
                            padding: '10px 14px !important',
                            boxSizing: 'border-box !important',
                        },
                        '.mycred-react-root legend': {
                            width: 'auto',
                            display: 'block',
                            padding: 0,
                            marginBottom: 0,
                        }
                    }}
                />
                <Box className="mycred-react-root" sx={{ bgcolor: '#F8F6FF', minHeight: '100vh' }}>
                    <Toaster
                        position="bottom-right"
                        toastOptions={{
                            success: {
                                iconTheme: {
                                    primary: '#5E2CED',
                                    secondary: '#fff',
                                },
                            },
                        }}
                    />
                    <Header />
                    <Box sx={{ maxWidth: '1400px', width: '90%', margin: '40px auto' }}>
                        <Box sx={{
                            flexGrow: 1,
                            bgcolor: 'background.paper',
                            display: 'flex',
                            height: 'auto',
                            minHeight: '600px',
                            borderRadius: '12px',
                            boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
                            overflow: 'hidden',
                            border: '1px solid #E0E0E0'
                        }}>
                            <Tabs
                                orientation="vertical"
                                variant="scrollable"
                                value={value}
                                onChange={handleChange}
                                aria-label="Loyalty Widget Settings Tabs"
                                sx={{
                                    borderRight: 1,
                                    borderColor: 'divider',
                                    minWidth: '220px',
                                    '& .MuiTab-root': {
                                        textTransform: 'none',
                                        fontWeight: 500,
                                        fontSize: '15px',
                                        py: 2.5,
                                        px: 3,
                                        minHeight: 'auto',
                                        alignItems: 'center',
                                        justifyContent: 'flex-start',
                                        textAlign: 'left',
                                        color: '#666',
                                        '&.Mui-selected': {
                                            color: '#5E2CED',
                                            bgcolor: 'rgba(94, 44, 237, 0.04)'
                                        }
                                    }
                                }}
                            >
                                <Tab icon={<SettingsIcon sx={{ mr: 1.5 }} />} iconPosition="start" label={__('General', 'mycred')} {...a11yProps(0)} />
                                <Tab icon={<PaletteIcon sx={{ mr: 1.5 }} />} iconPosition="start" label={__('Design', 'mycred')} {...a11yProps(1)} />
                                <Tab icon={<ArticleIcon sx={{ mr: 1.5 }} />} iconPosition="start" label={__('Content', 'mycred')} {...a11yProps(2)} />
                                <Tab icon={<ViewListIcon sx={{ mr: 1.5 }} />} iconPosition="start" label={__('Tabs', 'mycred')} {...a11yProps(3)} />
                                <Tab icon={<HelpOutlineIcon sx={{ mr: 1.5 }} />} iconPosition="start" label={__('FAQs', 'mycred')} {...a11yProps(4)} />
                                <Tab icon={<EventIcon sx={{ mr: 1.5 }} />} iconPosition="start" label={__('Event triggers', 'mycred')} {...a11yProps(5)} />
                            </Tabs>
    
                            <PreviewSettingsProvider>
                                <Box sx={{ flexGrow: 1, bgcolor: '#fff', width: '100%' }}>
                                    <TabPanel value={value} index={0}>
                                        <GeneralSettings />
                                    </TabPanel>
                                    <TabPanel value={value} index={1}>
                                        <DesignSettings />
                                    </TabPanel>
                                    <TabPanel value={value} index={2}>
                                        <ContentSettings />
                                    </TabPanel>
                                    <TabPanel value={value} index={3}>
                                        <TabsSettings />
                                    </TabPanel>
                                    <TabPanel value={value} index={4}>
                                        <FaqSettings />
                                    </TabPanel>
                                    <TabPanel value={value} index={5}>
                                        <EventTriggersSettings />
                                    </TabPanel>
                                </Box>
                            </PreviewSettingsProvider>
                        </Box>
                    </Box>
                </Box>
            </ScopedCssBaseline>
        </ThemeProvider>
    );
}
