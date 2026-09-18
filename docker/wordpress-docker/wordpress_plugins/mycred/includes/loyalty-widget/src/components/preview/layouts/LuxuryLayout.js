import { useState, useRef, useCallback, Fragment } from '@wordpress/element';
import { Box, Typography, IconButton, Paper, Button, Divider } from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import LeaderboardIcon from '@mui/icons-material/Leaderboard';
import { __ } from '@wordpress/i18n';
import { hexToRgba, HeroIllustration, themedSvgIconSx } from '../utils';

const formatBalanceValue = (balance) => {
    return balance.formatted ?? String(balance.balance ?? '0');
};

const MemberBalanceCards = ({ balances, btnColor, borderRadius, assetsUrl }) => (
    <Paper
        elevation={0}
        sx={{
            display: 'flex',
            flexDirection: 'column',
            width: '100%',
            mb: 0,
            borderRadius: `${borderRadius}px`,
            bgcolor: '#fff',
            boxShadow: '0px 8px 24px rgba(0,0,0,0.06)',
            boxSizing: 'border-box',
            overflow: 'hidden',
        }}
    >
        {balances.map((balance, index) => (
            <Fragment key={balance.type}>
                <Box
                    sx={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        width: '100%',
                        px: 2.5,
                        py: balances.length === 1 ? 3.5 : 2,
                        boxSizing: 'border-box',
                    }}
                >
                    <Box sx={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flexShrink: 0,
                        mr: 2,
                    }}>
                        {balance.image_url || balance.image || balance.icon ? (
                            <Box component="img" src={balance.image_url || balance.image || balance.icon} alt={balance.label} sx={{ width: 22, height: 22, objectFit: 'contain' }} />
                        ) : assetsUrl ? (
                            <Box sx={{ ...themedSvgIconSx(assetsUrl + 'earn-icon.svg', 22), color: '#1a1a1a' }} />
                        ) : (
                            <EmojiEventsIcon sx={{ fontSize: 22, color: '#1a1a1a' }} />
                        )}
                    </Box>
                    <Typography
                        component="span"
                        sx={{
                            fontSize: '14px',
                            fontWeight: 600,
                            color: '#1a1a1a',
                            fontFamily: "'Instrument Sans', sans-serif",
                            lineHeight: 1.2,
                            flex: 1,
                        }}
                    >
                        {balance.label}
                    </Typography>
                    <Typography
                        component="span"
                        sx={{
                            fontSize: '14px',
                            fontWeight: 700,
                            color: '#1a1a1a',
                            fontFamily: "'Instrument Sans', sans-serif",
                            lineHeight: 1.2,
                            textAlign: 'right',
                            flexShrink: 0,
                            ml: 2,
                        }}
                    >
                        {formatBalanceValue(balance)}
                    </Typography>
                </Box>
                {index < balances.length - 1 && (
                    <Box sx={{ mx: 2.5, height: '1px', bgcolor: '#F0F0F0' }} />
                )}
            </Fragment>
        ))}
    </Paper>
);

const LuxuryListRow = ({ icon: Icon, iconSrc, title, subtitle, btnColor, onClick }) => (
    <Box
        onClick={onClick}
        sx={{
            display: 'flex',
            alignItems: 'center',
            gap: 1.5,
            py: 1.35,
            borderBottom: '1px solid #F0F0F0',
            cursor: onClick ? 'pointer' : 'default',
            transition: 'background-color 0.15s ease',
            mx: -1,
            px: 1,
            borderRadius: '8px',
            '&:last-child': { borderBottom: 'none' },
            '&:hover': onClick ? { bgcolor: hexToRgba(btnColor, 0.05) } : {},
        }}
    >
        <Box sx={{
            width: 36,
            height: 36,
            borderRadius: '50%',
            bgcolor: hexToRgba(btnColor, 0.1),
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
        }}>
            {iconSrc ? (
                <Box sx={{ ...themedSvgIconSx(iconSrc, 18), color: btnColor }} />
            ) : Icon ? (
                <Icon sx={{ fontSize: 18, color: btnColor }} />
            ) : null}
        </Box>
        <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography sx={{ fontSize: '14px', fontWeight: 600, color: '#1a1a1a', fontFamily: "'Instrument Sans', sans-serif", lineHeight: 1.3 }}>
                {title}
            </Typography>
            {subtitle && (
                <Typography sx={{ fontSize: '12px', color: '#888', mt: 0.25, fontFamily: "'Instrument Sans', sans-serif" }}>
                    {subtitle}
                </Typography>
            )}
        </Box>
        <ChevronRightIcon sx={{ fontSize: 18, color: '#C4C4C4', flexShrink: 0 }} />
    </Box>
);

