/**
 * Child add-on slugs hidden from the unified Add-ons page.
 * Mirror of mycred_get_all_child_addon_slugs() in PHP.
 */
export const CHILD_ADDON_SLUGS = [
  "mycred-transfer-plus",
  "mycred-coupons-plus",
  "mycred-email-plus",
  "mycred-woocommerce-plus",
  "mycred-birthday-plus",
  "mycred-paystack",
  "mycred-robokassa",
  "mycred-coinpayment",
  "mycred-paymentwall",
  "mycred-2co",
  "mycred-coinbase",
  "mycred-wepay",
  "mycred-stripe",
  "mycred-payfast",
  "mycred-cashcred-paystack",
  "mycred-cashcred-stripe",
  "mycred-cashcred-paypal",
];

export function isChildAddon(slug) {
  return CHILD_ADDON_SLUGS.includes(slug);
}
