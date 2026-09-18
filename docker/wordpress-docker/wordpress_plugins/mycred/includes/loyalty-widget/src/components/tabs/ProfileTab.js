import { useState, useEffect } from '@wordpress/element';
import { Box, Typography, Paper, IconButton, Skeleton } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CloseIcon from '@mui/icons-material/Close';
import { __ } from '@wordpress/i18n';
import { getRankStyle } from '../preview/utils';

/* ─── Guest screen ───────────────────────────────────────────────── */
function GuestProfile({ btnColor, bgColor, currentContent, onBack, onClose }) {
    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: bgColor }}>
            <Header title={currentContent.profileMessage || __('Profile', 'mycred')}
                    btnColor={btnColor} onBack={onBack} onClose={onClose} />
            <Box sx={{ flex: 1, bgcolor: '#F8F6FF', borderRadius: '28px 28px 0 0', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 2, p: '24px' }}>
                <Box sx={{ width: 80, height: 80, borderRadius: '50%', bgcolor: `${btnColor}22`, display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 1 }}>
                    <Typography sx={{ fontSize: '40px' }}>👤</Typography>
                </Box>
                <Typography sx={{ fontSize: '16px', fontWeight: 600, color: btnColor, fontFamily: "'Instrument Sans', sans-serif" }}>
                    {__('You are not logged in', 'mycred')}
                </Typography>
                <Typography sx={{ fontSize: '13px', color: '#8670C4', textAlign: 'center', fontFamily: "'Instrument Sans', sans-serif" }}>
                    {__('Sign in or create an account to track your points, ranks and badges.', 'mycred')}
                </Typography>
                <Box
                    onClick={() => { if (currentContent.loginRedirect) window.location.href = currentContent.loginRedirect; }}
                    sx={{
                        mt: 1, px: '28px', py: '11px', bgcolor: btnColor, borderRadius: '10px',
                        cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 1,
                    }}
                >
                    <Typography sx={{ fontSize: '14px', fontWeight: 600, color: '#fff', fontFamily: "'Instrument Sans', sans-serif" }}>
                        {currentContent.loginButtonText || __('Sign In', 'mycred')}
                    </Typography>
                </Box>
            </Box>
        </Box>
    );
}