const LuxuryNavCard = ({ icon: Icon, iconSrc, title, subtitle, btnColor, borderRadius, onClick }) => (
    <Paper
        elevation={0}
        onClick={onClick}
        sx={{
            display: 'flex',
            alignItems: 'center',
            gap: 1.5,
            px: 2,
            py: 2,
            borderRadius: `${borderRadius}px`,
            bgcolor: '#fff',
            boxShadow: '0px 2px 8px rgba(0,0,0,0.04)',
            cursor: onClick ? 'pointer' : 'default',
            '&:hover .nav-arrow': onClick ? { transform: 'translateX(4px)' } : {},
        }}
    >
        <Box sx={{
            width: 36,
            height: 36,
            borderRadius: '50%',
            bgcolor: hexToRgba(btnColor, 0.1),
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
        }}>
            {iconSrc ? (
                <Box sx={{ ...themedSvgIconSx(iconSrc, 18), color: btnColor }} />
            ) : Icon ? (
                <Icon sx={{ fontSize: 18, color: btnColor }} />
            ) : null}
        </Box>
        <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography sx={{ fontSize: '14px', fontWeight: 600, color: '#1a1a1a', fontFamily: "'Instrument Sans', sans-serif" }}>
                {title}
            </Typography>
            {subtitle && (
                <Typography sx={{ fontSize: '12px', color: '#888', mt: 0.25, fontFamily: "'Instrument Sans', sans-serif" }}>
                    {subtitle}
                </Typography>
            )}
        </Box>
        <ChevronRightIcon className="nav-arrow" sx={{ fontSize: 18, color: '#1a1a1a', flexShrink: 0, transition: 'transform 0.2s ease' }} />
    </Paper>
);

