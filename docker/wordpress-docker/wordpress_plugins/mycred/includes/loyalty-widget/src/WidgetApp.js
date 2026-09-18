import { useState, useEffect } from '@wordpress/element';
import { Box, ThemeProvider, createTheme } from '@mui/material';
import Launcher from './components/Launcher';
import WidgetWindow from './components/WidgetWindow';

export default function WidgetApp() {
    const data = window.mycredLoyaltyWidget || {};
    const settings = data.settings || {};
    const general = settings.general || {};
    const design = settings.design || {};
    const tabs = settings.tabs || {};

    const [isOpen, setIsOpen] = useState(false);
    const [currentTab, setCurrentTab] = useState('home'); // 'home', 'earn', 'redeem', 'board', 'logs', 'profile'

    // Create a dynamic theme based on dashboard settings
    const theme = createTheme({
        palette: {
            primary: {
                main: design.buttonColor || '#5E2CED',
                contrastText: design.buttonTextColor || '#FFFFFF',
            },
        },
        typography: {
            fontFamily: "'Instrument Sans', sans-serif",
        },
    });

    const toggleWidget = () => {
        setIsOpen(!isOpen);
    };

    const position = general.widgetPosition || 'bottom-right';

    // Position CSS
    const getPositionStyles = () => {
        const styles = {
            position: 'fixed',
            zIndex: 99999,
        };

        if (position.includes('bottom')) styles.bottom = `${general.marginBottom || 24}px`;
        if (position.includes('top')) styles.top = `${general.marginTop || 24}px`;
        if (position.includes('right')) styles.right = `${general.marginRight || 24}px`;
        if (position.includes('left')) styles.left = `${general.marginLeft || 24}px`;

        return styles;
    };

    return (
        <ThemeProvider theme={theme}>
            <Box sx={getPositionStyles()}>
                {/* Launcher Button */}
                <Launcher
                    isOpen={isOpen}
                    onClick={toggleWidget}
                    settings={settings}
                />

                {/* Widget Window */}
                {isOpen && (
                    <WidgetWindow
                        settings={settings}
                        user={data.user}
                        currentTab={currentTab}
                        setCurrentTab={setCurrentTab}
                        onClose={() => setIsOpen(false)}
                    />
                )}
            </Box>
        </ThemeProvider>
    );
}