/* ─── Shared header ──────────────────────────────────────────────── */
function Header({ title, subtitle, btnColor, onBack, onClose }) {
    const isRtl = document?.documentElement?.dir === 'rtl';
    return (
        <Box sx={{ px: '24px', pt: '20px', pb: '16px', position: 'relative' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <IconButton size="small" onClick={onBack} sx={{ color: '#fff', p: 0 }}>
                    <ArrowBackIcon sx={{ fontSize: '20px', transform: isRtl ? 'scaleX(-1)' : 'none' }} />
                </IconButton>
                <Typography sx={{ fontSize: '16px', fontWeight: 600, color: '#fff', fontFamily: "'Instrument Sans', sans-serif" }}>
                    {title}
                </Typography>
            </Box>
            <IconButton size="small" onClick={onClose}
                sx={{ position: 'absolute', insetInlineEnd: '20px', top: '18px', color: '#fff', p: 0 }}>
                <CloseIcon sx={{ fontSize: '20px' }} />
            </IconButton>
        </Box>
    );
}

/* ─── Stat card ──────────────────────────────────────────────────── */
function StatCard({ label, value, color }) {
    return (
        <Box sx={{
            flex: 1,
            bgcolor: '#fff',
            borderRadius: '14px',
            border: '1.5px solid #F0EEFF',
            p: '14px 12px',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '2px',
            boxShadow: '0px 2px 8px rgba(94,44,237,0.04)',
        }}>
            <Typography sx={{ fontSize: '20px', fontWeight: 800, color: color || '#5E2CED', fontFamily: "'Instrument Sans', sans-serif", lineHeight: 1.2 }}>
                {value}
            </Typography>
            <Typography sx={{ fontSize: '11px', color: '#8670C4', fontFamily: "'Instrument Sans', sans-serif", textAlign: 'center' }}>
                {label}
            </Typography>
        </Box>
    );
}

/* ─── Main export ────────────────────────────────────────────────── */
export default function ProfileTab({ user, settings, currentContent, onBack, onClose }) {
    currentContent = currentContent || {};
    const design   = settings.design || {};
    const btnColor = design.buttonColor || '#5E2CED';
    const bgColor  = design.backgroundColor || '#2D1572';

    // ---- Guest ----
    if (!user?.is_logged_in) {
        return <GuestProfile btnColor={btnColor} bgColor={bgColor} currentContent={currentContent} onBack={onBack} onClose={onClose} />;
    }

    const rankStyle    = getRankStyle(user.rank, btnColor);
    const rankMin      = user.rank_min || 0;
    const rankMax      = user.rank_max || 0;
    const balance      = user.balance  || 0;
    const allBalances  = user.all_balances || [];
    const badges       = user.badges   || [];

    // Addon feature flags
    const addons        = window.mycredLoyaltyWidget?.addons || {};
    const ranksEnabled  = !!addons.ranks_enabled;
    const badgesEnabled = !!addons.badges_enabled;

    // Progress percentage toward next rank threshold
    const progressPct  = (rankMax > rankMin && balance >= rankMin)
        ? Math.min(100, Math.round(((balance - rankMin) / (rankMax - rankMin)) * 100))
        : 0;
    const showProgress = rankMax > 0;

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: bgColor }}>
            <Header
                title={currentContent.profileMessage || __('Profile', 'mycred')}
                subtitle={user.display_name || ''}
                btnColor={btnColor}
                onBack={onBack}
                onClose={onClose}
            />

            {/* Scrollable content */}
            <Box sx={{
                flex: 1,
                bgcolor: '#F8F6FF',
                borderRadius: '28px 28px 0 0',
                overflowY: 'auto',
                scrollbarWidth: 'none',
                '&::-webkit-scrollbar': { display: 'none' },
                p: '20px 16px 24px',
                display: 'flex',
                flexDirection: 'column',
                gap: '14px',
            }}>

                {/* ── Avatar + Name card ─────────────────────────── */}
                <Paper elevation={0} sx={{
                    borderRadius: '20px',
                    border: '1.5px solid #EDE8FF',
                    bgcolor: '#fff',
                    p: '20px 16px 16px',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '10px',
                    boxShadow: '0px 4px 16px rgba(94,44,237,0.06)',
                }}>
                    {/* Avatar with optional rank image badge */}
                    <Box sx={{ position: 'relative', display: 'inline-flex' }}>
                        <Box
                            component="img"
                            src={user.avatar}
                            alt={user.display_name}
                            onError={(e) => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(user.display_name || 'U')}&background=EDE8FF&color=5E2CED&size=80`; }}
                            sx={{
                                width: 76, height: 76,
                                borderRadius: '50%',
                                objectFit: 'cover',
                                border: `3px solid ${bgColor}`,
                            }}
                        />
                        {/* Rank image floated bottom-right on avatar — only when ranks addon enabled */}
                        {ranksEnabled && user.rank_image && (
                            <Box
                                component="img"
                                src={user.rank_image}
                                alt={user.rank}
                                title={user.rank}
                                sx={{
                                    position: 'absolute',
                                    bottom: '-4px', right: '-4px',
                                    width: '26px', height: '26px',
                                    borderRadius: '50%',
                                    border: '2px solid #fff',
                                    objectFit: 'cover',
                                    background: '#fff',
                                }}
                            />
                        )}
                    </Box>

                    {/* Display name */}
                    <Typography sx={{ fontSize: '17px', fontWeight: 700, color: btnColor, fontFamily: "'Instrument Sans', sans-serif", textAlign: 'center' }}>
                        {user.display_name || __('User', 'mycred')}
                    </Typography>

                    {/* Rank pill — only when ranks addon enabled */}
                    {ranksEnabled && user.rank && (
                        <Box sx={{
                            display: 'inline-flex', alignItems: 'center', gap: '6px',
                            px: '12px', py: '4px',
                            bgcolor: rankStyle.bg,
                            borderRadius: '20px',
                        }}>
                            {user.rank_image && (
                                <Box component="img" src={user.rank_image} alt="" sx={{ width: '14px', height: '14px', borderRadius: '50%', objectFit: 'cover' }} />
                            )}
                            <Typography sx={{ fontSize: '12px', fontWeight: 700, color: rankStyle.text, fontFamily: "'Instrument Sans', sans-serif" }}>
                                {user.rank}
                            </Typography>
                        </Box>
                    )}

                    {/* Rank progress bar — only when ranks addon is enabled */}
                    {ranksEnabled && showProgress && (
                        <Box sx={{ width: '100%', px: '4px' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: '4px' }}>
                                <Typography sx={{ fontSize: '11px', color: '#8670C4', fontFamily: "'Instrument Sans', sans-serif" }}>
                                    {rankMin.toLocaleString()}
                                </Typography>
                                <Typography sx={{ fontSize: '11px', color: '#8670C4', fontFamily: "'Instrument Sans', sans-serif" }}>
                                    {progressPct}%
                                </Typography>
                                <Typography sx={{ fontSize: '11px', color: '#8670C4', fontFamily: "'Instrument Sans', sans-serif" }}>
                                    {rankMax.toLocaleString()}
                                </Typography>
                            </Box>
                            <Box sx={{ width: '100%', height: '6px', bgcolor: '#F0EEFF', borderRadius: '99px', overflow: 'hidden' }}>
                                <Box sx={{
                                    width: `${progressPct}%`,
                                    height: '100%',
                                    bgcolor: bgColor,
                                    borderRadius: '99px',
                                    transition: 'width 0.6s ease',
                                }} />
                            </Box>
                            <Typography sx={{ fontSize: '11px', color: '#8670C4', mt: '4px', textAlign: 'center', fontFamily: "'Instrument Sans', sans-serif" }}>
                                {__('Progress to next rank', 'mycred')}
                            </Typography>
                        </Box>
                    )}
                </Paper>

                {/* ── Point Balances ─────────────────────────────── */}
                {allBalances.length > 0 ? (
                    <Box>
                        <Typography sx={{ fontSize: '13px', fontWeight: 600, color: '#8670C4', mb: '8px', px: '4px', fontFamily: "'Instrument Sans', sans-serif", textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                            {__('Your Balance', 'mycred')}
                        </Typography>
                        <Box sx={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                            {allBalances.map((b) => (
                                <StatCard key={b.type} label={b.label} value={b.formatted} color={btnColor} />
                            ))}
                        </Box>
                    </Box>
                ) : (
                    <Box sx={{ display: 'flex', gap: '10px' }}>
                        <StatCard label={user.point_label || __('Points', 'mycred')} value={user.formatted_balance || '0'} color={btnColor} />
                    </Box>
                )}

                {/* ── Earned Badges — only when badges addon enabled ──── */}
                {badgesEnabled && badges.length > 0 && (
                    <Box>
                        <Typography sx={{ fontSize: '13px', fontWeight: 600, color: '#8670C4', mb: '8px', px: '4px', fontFamily: "'Instrument Sans', sans-serif", textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                            {__('Earned Badges', 'mycred')}
                        </Typography>
                        <Box sx={{
                            display: 'grid',
                            gridTemplateColumns: 'repeat(3, 1fr)',
                            gap: '10px',
                        }}>
                            {badges.map((badge) => (
                                <Paper key={badge.id} elevation={0} sx={{
                                    borderRadius: '14px',
                                    border: '1.5px solid #EDE8FF',
                                    bgcolor: '#fff',
                                    p: '12px 8px',
                                    display: 'flex',
                                    flexDirection: 'column',
                                    alignItems: 'center',
                                    gap: '6px',
                                    boxShadow: '0px 2px 8px rgba(94,44,237,0.04)',
                                }}>
                                    {badge.image_url ? (
                                        <Box
                                            component="img"
                                            src={badge.image_url}
                                            alt={badge.title}
                                            sx={{ width: '46px', height: '46px', objectFit: 'contain' }}
                                        />
                                    ) : (
                                        <Box sx={{ width: '46px', height: '46px', bgcolor: `${btnColor}15`, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                            <Typography sx={{ fontSize: '22px' }}>🏅</Typography>
                                        </Box>
                                    )}
                                    <Typography sx={{
                                        fontSize: '11px',
                                        fontWeight: 600,
                                        color: btnColor,
                                        textAlign: 'center',
                                        fontFamily: "'Instrument Sans', sans-serif",
                                        lineHeight: 1.3,
                                    }}>
                                        {badge.title}
                                    </Typography>
                                    {badge.level > 1 && (
                                        <Box sx={{ px: '6px', py: '1px', bgcolor: `${btnColor}15`, borderRadius: '99px' }}>
                                            <Typography sx={{ fontSize: '10px', fontWeight: 600, color: btnColor, fontFamily: "'Instrument Sans', sans-serif" }}>
                                                Lv. {badge.level}
                                            </Typography>
                                        </Box>
                                    )}

                                    {/* WooCommerce coupon reward */}
                                    {badge.coupon && badge.coupon.code && (
                                        <Box sx={{
                                            width: '100%',
                                            mt: '2px',
                                            display: 'flex',
                                            flexDirection: 'column',
                                            alignItems: 'center',
                                            gap: '3px',
                                        }}>
                                            {/* Reward label */}
                                            <Box sx={{
                                                px: '6px', py: '2px',
                                                bgcolor: '#FFF7ED',
                                                border: '1px solid #FED7AA',
                                                borderRadius: '99px',
                                                display: 'flex', alignItems: 'center', gap: '3px',
                                            }}>
                                                <Typography sx={{ fontSize: '9px', fontWeight: 700, color: '#C2410C', fontFamily: "'Instrument Sans', sans-serif", whiteSpace: 'nowrap' }}>
                                                    🎫 {badge.coupon.discount_type === 'percent'
                                                        ? `${badge.coupon.amount}% OFF`
                                                        : `$${badge.coupon.amount} OFF`}
                                                </Typography>
                                            </Box>
                                            {/* Show coupon code if already generated */}
                                            {badge.coupon.generated_code && (
                                                <Box sx={{
                                                    px: '6px', py: '1px',
                                                    bgcolor: '#F0FDF4',
                                                    border: '1px solid #BBF7D0',
                                                    borderRadius: '99px',
                                                }}>
                                                    <Typography sx={{ fontSize: '9px', fontWeight: 700, color: '#15803D', fontFamily: "'Instrument Sans', sans-serif", letterSpacing: '0.5px' }}>
                                                        {badge.coupon.generated_code}
                                                    </Typography>
                                                </Box>
                                            )}
                                        </Box>
                                    )}
                                </Paper>
                            ))}
                        </Box>
                    </Box>
                )}

                {/* Empty badge state — only shown when badges addon is enabled */}
                {badgesEnabled && badges.length === 0 && (
                    <Paper elevation={0} sx={{
                        borderRadius: '16px',
                        border: '1.5px solid #EDE8FF',
                        bgcolor: '#fff',
                        p: '20px',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        gap: '6px',
                    }}>
                        <Typography sx={{ fontSize: '32px' }}>🏆</Typography>
                        <Typography sx={{ fontSize: '13px', fontWeight: 600, color: btnColor, fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('No badges yet', 'mycred')}
                        </Typography>
                        <Typography sx={{ fontSize: '12px', color: '#8670C4', textAlign: 'center', fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('Complete actions to earn your first badge!', 'mycred')}
                        </Typography>
                    </Paper>
                )}

            </Box>
        </Box>
    );
}
