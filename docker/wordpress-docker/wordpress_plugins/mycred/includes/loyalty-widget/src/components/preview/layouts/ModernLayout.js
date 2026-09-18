import { Fragment, useRef, useState, useCallback } from '@wordpress/element';
import { Box, Typography, IconButton, Paper, Button } from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import LeaderboardIcon from '@mui/icons-material/Leaderboard';
import { __ } from '@wordpress/i18n';
import { hexToRgba, HeroIllustration, themedSvgIconSx } from '../utils';

const formatBalanceValue = (balance) => balance.formatted ?? String(balance.balance ?? '0');

const GemIcon = () => (
    <Box
        component="svg"
        width={28}
        height={28}
        viewBox="0 0 48 48"
        fill="none"
        aria-hidden
    >
        <path d="M24 6L38 16v16L24 42 10 32V16L24 6z" fill="#8B5CF6" />
        <path d="M24 6L38 16l-14 6L10 16 24 6z" fill="#C4B5FD" opacity="0.9" />
        <path d="M24 22v20L10 32V16l14 6z" fill="#6D28D9" opacity="0.85" />
    </Box>
);

const ActionCard = ({ iconSrc, icon, label, accent, iconColor = '#1a1a1a', onClick, borderRadius }) => (
    <Paper
        elevation={0}
        onClick={onClick}
        sx={{
            p: '16px 14px',
            borderRadius: `${Math.max(12, borderRadius)}px`,
            bgcolor: '#fff',
            boxShadow: '0 4px 16px rgba(0,0,0,0.06)',
            border: '1px solid rgba(0,0,0,0.04)',
            cursor: 'pointer',
            display: 'flex',
            flexDirection: 'column',
            gap: 1.5,
            '&:hover .action-arrow': {
                transform: 'translateX(3px)',
            },
        }}
    >
        <Box sx={{ width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {iconSrc ? (
                <Box sx={{ ...themedSvgIconSx(iconSrc, 28), color: iconColor }} />
            ) : icon ? (
                icon
            ) : null}
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Typography sx={{ fontSize: 15, fontWeight: 600, color: '#1a1a1a', fontFamily: "'Instrument Sans', sans-serif" }}>
                {label}
            </Typography>
            <ChevronRightIcon
                className="action-arrow"
                sx={{ fontSize: 18, color: accent, transition: 'transform 0.2s ease' }}
            />
        </Box>
    </Paper>
);

const MoreRow = ({ iconSrc, icon: Icon, title, subtitle, accent, iconColor = '#666', onClick }) => (
    <Box
        onClick={onClick}
        sx={{
            display: 'flex',
            alignItems: 'center',
            gap: 1.5,
            width: '100%',
            px: 1.25,
            py: 1.25,
            borderRadius: '12px',
            cursor: 'pointer',
            '&:hover .action-arrow': {
                transform: 'translateX(3px)',
            },
            '& + &': { borderTop: '1px solid rgba(0,0,0,0.05)' },
        }}
    >
        <Box
            sx={{
                width: 38,
                height: 38,
                borderRadius: '50%',
                bgcolor: hexToRgba(iconColor, 0.12),
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
                color: iconColor,
            }}
        >
            {iconSrc ? (
                <Box sx={{ ...themedSvgIconSx(iconSrc, 18), color: iconColor }} />
            ) : Icon ? (
                <Icon sx={{ fontSize: 18, color: iconColor }} />
            ) : null}
        </Box>
        <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography sx={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a', lineHeight: 1.25, fontFamily: "'Instrument Sans', sans-serif" }}>
                {title}
            </Typography>
            {subtitle && (
                <Typography sx={{ fontSize: 11, color: '#888', mt: 0.25, fontFamily: "'Instrument Sans', sans-serif", overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {subtitle}
                </Typography>
            )}
        </Box>
        <ChevronRightIcon
            className="action-arrow"
            sx={{ fontSize: 16, color: accent, opacity: 0.8, transition: 'transform 0.2s ease', mr: 1 }}
        />
    </Box>
);

export default function ModernLayout({
    design = {},
    content = {},
    tabs = {},
    faq = {},
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
    borderRadius = 16,
}) {
    const bgColor = design.backgroundColor || '#1A1A1A';
    const textColor = design.textColor || '#FFFFFF';
    const btnColor = design.buttonColor || '#8B6F47';
    const btnTextColor = design.buttonTextColor || '#FFFFFF';
    const overlay = design.headerOverlayOpacity ?? 0;
    const headerImage = design.headerImageUrl || '';
    const programTitle = design.programTitle || __('Rewards Hub', 'mycred');
    const headerSubtitle = design.headerSubtitle || __('Welcome to', 'mycred');
    const tabControls = tabs.tabControls || {};
    const radius = Math.max(12, borderRadius);

    const showEarn = tabControls.earn !== false;
    const showRedeem = tabControls.redeem !== false && isPro;
    const showBoard = tabControls.board !== false;
    const showLogs = tabControls.logs !== false && !isGuest;
    const showFaq = tabControls.faq !== false;
    const showProfile = tabControls.profile !== false && !isGuest;
    const showRanks = ranksEnabled && tabControls.ranks !== false;
    const showBadges = badgesEnabled && tabControls.badges !== false;
    const pairBoardInRow = showBoard && !showRedeem;
    const showBoardPromo = showBoard && showRedeem;

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

    const primaryBalance = memberBalances[0];
    const secondaryBalances = memberBalances.slice(1);
    const isMulti = secondaryBalances.length > 0;

    const moreItems = [
        {
            key: 'profile',
            show: showProfile,
            svg: 'profile-icon.svg',
            label: content.profileLabel || __('Profile', 'mycred'),
            subtitle: content.profileMessage,
        },
        {
            key: 'ranks',
            show: showRanks,
            icon: LeaderboardIcon,
            label: content.ranksLabel || __('Ranks', 'mycred'),
            subtitle: content.ranksMessage,
        },
        {
            key: 'badges',
            show: showBadges,
            icon: EmojiEventsIcon,
            label: content.badgesLabel || __('Badges', 'mycred'),
            subtitle: content.badgesMessage,
        },
    ].filter((item) => item.show);

    const panelBg = '#F8F8F8';

    const HEADER_EXPANDED = 160;
    const HEADER_COLLAPSED = 48;
    const COLLAPSE_RANGE = 72;
    const CARD_OVERLAP = 36;

    const scrollRef = useRef(null);
    const [scrollY, setScrollY] = useState(0);

    const handleScroll = useCallback(() => {
        setScrollY(scrollRef.current?.scrollTop ?? 0);
    }, []);

    const collapse = Math.min(1, Math.max(0, scrollY / COLLAPSE_RANGE));
    const headerHeight = HEADER_EXPANDED - (HEADER_EXPANDED - HEADER_COLLAPSED) * collapse;
    const expandedFade = 1 - collapse;
    const collapsedFade = collapse;

    return (
        <Box sx={{ position: 'relative', height: '100%', overflow: 'hidden', bgcolor: panelBg }}>
            {/* Expanded Header BG Layer */}
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
                    background: headerImage ? undefined : bgColor,
                    backgroundImage: headerImage ? `url(${headerImage})` : 'none',
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    opacity: expandedFade,
                }} />
                {headerImage && (
                    <Box sx={{
                        position: 'absolute',
                        inset: 0,
                        bgcolor: `rgba(0,0,0,${overlay})`,
                        opacity: expandedFade,
                    }} />
                )}
                {/* Curve */}
                <Box sx={{
                    position: 'absolute',
                    left: 0,
                    right: 0,
                    bottom: -1,
                    height: 28,
                    bgcolor: panelBg,
                    borderRadius: '50% 50% 0 0 / 100% 100% 0 0',
                    opacity: expandedFade,
                }} />
            </Box>

            {/* Collapsed Header Bar */}
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

            {/* Header Chrome */}
            <Box sx={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                height: `${headerHeight}px`,
                zIndex: 11,
                px: 2.5,
                pt: 2,
                boxSizing: 'border-box',
                color: textColor,
                pointerEvents: 'none',
                '& .MuiIconButton-root, & button': { pointerEvents: 'auto' },
            }}>
                <Box sx={{
                    opacity: expandedFade,
                    transform: `translateY(${-collapse * 10}px)`,
                    pointerEvents: expandedFade < 0.1 ? 'none' : 'auto',
                }}>
                    <Box sx={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                        {showFaq ? (
                            <Box
                                component="button"
                                type="button"
                                onClick={() => onNavigate?.('faq')}
                                aria-label={faq?.screenTitle || __('FAQ', 'mycred')}
                                sx={{
                                    display: 'inline-flex',
                                    alignItems: 'center',
                                    gap: 0.75,
                                    border: '1px solid rgba(255,255,255,0.22)',
                                    bgcolor: 'rgba(255,255,255,0.95)',
                                    color: btnColor,
                                    fontFamily: "'Instrument Sans', sans-serif",
                                    fontSize: 11,
                                    fontWeight: 700,
                                    letterSpacing: '0.02em',
                                    px: 1.25,
                                    py: 0.6,
                                    pl: 0.85,
                                    borderRadius: 999,
                                    cursor: 'pointer',
                                    boxShadow: '0 4px 12px rgba(0,0,0,0.12)',
                                    transition: 'transform 0.15s ease, box-shadow 0.15s ease',
                                    '&:hover': {
                                        transform: 'translateY(-1px)',
                                        boxShadow: '0 6px 16px rgba(0,0,0,0.16)',
                                    },
                                }}
                            >
                                <Box
                                    sx={{
                                        width: 18,
                                        height: 18,
                                        borderRadius: '50%',
                                        bgcolor: btnColor,
                                        color: '#fff',
                                        display: 'inline-flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        fontSize: 11,
                                        fontWeight: 800,
                                        lineHeight: 1,
                                    }}
                                >
                                    ?
                                </Box>
                                {__('FAQ', 'mycred')}
                            </Box>
                        ) : (
                            <Box />
                        )}
                    </Box>

                    <Box sx={{ position: 'relative', display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 1.5, pr: 0.5 }}>
                        <Box>
                            <Typography sx={{ fontSize: 13, fontWeight: 400, opacity: 0.92, fontFamily: "'Instrument Sans', sans-serif" }}>
                                {headerSubtitle}
                            </Typography>
                            <Typography sx={{ fontSize: 26, fontWeight: 700, lineHeight: 1.2, letterSpacing: '-0.02em', mt: 0.25, fontFamily: "'Instrument Sans', sans-serif" }}>
                                {programTitle}
                            </Typography>
                        </Box>
                        {showLogs && (
                            <IconButton
                                size="small"
                                onClick={() => onNavigate?.('logs')}
                                aria-label={content.logsLabel || __('History', 'mycred')}
                                sx={{
                                    color: textColor,
                                    width: 34,
                                    height: 34,
                                    borderRadius: '10px',
                                    bgcolor: 'rgba(255,255,255,0.16)',
                                    border: '1px solid rgba(255,255,255,0.18)',
                                    mt: 0.5,
                                    flexShrink: 0,
                                    '&:hover': { bgcolor: 'rgba(255,255,255,0.26)' },
                                }}
                            >
                                <AccessTimeIcon sx={{ fontSize: 18 }} />
                            </IconButton>
                        )}
                    </Box>
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
                        right: 12,
                        top: 10,
                        pointerEvents: 'auto',
                        '&:hover': { bgcolor: 'rgba(255,255,255,0.12)' }
                    }}
                >
                    <CloseIcon fontSize="small" />
                </IconButton>
            </Box>

            {/* Scroll Container */}
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
                    pt: `${HEADER_EXPANDED - CARD_OVERLAP}px`,
                    px: 2,
                    pb: 2,
                    boxSizing: 'border-box',
                }}
            >
                {/* Member hero balances */}
                {!isGuest && primaryBalance && (
                    <Paper
                        elevation={0}
                        sx={{
                            mb: 1.5,
                            borderRadius: `${radius}px`,
                            bgcolor: '#fff',
                            boxShadow: '0 4px 16px rgba(0,0,0,0.06)',
                            border: '1px solid rgba(0,0,0,0.04)',
                            overflow: 'hidden',
                        }}
                    >
                        <Box
                            sx={{
                                display: 'flex',
                                alignItems: 'center',
                                gap: 1.75,
                                px: 2.25,
                                py: 2.25,
                                background: `radial-gradient(ellipse 80% 120% at 0% 0%, ${hexToRgba(btnColor, 0.18)}, transparent 55%), #fff`,
                            }}
                        >
                            <Box
                                sx={{
                                    width: 40,
                                    height: 40,
                                    borderRadius: '20px',
                                    border: '1px solid rgba(167,139,250,0.35)',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    flexShrink: 0,
                                }}
                            >
                                {(primaryBalance.image_url || primaryBalance.image || primaryBalance.icon) ? (
                                    <Box
                                        component="img"
                                        src={primaryBalance.image_url || primaryBalance.image || primaryBalance.icon}
                                        alt=""
                                        sx={{ width: 28, height: 28, objectFit: 'contain' }}
                                    />
                                ) : (
                                    <GemIcon />
                                )}
                            </Box>
                            <Box sx={{ flex: 1, minWidth: 0 }}>

                                <Typography sx={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.02em', color: '#1a1a1a', fontFamily: "'Instrument Sans', sans-serif" }}>
                                    {primaryBalance.label || __('Points', 'mycred')}
                                </Typography>

                            </Box>
                            <Box sx={{ textAlign: 'right', flexShrink: 0 }}>
                                <Typography sx={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.04em', lineHeight: 1, color: '#1a1a1a', fontFamily: "'Instrument Sans', sans-serif" }}>
                                    {formatBalanceValue(primaryBalance)}
                                </Typography>
                            </Box>
                        </Box>

                        {isMulti && (
                            <Box
                                sx={{
                                    display: 'grid',
                                    gridTemplateColumns: secondaryBalances.length === 1 ? '1fr' : '1fr 1fr',
                                    gap: 1,
                                    px: 1.5,
                                    pb: 1.5,
                                    background: 'linear-gradient(180deg, transparent, rgba(0,0,0,0.03))',
                                }}
                            >
                                {secondaryBalances.map((bal) => (
                                    <Box
                                        key={bal.type}
                                        sx={{
                                            display: 'flex',
                                            alignItems: 'center',
                                            gap: 1.25,
                                            px: 1.5,
                                            py: 1.25,
                                            borderRadius: '12px',
                                            bgcolor: '#fff',
                                            border: '1px solid rgba(0,0,0,0.05)',
                                            boxShadow: '0 2px 8px rgba(0,0,0,0.04)',
                                        }}
                                    >
                                        <Box
                                            sx={{
                                                width: 32,
                                                height: 32,
                                                borderRadius: '10px',
                                                bgcolor: hexToRgba(btnColor, 0.12),
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                flexShrink: 0,
                                            }}
                                        >
                                            {(bal.image_url || bal.image || bal.icon) ? (
                                                <Box component="img" src={bal.image_url || bal.image || bal.icon} alt="" sx={{ width: 18, height: 18, objectFit: 'contain' }} />
                                            ) : assetsUrl ? (
                                                <Box sx={{ ...themedSvgIconSx(assetsUrl + 'earn-icon.svg', 18), color: '#1a1a1a' }} />
                                            ) : (
                                                <EmojiEventsIcon sx={{ fontSize: 16, color: '#1a1a1a' }} />
                                            )}
                                        </Box>
                                        <Box sx={{ flex: 1, minWidth: 0 }}>
                                            <Typography sx={{ fontSize: 10, fontWeight: 600, color: '#888', textTransform: 'uppercase', letterSpacing: '0.04em', fontFamily: "'Instrument Sans', sans-serif" }}>
                                                {bal.label}
                                            </Typography>
                                            <Typography sx={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.02em', color: '#1a1a1a', fontFamily: "'Instrument Sans', sans-serif" }}>
                                                {formatBalanceValue(bal)}
                                            </Typography>
                                        </Box>
                                    </Box>
                                ))}
                            </Box>
                        )}
                    </Paper>
                )}

                {/* Guest join card */}
                {isGuest && (
                    <Paper
                        elevation={0}
                        sx={{
                            mb: 1.5,
                            p: '22px 18px 18px',
                            borderRadius: `${radius}px`,
                            bgcolor: '#fff',
                            boxShadow: '0 4px 16px rgba(0,0,0,0.06)',
                            border: '1px solid rgba(0,0,0,0.04)',
                            textAlign: 'center',
                        }}
                    >
                        <Box sx={{ mb: 1.75 }}>
                            <HeroIllustration heroImageUrl={design.heroImageUrl} assetsUrl={assetsUrl} variant="inline" size={88} />
                        </Box>
                        <Typography sx={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.02em', mb: 1, color: '#1a1a1a', fontFamily: "'Instrument Sans', sans-serif" }}>
                            {content.joinCardTitle || __('Join the Circle', 'mycred')}
                        </Typography>
                        <Typography sx={{ fontSize: 12, color: '#888', lineHeight: 1.5, mb: 2, maxWidth: 280, mx: 'auto', fontFamily: "'Instrument Sans', sans-serif" }}>
                            {content.joinCardDescription || content.welcomeMessage || __('First access to rare rewards, exclusive events, and privileges reserved for members.', 'mycred')}
                        </Typography>
                        <Button
                            fullWidth
                            variant="contained"
                            onClick={onPrimaryAction}
                            sx={{
                                bgcolor: btnColor,
                                color: btnTextColor,
                                textTransform: 'none',
                                boxShadow: `0 8px 20px ${hexToRgba(btnColor, 0.3)}`,
                                borderRadius: `${Math.max(8, radius - 4)}px`,
                                py: 1.5,
                                fontWeight: 600,
                                fontFamily: "'Instrument Sans', sans-serif",
                                mb: 1.5,
                                fontSize: '15px !important',
                                lineHeight: '1.4 !important',
                                whiteSpace: 'normal',
                                wordBreak: 'break-word',
                                minHeight: '48px',
                                '&:hover': { bgcolor: btnColor, boxShadow: `0 8px 20px ${hexToRgba(btnColor, 0.3)}` },
                            }}
                        >
                            {content.joinButtonText || __('Join now', 'mycred')}
                        </Button>
                        <Typography sx={{ fontSize: 12, color: '#888', fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('Already have an account? ', 'mycred')}
                            <Box component="span" onClick={onLoginClick} sx={{ fontWeight: 700, color: btnColor, cursor: 'pointer' }}>
                                {content.loginButtonText || __('Sign in', 'mycred')}
                            </Box>
                        </Typography>
                    </Paper>
                )}

                {isGuest && (showEarn || showRedeem || showBoard || moreItems.length > 0) && (
                    <Box sx={{ textAlign: 'center', mb: 1.5, mt: 0.25 }}>
                        <Typography sx={{ fontSize: 15, fontWeight: 700, color: '#1a1a1a', mb: 0.5, fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('Explore', 'mycred')}
                        </Typography>
                        <Typography sx={{ fontSize: 11, color: '#888', fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('Discover ways to earn, redeem, and track your rewards.', 'mycred')}
                        </Typography>
                    </Box>
                )}

                {/* Earn | Redeem when Redeem on; Earn | Board when Redeem off */}
                {(showEarn || showRedeem || pairBoardInRow) && (
                    <Box
                        sx={{
                            display: 'grid',
                            gridTemplateColumns: (showEarn && (showRedeem || pairBoardInRow)) ? '1fr 1fr' : '1fr',
                            gap: 1.5,
                            mb: 1.5,
                        }}
                    >
                        {showEarn && (
                            <ActionCard
                                iconSrc={assetsUrl ? assetsUrl + 'earn-icon.svg' : null}
                                label={content.earnLabel || __('Earn', 'mycred')}
                                accent={btnColor}
                                iconColor={bgColor}
                                borderRadius={radius}
                                onClick={() => onNavigate?.('earn')}
                            />
                        )}
                        {showRedeem && (
                            <ActionCard
                                iconSrc={assetsUrl ? assetsUrl + 'redeem-icon.svg' : null}
                                label={content.redeemLabel || __('Redeem', 'mycred')}
                                accent={btnColor}
                                iconColor={bgColor}
                                borderRadius={radius}
                                onClick={() => onNavigate?.('redeem')}
                            />
                        )}
                        {pairBoardInRow && (
                            <ActionCard
                                iconSrc={assetsUrl ? assetsUrl + 'board-icon.svg' : null}
                                label={content.boardLabel || __('Board', 'mycred')}
                                accent={btnColor}
                                iconColor={bgColor}
                                borderRadius={radius}
                                onClick={() => onNavigate?.('board')}
                            />
                        )}
                    </Box>
                )}

                {/* Board promo — only when Redeem takes the paired slot */}
                {showBoardPromo && (
                    <Paper
                        elevation={0}
                        onClick={() => onNavigate?.('board')}
                        sx={{
                            mb: 1.5,
                            p: '18px 16px',
                            borderRadius: `${radius}px`,
                            bgcolor: '#fff',
                            boxShadow: '0 4px 16px rgba(0,0,0,0.06)',
                            border: '1px solid rgba(0,0,0,0.04)',
                            display: 'flex',
                            alignItems: 'center',
                            gap: 1,
                            cursor: 'pointer',
                            '&:hover .action-arrow': {
                                transform: 'translateX(3px)',
                            },
                        }}
                    >
                        <Box sx={{ flex: 1, minWidth: 0 }}>
                            <Typography sx={{ fontSize: 16, fontWeight: 700, mb: 0.75, color: '#1a1a1a', fontFamily: "'Instrument Sans', sans-serif" }}>
                                {content.boardLabel || __('Board', 'mycred')}
                            </Typography>
                            <Typography sx={{ fontSize: 12, color: '#888', lineHeight: 1.45, mb: 1.25, fontFamily: "'Instrument Sans', sans-serif" }}>
                                {content.boardMessage || __('Check your standing and climb the leaderboard!', 'mycred')}
                            </Typography>
                            <Typography
                                className="action-arrow"
                                sx={{
                                    fontSize: 13,
                                    fontWeight: 600,
                                    color: btnColor,
                                    fontFamily: "'Instrument Sans', sans-serif",
                                    display: 'inline-block',
                                    transition: 'transform 0.2s ease',
                                }}
                            >
                                {__('View Board', 'mycred')}
                            </Typography>
                        </Box>
                        <Box sx={{ width: 70, height: 70, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            {assetsUrl ? (
                                <Box sx={{ ...themedSvgIconSx(assetsUrl + 'board-icon.svg', 48), color: bgColor }} />
                            ) : (
                                <LeaderboardIcon sx={{ fontSize: 40, color: bgColor }} />
                            )}
                        </Box>
                    </Paper>
                )}

                {/* More */}
                {moreItems.length > 0 && (
                    <Paper
                        elevation={0}
                        sx={{
                            borderRadius: `${radius}px`,
                            bgcolor: '#fff',
                            boxShadow: '0 4px 16px rgba(0,0,0,0.06)',
                            border: '1px solid rgba(0,0,0,0.04)',
                            px: 1.25,
                            pt: 1.75,
                            pb: 1.25,
                            overflow: 'hidden',
                        }}
                    >
                        <Box
                            className="more-header"
                            sx={{
                                display: 'flex',
                                alignItems: 'baseline',
                                justifyContent: 'space-between',
                                px: 1.25,
                                pb: 1.5,
                                '&:hover .action-arrow': {
                                    transform: 'translateX(3px)',
                                },
                            }}
                        >
                            <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1 }}>
                                <Typography sx={{ fontSize: 15, fontWeight: 700, color: '#1a1a1a', fontFamily: "'Instrument Sans', sans-serif" }}>
                                    {__('More', 'mycred')}
                                </Typography>
                                <Typography sx={{ fontSize: 11, color: '#aaa', fontWeight: 500, fontFamily: "'Instrument Sans', sans-serif" }}>
                                    {__('Quick links', 'mycred')}
                                </Typography>
                            </Box>
                        </Box>
                        {moreItems.map((item) => (
                            <Fragment key={item.key}>
                                <MoreRow
                                    iconSrc={item.svg && assetsUrl ? assetsUrl + item.svg : null}
                                    icon={item.icon}
                                    title={item.label}
                                    subtitle={item.subtitle}
                                    accent={btnColor}
                                    iconColor={bgColor}
                                    onClick={() => onNavigate?.(item.key)}
                                />
                            </Fragment>
                        ))}
                    </Paper>
                )}
            </Box>
        </Box>
    );
}
