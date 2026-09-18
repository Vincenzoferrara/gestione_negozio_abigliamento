import React from 'react';
import {
  Dialog,
  DialogContent,
  DialogTitle,
  DialogActions,
  Typography,
  Button,
  IconButton,
  Box,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import { ReactComponent as MyCredDialogLogo } from '../icons/mycred-logo-dialog.svg';
import { ReactComponent as ProBoxBg } from '../icons/pro-box-bg.svg';

const UpgradeDialog = ({ open, handleClose }) => {
  return (
    <Dialog
      open={open}
      onClose={handleClose}
      disableScrollLock={true}
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
        '& .MuiBackdrop-root': {
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
        }
      }}
    >
      {/* Background SVG */}
      <ProBoxBg
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          zIndex: 0,
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
        {/* Positioned logo per spec */}
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
          <MyCredDialogLogo width={195} height={58.5742} />
        </Box>
        <IconButton
          aria-label="close"
          onClick={handleClose}
          sx={{ position: 'absolute', top: '16px', left: '558px', width: 24, height: 24, p: 0, color: '#fff' }}
        >
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent sx={{ position: 'static', width: '100%', zIndex: 1 }}>
        {/* Headline positioned per spec */}
        <Box
          sx={{
            position: 'absolute',
            top: '149px',
            left: '41px',
            width: '520px',
            height: '84px',
            color: '#FFFFFF',
            fontFamily: 'Figtree, sans-serif',
            fontWeight: 600,
            fontSize: '28px',
            lineHeight: '150%',
            letterSpacing: 0,
            textAlign: 'center',
          }}
        >
          <Box component="span" sx={{ color: '#FFC436' }}>Join Over 10,000+</Box> WordPress Site
          <br />
          <Box component="span" sx={{ whiteSpace: 'nowrap' }}>Owners to Gamify User Engagement</Box>
        </Box>

        {/* Button positioned per spec */}
        <Button
          onClick={() => {
            window.open('https://mycred.me/pricing/', '_blank');
          }}
          variant="contained"
          sx={{
            position: 'absolute',
            top: '265px',
            left: '206.5px',
            width: '190px',
            height: '48px',
            borderRadius: '45px',
            backgroundColor: '#F19C38',
            color: '#341883',
            fontWeight: 700,
            px: '31px',
            py: '12px',
            gap: '10px',
            fontSize: '14px',
            fontFamily: 'Figtree, sans-serif',
            textTransform: 'none',
          }}
        >
          Get myCred Pro
        </Button>
      </DialogContent>
    </Dialog>
  );
};

export default UpgradeDialog;
