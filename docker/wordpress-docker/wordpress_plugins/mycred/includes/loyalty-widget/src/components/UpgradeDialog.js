import React from 'react';
import {
    Dialog,
    DialogContent,
    DialogTitle,
    Typography,
    Button,
    IconButton,
    Box,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import myCredDialogLogo from '../assets/header/mycred-logo-dialog.svg';
import proBoxBg from '../assets/header/pro-box-bg.svg';

const UpgradeDialog = ({ open, handleClose }) => {
    return (
        <Dialog
            open={open}
            onClose={handleClose}
            sx={{
                '& .MuiDialog-paper': {
                    width: '602px',
                    height: '379px',
                    borderRadius: '16px',
                    boxShadow: '0 4px 20px rgba(0, 0, 0, 0.1)',
                    backgroundColor: '#2D1572',
                    position: 'relative',
                    overflow: 'hidden',
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center',
                    alignItems: 'center',
                    zIndex: 1300,
                    p: 0,
                },
            }}
        >
            {/* Background SVG */}
            <img
                src={proBoxBg}
                alt="background"
                style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                    zIndex: 0,
                    objectFit: 'cover'
                }}
            />

            <DialogTitle
                sx={{
                    backgroundColor: 'transparent',
                    color: '#fff',
                    position: 'relative',
                    minHeight: '132px',
                    width: '100%',
                    zIndex: 1,
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                }}
            >
                <Box
                    sx={{
                        position: 'absolute',
                        top: '58.21px',
                        left: '50%',
                        transform: 'translateX(-50%)',
                        width: '195px',
                        height: '58.5742px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                    }}
                >
                    <img src={myCredDialogLogo} alt="myCred Logo" width={195} height={58.5742} />
                </Box>
                <IconButton
                    aria-label="close"
                    onClick={handleClose}
                    sx={{ position: 'absolute', top: '16px', right: '16px', width: 24, height: 24, p: 0, color: '#fff' }}
                >
                    <CloseIcon />
                </IconButton>
            </DialogTitle>

            <DialogContent sx={{ position: 'static', width: '100%', zIndex: 1 }}>
                <Box
                    sx={{
                        mt: 2,
                        width: '100%',
                        color: '#FFFFFF',
                        fontFamily: 'Figtree, sans-serif',
                        fontWeight: 600,
                        fontSize: '28px',
                        lineHeight: '150%',
                        textAlign: 'center',
                    }}
                >
                    <Box component="span" sx={{ color: '#FFC436' }}>Join Over 10,000+</Box> WordPress Site
                    <br />
                    Owners to Gamify User Engagement
                </Box>

                <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
                    <Button
                        onClick={() => {
                            window.open('https://mycred.me/pricing/', '_blank');
                        }}
                        variant="contained"
                        sx={{
                            width: '190px',
                            height: '48px',
                            borderRadius: '45px',
                            backgroundColor: '#F19C38',
                            color: '#341883',
                            fontWeight: 700,
                            fontSize: '14px',
                            fontFamily: 'Figtree, sans-serif',
                            textTransform: 'none',
                            '&:hover': { backgroundColor: '#FF9800' },
                        }}
                    >
                        Get myCred Pro
                    </Button>
                </Box>
            </DialogContent>
        </Dialog>
    );
};

export default UpgradeDialog;
