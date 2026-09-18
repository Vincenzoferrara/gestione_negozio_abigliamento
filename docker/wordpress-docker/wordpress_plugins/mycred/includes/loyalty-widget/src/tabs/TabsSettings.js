import { useState } from '@wordpress/element';
import {
    Box,
    Typography,
    Paper,
    Tabs,
    Tab,
    Divider,
    TextField,
    Select,
    MenuItem,
    FormControl,
    Button,
} from '@mui/material';
import { __ } from '@wordpress/i18n';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import TabIcon from '@mui/icons-material/Tab';
import SaveIcon from '@mui/icons-material/Save';
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

const ToggleOption = ({ title, description, checked, onChange, showDivider = true, disabled = false }) => (
    <>
        <Box sx={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            py: 2,
            opacity: disabled ? 0.6 : 1,
            pointerEvents: disabled ? 'none' : 'auto'
        }}>
            <Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Typography sx={{ fontWeight: 600, fontSize: '15px', color: '#1a1a1a' }}>
                        {title}
                    </Typography>
                    {disabled && (
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
                <Typography sx={{ fontSize: '13px', color: '#666', mt: 0.5 }}>
                    {description}
                </Typography>
            </Box>
            <ToggleSwitch checked={checked} onChange={onChange} disabled={disabled} />
        </Box>
        {showDivider && <Divider />}
    </>
);
export default function TabsSettings() {
    const initialTabs = window.mycredLoyaltyWidgetData?.settings?.tabs || {};

    const [activeTab, setActiveTab] = useState(0);
    const [loading, setLoading] = useState(false);
    const isPro = window.mycredLoyaltyWidgetData?.is_toolkit_pro_active || false;

    const [tabControls, setTabControls] = useState({
        earn: initialTabs.tabControls?.earn !== undefined ? initialTabs.tabControls.earn : true,
        redeem: isPro ? (initialTabs.tabControls?.redeem !== undefined ? initialTabs.tabControls.redeem : true) : false,
        profile: initialTabs.tabControls?.profile !== undefined ? initialTabs.tabControls.profile : true,
        board: initialTabs.tabControls?.board !== undefined ? initialTabs.tabControls.board : true,
        logs: initialTabs.tabControls?.logs !== undefined ? initialTabs.tabControls.logs : true,
        badges: initialTabs.tabControls?.badges !== undefined ? initialTabs.tabControls.badges : true,
        ranks: initialTabs.tabControls?.ranks !== undefined ? initialTabs.tabControls.ranks : true,
        faq: initialTabs.tabControls?.faq !== undefined ? initialTabs.tabControls.faq : true,
    });

    const [leaderboardSettings, setLeaderboardSettings] = useState({
        numberOfUsers: initialTabs.boardSettings?.leaderboard?.numberOfUsers || 10,
        rankingOrder: initialTabs.boardSettings?.leaderboard?.rankingOrder || 'highest_first',
        positionOffset: initialTabs.boardSettings?.leaderboard?.positionOffset || 0,
        timeframeFilter: initialTabs.boardSettings?.leaderboard?.timeframeFilter || 'all_time',
        emptyMessage: initialTabs.boardSettings?.leaderboard?.emptyMessage || __('No users to display', 'mycred')
    });

    const [displayOptions, setDisplayOptions] = useState({
        showUserAvatar: initialTabs.boardSettings?.displayOptions?.showUserAvatar !== undefined ? initialTabs.boardSettings.displayOptions.showUserAvatar : true,
        showUserRank: initialTabs.boardSettings?.displayOptions?.showUserRank !== undefined ? initialTabs.boardSettings.displayOptions.showUserRank : true,
        showPointsBalance: initialTabs.boardSettings?.displayOptions?.showPointsBalance !== undefined ? initialTabs.boardSettings.displayOptions.showPointsBalance : true,
        highlightCurrentUser: initialTabs.boardSettings?.displayOptions?.highlightCurrentUser !== undefined ? initialTabs.boardSettings.displayOptions.highlightCurrentUser : true,
        filterByPointType: initialTabs.boardSettings?.displayOptions?.filterByPointType !== undefined ? initialTabs.boardSettings.displayOptions.filterByPointType : false
    });

    const handleTabChange = (event, newValue) => {
        setActiveTab(newValue);
    };

    const handleTabControlChange = (field) => (event) => {
        setTabControls(prev => ({
            ...prev,
            [field]: event.target.checked
        }));
    };

    const handleDisplayOptionChange = (field) => (event) => {
        setDisplayOptions(prev => ({
            ...prev,
            [field]: event.target.checked
        }));
    };

    const handleLeaderboardChange = (field, value) => {
        setLeaderboardSettings(prev => ({
            ...prev,
            [field]: value
        }));
    };

    const handleSave = async () => {
        setLoading(true);
        try {
            const dataToSave = {
                tabControls: tabControls,
                boardSettings: {
                    leaderboard: leaderboardSettings,
                    displayOptions: displayOptions
                }
            };
            const response = await saveSectionSettings('tabs', dataToSave);
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
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                {/* Tab Controls */}
                <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                    <SectionHeader
                        icon={TabIcon}
                        title={__('Tab Controls', 'mycred')}
                        desc={__('Enable or disable specific tabs in the widget', 'mycred')}
                    />

                    <Box sx={{ mt: 2 }}>
                        <ToggleOption
                            title={__('Earn Tab', 'mycred')}
                            description={__('Show the rewards and campaigns tab', 'mycred')}
                            checked={tabControls.earn}
                            onChange={handleTabControlChange('earn')}
                        />
                        <ToggleOption
                            title={__('Redeem Tab', 'mycred')}
                            description={isPro ? __('Show the rewards redemption tab', 'mycred') : __('Reward redemptions are available in Pro version', 'mycred')}
                            checked={tabControls.redeem}
                            onChange={handleTabControlChange('redeem')}
                            disabled={!isPro}
                        />
                        <ToggleOption
                            title={__('Board Tab', 'mycred')}
                            description={__('Show the leaderboard rankings', 'mycred')}
                            checked={tabControls.board}
                            onChange={handleTabControlChange('board')}
                        />
                        <ToggleOption
                            title={__('Logs Tab', 'mycred')}
                            description={__('Show the user activity and point logs', 'mycred')}
                            checked={tabControls.logs}
                            onChange={handleTabControlChange('logs')}
                        />
                        <ToggleOption
                            title={__('FAQ (only on card based template)', 'mycred')}
                            description={__('Show the FAQ pill on the Modern home header', 'mycred')}
                            checked={tabControls.faq}
                            onChange={handleTabControlChange('faq')}
                        />
                        <ToggleOption
                            title={__('Badges Tab', 'mycred')}
                            description={__('Show the badges and achievements tab', 'mycred')}
                            checked={tabControls.badges}
                            onChange={handleTabControlChange('badges')}
                        />
                        <ToggleOption
                            title={__('Profile Tab', 'mycred')}
                            description={__('Show the user profile and stats tab', 'mycred')}
                            checked={tabControls.profile}
                            onChange={handleTabControlChange('profile')}
                        />
                        <ToggleOption
                            title={__('Rank Tab', 'mycred')}
                            description={__('Show the user rank tab', 'mycred')}
                            checked={tabControls.ranks}
                            onChange={handleTabControlChange('ranks')}
                            showDivider={false}
                        />
                    </Box>
                </Paper>

                {/* Board Settings */}
                <Paper sx={{ p: 3, borderRadius: '12px', boxShadow: 'none', border: '1px solid #E0E0E0' }}>
                    <SectionHeader
                        icon={EmojiEventsIcon}
                        title={__('Board Settings', 'mycred')}
                    />

                    {/* Tabs for Leaderboard / Display Options */}
                    <Tabs
                        value={activeTab}
                        onChange={handleTabChange}
                        sx={{
                            mb: 3,
                            minHeight: 'auto',
                            '& .MuiTabs-indicator': {
                                backgroundColor: '#5E2CED',
                            },
                            '& .MuiTab-root': {
                                minHeight: 'auto',
                                py: 1.5,
                                px: 3,
                                textTransform: 'none',
                                fontSize: '14px',
                                fontWeight: 600,
                                color: '#666',
                                '&.Mui-selected': {
                                    color: '#5E2CED',
                                }
                            }
                        }}
                    >
                        <Tab label={__('Leaderboard', 'mycred')} />
                        <Tab label={__('Display Options', 'mycred')} />
                    </Tabs>

                    {/* Leaderboard Tab */}
                    {activeTab === 0 && (
                        <Box>
                            <SectionHeader
                                icon={EmojiEventsIcon}
                                title={__('Leaderboard Settings', 'mycred')}
                                desc={__('Configure how the leaderboard displays rankings and activity logs', 'mycred')}
                            />

                            <Box sx={{ mt: 2, display: 'flex', flexDirection: 'column', gap: 3 }}>
                                {/* Number of Users */}
                                <Box>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                        {__('Number of Users', 'mycred')}
                                    </Typography>
                                    <TextField
                                        type="number"
                                        fullWidth
                                        size="small"
                                        value={leaderboardSettings.numberOfUsers}
                                        onChange={(e) => handleLeaderboardChange('numberOfUsers', e.target.value)}
                                        inputProps={{ min: 1, max: 100 }}
                                        sx={{
                                            '& .MuiOutlinedInput-root': {
                                                borderRadius: '8px',
                                                height: '40px',
                                            },
                                        }}
                                    />
                                    <Typography sx={{ fontSize: '12px', color: '#666', mt: 1 }}>
                                        {__('Number of users to display in the leaderboard (1-100)', 'mycred')}
                                    </Typography>
                                </Box>

                                {/* Ranking Order */}
                                <Box>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                        {__('Ranking Order', 'mycred')}
                                    </Typography>
                                    <Select
                                        fullWidth
                                        size="small"
                                        value={leaderboardSettings.rankingOrder}
                                        onChange={(e) => handleLeaderboardChange('rankingOrder', e.target.value)}
                                        sx={{
                                            borderRadius: '8px',
                                            '& .MuiOutlinedInput-notchedOutline': {
                                                borderColor: '#e0e0e0',
                                            },
                                        }}
                                    >
                                        <MenuItem value="highest_first">{__('Descending (Highest First)', 'mycred')}</MenuItem>
                                        <MenuItem value="lowest_first">{__('Ascending (Lowest First)', 'mycred')}</MenuItem>
                                    </Select>
                                </Box>

                                {/* Position Offset */}
                                <Box>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                        {__('Position Offset', 'mycred')}
                                    </Typography>
                                    <TextField
                                        type="number"
                                        fullWidth
                                        size="small"
                                        value={leaderboardSettings.positionOffset}
                                        onChange={(e) => handleLeaderboardChange('positionOffset', e.target.value)}
                                        inputProps={{ min: 0 }}
                                        sx={{
                                            '& .MuiOutlinedInput-root': {
                                                borderRadius: '8px',
                                                height: '40px',
                                            },
                                        }}
                                    />
                                    <Typography sx={{ fontSize: '12px', color: '#666', mt: 1 }}>
                                        {__('Skip first N positions (useful for showing different sections)', 'mycred')}
                                    </Typography>
                                </Box>

                                {/* Timeframe Filter */}
                                <Box>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                        {__('Timeframe Filter', 'mycred')}
                                    </Typography>
                                    <Select
                                        fullWidth
                                        size="small"
                                        value={leaderboardSettings.timeframeFilter}
                                        onChange={(e) => handleLeaderboardChange('timeframeFilter', e.target.value)}
                                        sx={{
                                            borderRadius: '8px',
                                            '& .MuiOutlinedInput-notchedOutline': {
                                                borderColor: '#e0e0e0',
                                            },
                                        }}
                                    >
                                        <MenuItem value="all_time">{__('All Time', 'mycred')}</MenuItem>
                                        <MenuItem value="today">{__('Today', 'mycred')}</MenuItem>
                                        <MenuItem value="this_week">{__('This Week', 'mycred')}</MenuItem>
                                        <MenuItem value="this_month">{__('This Month', 'mycred')}</MenuItem>
                                        <MenuItem value="this_year">{__('This Year', 'mycred')}</MenuItem>
                                    </Select>
                                    <Typography sx={{ fontSize: '12px', color: '#666', mt: 1 }}>
                                        {__('Filter rankings by time period', 'mycred')}
                                    </Typography>
                                </Box>

                                {/* Empty Message */}
                                <Box>
                                    <Typography sx={{ fontSize: '14px', fontWeight: 600, mb: 1, color: '#1a1a1a' }}>
                                        {__('Empty Message', 'mycred')}
                                    </Typography>
                                    <TextField
                                        fullWidth
                                        size="small"
                                        value={leaderboardSettings.emptyMessage}
                                        onChange={(e) => handleLeaderboardChange('emptyMessage', e.target.value)}
                                        sx={{
                                            '& .MuiOutlinedInput-root': {
                                                borderRadius: '8px',
                                                height: '40px',
                                            },
                                        }}
                                    />
                                    <Typography sx={{ fontSize: '12px', color: '#666', mt: 1 }}>
                                        {__('Message shown when no users are in the leaderboard', 'mycred')}
                                    </Typography>
                                </Box>
                            </Box>
                        </Box>
                    )}

                    {/* Display Options Tab */}
                    {activeTab === 1 && (
                        <Box>
                            <SectionHeader
                                icon={EmojiEventsIcon}
                                title={__('Display Options', 'mycred')}
                                desc={__('Control what information is shown on the leaderboard', 'mycred')}
                            />

                            <Box sx={{ mt: 2 }}>
                                <ToggleOption
                                    title={__('Show User Avatar', 'mycred')}
                                    description={__('Show user avatar in the leaderboard', 'mycred')}
                                    checked={displayOptions.showUserAvatar}
                                    onChange={handleDisplayOptionChange('showUserAvatar')}
                                />
                                <ToggleOption
                                    title={__('Show User Rank', 'mycred')}
                                    description={__('Display user rank/level', 'mycred')}
                                    checked={displayOptions.showUserRank}
                                    onChange={handleDisplayOptionChange('showUserRank')}
                                />
                                <ToggleOption
                                    title={__('Show Points Balance', 'mycred')}
                                    description={__('Display the current points balance of the user', 'mycred')}
                                    checked={displayOptions.showPointsBalance}
                                    onChange={handleDisplayOptionChange('showPointsBalance')}
                                />
                                <ToggleOption
                                    title={__('Highlight Current User', 'mycred')}
                                    description={__('Visually highlight the current user in the leaderboard', 'mycred')}
                                    checked={displayOptions.highlightCurrentUser}
                                    onChange={handleDisplayOptionChange('highlightCurrentUser')}
                                />
                                <ToggleOption
                                    title={__('Filter by Point Type', 'mycred')}
                                    description={__('Allow users to switch between different point types', 'mycred')}
                                    checked={displayOptions.filterByPointType}
                                    onChange={handleDisplayOptionChange('filterByPointType')}
                                    showDivider={false}
                                />
                            </Box>
                        </Box>
                    )}
                </Paper>

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
