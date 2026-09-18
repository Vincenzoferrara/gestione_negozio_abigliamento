import { Switch } from '@mui/material';
import { styled } from '@mui/material/styles';

/** Shared admin toggle — compact 32×16, purple active state (all settings tabs). */
const ToggleSwitch = styled(Switch)(({ theme }) => ({
    width: 32,
    height: 16,
    padding: 0,
    display: 'flex',
    '&:active': {
        '& .MuiSwitch-thumb': {
            width: 12,
        },
        '& .MuiSwitch-switchBase.Mui-checked': {
            transform: 'translateX(16px)',
        },
    },
    '& .MuiSwitch-switchBase': {
        padding: 2,
        transform: 'translateX(0px)',
        '&.Mui-checked': {
            transform: 'translateX(16px)',
            color: '#fff',
            '& + .MuiSwitch-track': {
                opacity: 1,
                backgroundColor: '#5E2CED',
            },
        },
    },
    '& .MuiSwitch-thumb': {
        boxShadow: '0 2px 4px 0 rgb(0 35 11 / 20%)',
        width: 12,
        height: 12,
        borderRadius: 6,
        transition: theme.transitions.create(['width'], {
            duration: 200,
        }),
    },
    '& .MuiSwitch-track': {
        borderRadius: 9.33,
        opacity: 1,
        backgroundColor: '#E0E0E0',
        boxSizing: 'border-box',
    },
}));

export default ToggleSwitch;
