import { useState } from 'react';
import {
    AppBar,
    Toolbar,
    Box,
} from '@mui/material';
import MyCredLogo from '../assets/header/mycred-logo.svg';
import DiamondIcon from '../assets/header/diamond.svg';
import UpgradeDialog from './UpgradeDialog';

const Header = () => {
    const [upgradeOpen, setUpgradeOpen] = useState(false);
    const openUpgrade = () => setUpgradeOpen(true);
    const closeUpgrade = () => setUpgradeOpen(false);

    // Checking toolkit pro from global data if available
    const isToolkitProActive = Boolean(window.mycredLoyaltyWidgetData?.is_toolkit_pro_active);

    return (
        <Box>
            <AppBar
                position="static"
                sx={{
                    backgroundColor: '#fff',
                    boxShadow: 'none',
                    width: '100%',
                    height: '84px',
                    borderBottom: '1px solid #E0E0E0'
                }}
            >
                <Toolbar sx={{
                    justifyContent: 'space-between',
                    px: 3,
                    height: '84px',
                    maxWidth: '100%',
                    width: '100%'
                }}>
                    {/* Left side - Logo */}
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', width: 142, height: 42 }}>
                            <img src={MyCredLogo} alt="myCred" style={{ width: '100%', height: 'auto' }} />
                        </Box>
                    </Box>

                    {/* Right side - PRO badge */}
                    {!isToolkitProActive &&
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Box
                                sx={{
                                    position: 'relative',
                                    width: '130px',
                                    height: '42.3256px',
                                    borderRadius: '4px',
                                    bgcolor: '#F3EDFF',
                                    overflow: 'hidden',
                                    cursor: 'pointer',
                                    userSelect: 'none',
                                }}
                                role="button"
                                aria-label="Supercharge with PRO"
                                onClick={openUpgrade}
                            >
                                <Box
                                    sx={{
                                        position: 'absolute',
                                        width: '108.2789px',
                                        height: '28px',
                                        top: '7.56px',
                                        left: '10.58px',
                                    }}
                                >
                                    <Box
                                        sx={{
                                            position: 'absolute',
                                            top: '0.56px',
                                            left: '0.22px',
                                            width: '29.7541px',
                                            height: '21.7827px',
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center'
                                        }}
                                    >
                                        <img src={DiamondIcon} alt="diamond" style={{ width: '29.7541px', height: '21.7827px' }} />
                                    </Box>

                                    <Box
                                        sx={{
                                            position: 'absolute',
                                            top: 0,
                                            left: '36.28px',
                                            width: '72px',
                                            height: '28px',
                                            color: '#5E2CED',
                                            fontFamily: 'Poppins, sans-serif',
                                            fontWeight: 500,
                                            fontSize: '10.58px',
                                            lineHeight: '13.6px',
                                            letterSpacing: 0,
                                            textAlign: 'left',
                                            whiteSpace: 'normal',
                                        }}
                                    >
                                        Supercharge
                                        <br />
                                        with <Box component="span" sx={{ fontWeight: 700 }}>PRO</Box>
                                    </Box>
                                </Box>
                            </Box>
                        </Box>
                    }
                    <UpgradeDialog open={upgradeOpen} handleClose={closeUpgrade} />
                </Toolbar>
            </AppBar>
        </Box>
    );
};

export default Header;