export default function LuxuryLayout({
    design = {},
    content = {},
    tabs = {},
    user = {},
    isGuest,
    assetsUrl = '',
    isPro = false,
    ranksEnabled = true,
    badgesEnabled = true,
    onNavigate,
    onClose,
    onPrimaryAction,
    onLoginClick,
    borderRadius = 12,
}) {
    const bgColor = design.backgroundColor || '#1A1A1A';
    const textColor = design.textColor || '#FFFFFF';
    const btnColor = design.buttonColor || '#8B6F47';
    const btnTextColor = design.buttonTextColor || '#FFFFFF';
    const overlay = design.headerOverlayOpacity ?? 0.55;
    const headerImage = design.headerImageUrl || '';
    const programTitle = design.programTitle || __('Rewards Hub', 'mycred');
    const tabControls = tabs.tabControls || {};

    const navItems = [
        { key: 'earn', show: tabControls.earn !== false, svg: 'earn-icon.svg', label: content.earnLabel || __('Earn', 'mycred'), subtitle: content.earnMessage },
        { key: 'redeem', show: tabControls.redeem !== false && isPro, svg: 'redeem-icon.svg', label: content.redeemLabel || __('Redeem', 'mycred'), subtitle: content.redeemMessage },
        { key: 'board', show: tabControls.board !== false, svg: 'board-icon.svg', label: content.boardLabel || __('Board', 'mycred'), subtitle: content.boardMessage },
        { key: 'logs', show: tabControls.logs !== false && !isGuest, svg: 'logs-icon.svg', label: content.logsLabel || __('History', 'mycred'), subtitle: content.logsMessage },
        { key: 'profile', show: tabControls.profile !== false && !isGuest, svg: 'profile-icon.svg', label: content.profileLabel || __('Profile', 'mycred'), subtitle: content.profileMessage },
        { key: 'ranks', show: ranksEnabled && tabControls.ranks !== false, icon: LeaderboardIcon, label: content.ranksLabel || __('Ranks', 'mycred'), subtitle: content.ranksMessage },
        { key: 'badges', show: badgesEnabled && tabControls.badges !== false, icon: EmojiEventsIcon, label: content.badgesLabel || __('Badges', 'mycred'), subtitle: content.badgesMessage },
    ].filter((item) => item.show);

    const showExplore = navItems.length > 0;
    const ranksTabEnabled = ranksEnabled && tabControls.ranks !== false;
    const showPrimaryCta = isGuest || content.showDashboardButton !== false;

    const memberBalances = !isGuest
        ? (user.all_balances?.length
            ? user.all_balances
            : (user.formatted_balance != null || user.balance != null
                ? [{
                    type: 'mycred_default',
                    label: user.point_label || __('Points', 'mycred'),
                    formatted: user.formatted_balance ?? String(user.balance ?? 0),
                }]
                : []))
        : [];

    const HEADER_EXPANDED = 110;
    const HEADER_COLLAPSED = 48;
    const CARD_TOP_GAP = 12;
    const COLLAPSE_RANGE = 64;

    const scrollRef = useRef(null);
    const [scrollY, setScrollY] = useState(0);

    const handleScroll = useCallback(() => {
        setScrollY(scrollRef.current?.scrollTop ?? 0);
    }, []);

    const collapse = Math.min(1, Math.max(0, scrollY / COLLAPSE_RANGE));
    const headerHeight = HEADER_EXPANDED - (HEADER_EXPANDED - HEADER_COLLAPSED) * collapse;
    const expandedFade = 1 - collapse;
    const collapsedFade = collapse;
    const headerPaddingX = 24 - 8 * collapse;
    const headerPaddingY = 24 - 12 * collapse;

    return (
        <Box sx={{ position: 'relative', height: '100%', overflow: 'hidden', bgcolor: '#F8F6FF' }}>
            <Box sx={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                height: `${HEADER_EXPANDED}px`,
                zIndex: 0,
                overflow: 'hidden',
            }}>
                <Box sx={{
                    position: 'absolute',
                    inset: 0,
                    bgcolor: bgColor,
                    backgroundImage: headerImage ? `url(${headerImage})` : 'none',
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    opacity: expandedFade,
                }} />
                <Box sx={{
                    position: 'absolute',
                    inset: 0,
                    bgcolor: headerImage ? `rgba(0,0,0,${overlay})` : 'transparent',
                    opacity: expandedFade,
                }} />
            </Box>

            <Box sx={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                height: `${headerHeight}px`,
                zIndex: 10,
                pointerEvents: 'none',
                boxShadow: collapse > 0.5 ? '0 2px 12px rgba(0,0,0,0.14)' : 'none',
            }}>
                <Box sx={{
                    position: 'absolute',
                    inset: 0,
                    bgcolor: bgColor,
                    opacity: collapsedFade,
                }} />
            </Box>

            <Box sx={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                height: `${headerHeight}px`,
                zIndex: 11,
                px: `${headerPaddingX}px`,
                py: `${headerPaddingY}px`,
                boxSizing: 'border-box',
                color: textColor,
                pointerEvents: 'none',
                '& .MuiIconButton-root': { pointerEvents: 'auto' },
            }}>
                <Box sx={{
                    position: 'absolute',
                    left: `${headerPaddingX}px`,
                    right: 48,
                    top: `${headerPaddingY}px`,
                    opacity: expandedFade,
                    transform: `translateY(${-collapse * 10}px)`,
                    overflow: 'hidden',
                    pointerEvents: expandedFade < 0.1 ? 'none' : 'auto',
                }}>
                    <Typography sx={{
                        fontSize: '12px',
                        opacity: 0.9,
                        fontFamily: "'Instrument Sans', sans-serif",
                        lineHeight: 1.3,
                    }}>
                        {design.headerSubtitle || __('Welcome to', 'mycred')}
                    </Typography>
                    <Typography sx={{
                        fontSize: `${24 - 8 * collapse}px`,
                        fontWeight: 700,
                        fontFamily: "'Instrument Sans', sans-serif",
                        mt: 0.5,
                        lineHeight: 1.2,
                    }}>
                        {programTitle}
                    </Typography>
                </Box>

                <Typography sx={{
                    position: 'absolute',
                    left: 48,
                    right: 48,
                    top: '50%',
                    transform: 'translateY(-50%)',
                    fontSize: '15px',
                    fontWeight: 700,
                    fontFamily: "'Instrument Sans', sans-serif",
                    lineHeight: 1.2,
                    textAlign: 'center',
                    opacity: collapsedFade,
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                    pointerEvents: 'none',
                }}>
                    {programTitle}
                </Typography>

                <IconButton
                    size="small"
                    onClick={onClose}
                    sx={{
                        color: textColor,
                        position: 'absolute',
                        right: 8,
                        top: '50%',
                        transform: 'translateY(-50%)',
                        pointerEvents: 'auto',
                    }}
                >
                    <CloseIcon fontSize="small" />
                </IconButton>
            </Box>

            <Box
                ref={scrollRef}
                onScroll={handleScroll}
                sx={{
                    position: 'relative',
                    zIndex: 1,
                    height: '100%',
                    overflowY: 'auto',
                    overflowX: 'hidden',
                    overscrollBehavior: 'contain',
                    WebkitOverflowScrolling: 'touch',
                    scrollbarWidth: 'none',
                    '&::-webkit-scrollbar': { display: 'none' },
                    pt: `${HEADER_EXPANDED - 24}px`,
                    boxSizing: 'border-box',
                    px: '24px',
                    pb: '24px',
                }}
            >
                {!isGuest && memberBalances.length > 0 && (
                    <Box sx={{ mb: 0 }}>
                        <MemberBalanceCards balances={memberBalances} btnColor={btnColor} borderRadius={borderRadius} assetsUrl={assetsUrl} />
                        <Divider sx={{ mt: 3, mb: 1, borderColor: 'rgba(0,0,0,0.06)' }} />
                    </Box>
                )}

                {isGuest && (
                    <Paper elevation={0} sx={{
                        p: '24px', borderRadius: `${borderRadius}px`, bgcolor: '#fff',
                        boxShadow: '0px 2px 8px rgba(0,0,0,0.04)', mb: 2, textAlign: 'center',
                        display: 'flex', flexDirection: 'column', alignItems: 'stretch',
                    }}>
                        <Typography sx={{ fontSize: '16px', fontWeight: 700, color: '#1a1a1a', mb: 1, fontFamily: "'Instrument Sans', sans-serif" }}>
                            {content.joinCardTitle || __('Join the Circle', 'mycred')}
                        </Typography>
                        <Typography sx={{ fontSize: '13px', color: '#666', mb: 2.5, lineHeight: 1.5, fontFamily: "'Instrument Sans', sans-serif" }}>
                            {content.joinCardDescription || content.welcomeMessage || __('First access to rare rewards, exclusive events, and privileges reserved for members.', 'mycred')}
                        </Typography>

                        <Box sx={{ width: '100%', mb: 3, mt: 0.5 }}>
                            <HeroIllustration heroImageUrl={design.heroImageUrl} assetsUrl={assetsUrl} variant="inline" size={100} />
                        </Box>

                        <Button fullWidth variant="contained" onClick={onPrimaryAction} sx={{
                            bgcolor: btnColor, color: btnTextColor, textTransform: 'none', boxShadow: 'none',
                            borderRadius: `${Math.max(8, borderRadius - 4)}px`, py: 1.5, fontWeight: 600,
                            fontFamily: "'Instrument Sans', sans-serif", mb: 1.5,
                            fontSize: '15px !important', lineHeight: '1.4 !important',
                            whiteSpace: 'normal', wordBreak: 'break-word', minHeight: '48px',
                            '&:hover': { bgcolor: btnColor, boxShadow: 'none' },
                        }}>
                            {content.joinButtonText || __('Join now', 'mycred')}
                        </Button>

                        <Typography sx={{ fontSize: '13px', color: '#666' }}>
                            {__('Already have an account? ', 'mycred')}
                            <Box component="span" onClick={onLoginClick} sx={{ fontWeight: 600, color: btnColor, cursor: 'pointer' }}>
                                {content.loginButtonText || __('Sign in', 'mycred')}
                            </Box>
                        </Typography>
                    </Paper>
                )}

                {showExplore && (
                    <Box>
                        {isGuest && (
                            <Fragment>
                                <Typography sx={{
                                    fontSize: '16px',
                                    fontWeight: 700,
                                    color: '#1a1a1a',
                                    textAlign: 'center',
                                    mb: 0.5,
                                    fontFamily: "'Instrument Sans', sans-serif",
                                }}>
                                    {__('Explore', 'mycred')}
                                </Typography>
                                <Typography sx={{ fontSize: '12px', color: '#666', textAlign: 'center', mb: 1.5, fontFamily: "'Instrument Sans', sans-serif" }}>
                                    {__('Discover ways to earn, redeem, and track your rewards.', 'mycred')}
                                </Typography>
                            </Fragment>
                        )}
                        <Box sx={{ 
                            display: 'flex', flexDirection: 'column', gap: 1.5, mt: isGuest ? 0 : 2,
                            '& > *': {
                                animation: 'slideKeyframe 0.5s cubic-bezier(0.16, 1, 0.3, 1) both',
                            },
                            ...Array.from({ length: 10 }).reduce((acc, _, i) => ({
                                ...acc,
                                [`& > *:nth-of-type(${i + 1})`]: { animationDelay: `${i * 0.05}s` }
                            }), {})
                        }}>
                            {navItems.map((item) => (
                                <LuxuryNavCard
                                    key={item.key}
                                    icon={item.icon}
                                    iconSrc={item.svg ? assetsUrl + item.svg : null}
                                    title={item.label}
                                    subtitle={item.subtitle}
                                    btnColor={btnColor}
                                    borderRadius={borderRadius}
                                    onClick={() => onNavigate?.(item.key)}
                                />
                            ))}
                        </Box>
                    </Box>
                )}
            </Box>
        </Box>
    );
}
