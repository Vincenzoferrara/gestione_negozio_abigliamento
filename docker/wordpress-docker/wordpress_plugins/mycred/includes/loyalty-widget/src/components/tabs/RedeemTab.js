import { Box, Typography, Paper, IconButton, CircularProgress, Divider } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CloseIcon from '@mui/icons-material/Close';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import PaymentsIcon from '@mui/icons-material/Payments';
import { __ } from '@wordpress/i18n';
import { useState, useEffect } from '@wordpress/element';

export default function RedeemTab({ settings, currentContent, onBack, onClose, previewMode = false, previewData }) {
    const [coupons, setCoupons]   = useState([]);
    const [loading, setLoading]   = useState(true);
    const isRtl = document?.documentElement?.dir === 'rtl';

    currentContent = currentContent || {};
    const design    = settings.design || {};
    const btnColor  = design.buttonColor  || '#5E2CED';
    const bgColor   = design.backgroundColor || '#2D1572';

    // Data from PHP
    const gateway      = (typeof mycredLoyaltyWidget !== 'undefined' && mycredLoyaltyWidget.woo_gateway)      || { enabled: false };
    const partialPay   = (typeof mycredLoyaltyWidget !== 'undefined' && mycredLoyaltyWidget.woo_partial_payment) || { enabled: false };

    useEffect(() => {
        if (previewMode) {
            setCoupons(previewData || []);
            setLoading(false);
            return;
        }

        fetch(`${mycredLoyaltyWidget.rest_url}/coupons`, {
            headers: { 'X-WP-Nonce': mycredLoyaltyWidget.nonce }
        })
        .then(r => r.ok ? r.json() : [])
        .then(data => setCoupons(Array.isArray(data) ? data : []))
        .catch(console.error)
        .finally(() => setLoading(false));
    }, [previewMode, previewData]);

    /* ─── shared styles ─────────────────────────────────────────── */
    const infoCard = (icon, accentColor, title, rows, footer) => (
        <Paper elevation={0} sx={{
            borderRadius: '18px',
            border: `1.5px solid ${accentColor}25`,
            bgcolor: '#fff',
            mb: '14px',
            overflow: 'hidden',
            boxShadow: '0 2px 12px rgba(0,0,0,0.05)',
        }}>
            {/* Card header */}
            <Box sx={{
                px: '16px', py: '12px',
                display: 'flex', alignItems: 'center', gap: '10px',
                bgcolor: `${accentColor}08`,
                borderBottom: `1px solid ${accentColor}15`,
            }}>
                <Box sx={{
                    width: 36, height: 36, borderRadius: '10px',
                    bgcolor: `${accentColor}15`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                    {icon}
                </Box>
                <Typography sx={{
                    fontSize: '14px', fontWeight: 700, color: accentColor,
                    fontFamily: "'Instrument Sans', sans-serif",
                }}>
                    {title}
                </Typography>
            </Box>

            {/* Rows */}
            <Box sx={{ px: '16px', py: '10px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {rows.map((row, i) => (
                    <Box key={i} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Typography sx={{ fontSize: '12px', color: '#7A7A9A', fontFamily: "'Instrument Sans', sans-serif" }}>
                            {row.label}
                        </Typography>
                        <Typography sx={{ fontSize: '13px', fontWeight: 700, color: accentColor, fontFamily: "'Instrument Sans', sans-serif" }}>
                            {row.value}
                        </Typography>
                    </Box>
                ))}
            </Box>

            {/* Footer hint */}
            {footer && (
                <Box sx={{ px: '16px', py: '10px', bgcolor: `${accentColor}06`, borderTop: `1px solid ${accentColor}10` }}>
                    <Typography sx={{ fontSize: '11px', color: '#9A9ABB', fontFamily: "'Instrument Sans', sans-serif", lineHeight: 1.5 }}>
                        💡 {footer}
                    </Typography>
                </Box>
            )}
        </Paper>
    );

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: bgColor }}>

            {/* ── Header ─────────────────────────────────────────── */}
            <Box sx={{ p: '20px 24px', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <IconButton size="small" onClick={onBack} sx={{ color: '#fff', p: 0.5 }}>
                        <ArrowBackIcon sx={{ transform: isRtl ? 'scaleX(-1)' : 'none' }} />
                    </IconButton>
                    <Box>
                        <Typography sx={{ fontSize: '18px', fontWeight: 700, fontFamily: "'Instrument Sans', sans-serif" }}>
                            {currentContent.redeemMessage || __('Redeem', 'mycred')}
                        </Typography>
                    </Box>
                </Box>
                <IconButton size="small" onClick={onClose} sx={{ color: '#fff' }}>
                    <CloseIcon />
                </IconButton>
            </Box>

            {/* ── Body ───────────────────────────────────────────── */}
            <Box sx={{
                flex: 1, bgcolor: '#F4F5F8', borderRadius: '24px 24px 0 0',
                overflowY: 'auto', p: '20px 16px',
                scrollbarWidth: 'none', '&::-webkit-scrollbar': { display: 'none' },
                display: 'flex', flexDirection: 'column', gap: '12px',
                '& > *': {
                    animation: 'slideKeyframe 0.5s cubic-bezier(0.16, 1, 0.3, 1) both',
                },
                ...Array.from({ length: 15 }).reduce((acc, _, i) => ({
                    ...acc,
                    [`& > *:nth-of-type(${i + 1})`]: { animationDelay: `${i * 0.05}s` }
                }), {})
            }}>

                {/* ── Gateway card ───────────────────────────────── */}
                {gateway.enabled && infoCard(
                    <ShoppingCartIcon sx={{ fontSize: 20, color: btnColor }} />,
                    btnColor,
                    __('Pay with Points', 'mycred'),
                    [
                        {
                            label: __('Your Balance', 'mycred'),
                            value: gateway.formatted_balance,
                        }
                    ],
                    __('Select "Pay with Points" at checkout to use your balance.', 'mycred')
                )}

                {/* ── Partial Payment card ────────────────────────── */}
                {partialPay.enabled && (() => {
                    const types = partialPay.point_types || [];
                    return infoCard(
                        <PaymentsIcon sx={{ fontSize: 20, color: '#16A34A' }} />,
                        '#16A34A',
                        __('Partial Payment', 'mycred'),
                        types.flatMap(pt => [
                            {
                                label: `${pt.label} — ${__('Balance', 'mycred')}`,
                                value: pt.formatted_balance,
                            }
                        ]),
                        __('Use your points to partially pay for any order at checkout.', 'mycred')
                    );
                })()}

                {/* ── Divider if both sections are shown with coupons ── */}
                {(gateway.enabled || partialPay.enabled) && (
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: '10px', mb: '16px' }}>
                        <Divider sx={{ flex: 1, borderColor: '#E0E0EE' }} />
                        <Typography sx={{ fontSize: '11px', fontWeight: 600, color: '#AAAAC8', fontFamily: "'Instrument Sans', sans-serif", whiteSpace: 'nowrap' }}>
                            {__('AWARDED COUPONS', 'mycred')}
                        </Typography>
                        <Divider sx={{ flex: 1, borderColor: '#E0E0EE' }} />
                    </Box>
                )}

                {/* ── Coupons list ─────────────────────────────────── */}
                {loading ? (
                    <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
                        <CircularProgress sx={{ color: btnColor }} />
                    </Box>
                ) : coupons.length > 0 ? (
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                        {coupons.map((coupon) => (
                            <Paper
                                key={coupon.id}
                                elevation={0}
                                sx={{
                                    p: '14px 16px',
                                    borderRadius: '16px',
                                    border: '1.5px solid #EEEEF8',
                                    bgcolor: '#fff',
                                    boxShadow: '0 2px 8px rgba(0,0,0,0.04)',
                                }}
                            >
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                                    {/* Icon badge */}
                                    <Box sx={{
                                        width: 46, height: 46, borderRadius: '12px',
                                        bgcolor: `${btnColor}12`,
                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                        flexShrink: 0,
                                    }}>
                                        <Typography sx={{ fontSize: '22px' }}>🎫</Typography>
                                    </Box>

                                    {/* Text */}
                                    <Box sx={{ flex: 1, minWidth: 0 }}>
                                        <Typography sx={{
                                            fontSize: '13px', fontWeight: 700, color: btnColor,
                                            fontFamily: "'Instrument Sans', sans-serif",
                                            mb: '2px',
                                            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                                        }}>
                                            {coupon.code}
                                        </Typography>
                                        <Typography sx={{
                                            fontSize: '11px', color: '#7A7A9A',
                                            fontFamily: "'Instrument Sans', sans-serif",
                                            lineHeight: 1.4,
                                            display: '-webkit-box',
                                            WebkitLineClamp: 2,
                                            WebkitBoxOrient: 'vertical',
                                            overflow: 'hidden',
                                        }}>
                                            {coupon.description || __('Awarded Coupon', 'mycred')}
                                        </Typography>
                                        <Typography sx={{ fontSize: '10px', color: '#AAAAC8', mt: '4px', fontFamily: "'Instrument Sans', sans-serif" }}>
                                            {__('Expires:', 'mycred')} {coupon.date_expires}
                                        </Typography>
                                    </Box>

                                    {/* Amount + status */}
                                    <Box sx={{ textAlign: 'right', flexShrink: 0 }}>
                                        <Typography sx={{
                                            fontSize: '15px', fontWeight: 800, color: btnColor,
                                            fontFamily: "'Instrument Sans', sans-serif",
                                        }}>
                                            {coupon.formatted_amount}
                                        </Typography>
                                        <Box sx={{
                                            display: 'inline-block', mt: '4px',
                                            px: '8px', py: '2px',
                                            bgcolor: '#F0FDF4', border: '1px solid #BBF7D0',
                                            borderRadius: '99px',
                                        }}>
                                            <Typography sx={{ fontSize: '10px', fontWeight: 700, color: '#15803D', fontFamily: "'Instrument Sans', sans-serif" }}>
                                                {coupon.status}
                                            </Typography>
                                        </Box>
                                    </Box>
                                </Box>
                            </Paper>
                        ))}
                    </Box>
                ) : (
                    <Box sx={{ textAlign: 'center', py: 6 }}>
                        <Typography sx={{ fontSize: '30px', mb: 1 }}>🎟️</Typography>
                        <Typography sx={{ fontSize: '13px', color: '#AAAAC8', fontFamily: "'Instrument Sans', sans-serif" }}>
                            {__('No coupons awarded yet.', 'mycred')}
                        </Typography>
                    </Box>
                )}
            </Box>
        </Box>
    );
}
