import { __ } from "@wordpress/i18n";

export const ADDON_PLANS = {
  // Basic plan
  "mycred-todo-list": "basic",
  "mycred-email-plus": "basic",
  "mycred-time-based-reward": "basic",
  "mycred-nominations": "basic",
  "mycred-submission": "basic",
  "mycred-anniversary-pro": "basic",
  "mycred-coupons-plus": "basic",
  "mycred-birthday-plus": "basic",
  "mycred-daily-login-rewards": "basic",
  "mycred-email-digest": "basic",
  "mycred-progress-map": "basic",
  "mycred-points-cap": "basic",
  "mycred-social-proof": "basic",
  "mycred-reset-points": "basic",
  "mycred-pending-points": "basic",
  "mycred-progress-bar": "basic",
  "mycred-jwplayer": "basic",
  "mycred-transfer-plus": "basic",
  "mycred-notice-plus": "basic",
  "mycred-beaver-builder": "basic",
  "mycred-userpro": "basic",
  "mycred-usersultra": "basic",
  "mycred-vc": "basic",

  // Professional plan
  "mycred-expiration-addon": "professional",
  "mycred-rest": "professional",
  "mycred-woocommerce-plus": "professional",
  "mycred-bp-charges": "professional",
  "mycred-gateway-edd": "professional",
  "mycred-paystack": "professional",
  "mycred-robokassa": "professional",
  "mycred-coinpayment": "professional",
  "mycred-paymentwall": "professional",
  "mycred-2co": "professional",
  "mycred-coinbase": "professional",
  "mycred-wepay": "professional",
  "mycred-cashcred-paystack": "professional",
  "mycred-pacman": "professional",

  // Business plan
  "mycred-level-cred": "business",
  "mycred-sms-payments": "business",
  "mycred-social-shares": "business",
  "mycred-videos": "business",
  "mycred-dokan": "business",
  "mycred-wc-vendors-addon": "business",
  "mycred-stripe": "business",
  "mycred-payfast": "business",
  "mycred-cashcred-stripe": "business",
  "mycred-cashcred-paypal": "business",
  "mycred-wheel-of-fortune": "business",
};

export const PLAN_LABELS = {
  basic: __("Basic", "mycred"),
  professional: __("Professional", "mycred"),
  business: __("Business", "mycred"),
};

export const USER_PLAN_LABELS = {
  free: __("Free Plan", "mycred"),
  basic: __("Basic Plan", "mycred"),
  professional: __("Professional Plan", "mycred"),
  business: __("Business Plan", "mycred"),
};

export function getUserPlanLabel(plan) {
  return USER_PLAN_LABELS[plan] || USER_PLAN_LABELS.free;
}

export function getUserPlanBadgeClass(plan) {
  const classes = {
    free: "mycred-addons-user-plan-badge--free",
    basic: "mycred-addons-user-plan-badge--basic",
    professional: "mycred-addons-user-plan-badge--professional",
    business: "mycred-addons-user-plan-badge--business",
  };

  return classes[plan] || classes.free;
}

const PLAN_RANK = { free: 0, basic: 1, professional: 2, business: 3 };

export function isAddonIncludedInPlanTier(addonPlan, tier) {
  if (!addonPlan || !tier) {
    return false;
  }

  const addonRank = PLAN_RANK[addonPlan];
  const tierRank = PLAN_RANK[tier];

  if (addonRank === undefined || tierRank === undefined) {
    return false;
  }

  return addonRank > 0 && addonRank <= tierRank;
}

export function resolveUserPlanFromStatuses(fileStatuses) {
  if (!Array.isArray(fileStatuses) || fileStatuses.length === 0) {
    return "free";
  }

  let highest = "free";

  for (const item of fileStatuses) {
    if (item.status !== "unlocked") {
      continue;
    }
    const tier = ADDON_PLANS[item.slug];
    if (tier && PLAN_RANK[tier] > PLAN_RANK[highest]) {
      highest = tier;
    }
  }

  return highest;
}

export const PLAN_SECTIONS = [
  {
    id: "basic",
    title: __("Basic Plan Add-ons", "mycred"),
    description: __(
      "Included with the myCred Toolkit Pro Basic plan ($99/year).",
      "mycred"
    ),
    match: (addon) => addon.plan === "basic",
    viewAll: { type: "filter", value: "basic" },
    limit: 4,
  },
  {
    id: "professional",
    title: __("Professional Plan Add-ons", "mycred"),
    description: __(
      "Included with the myCred Toolkit Pro Professional plan ($149/year).",
      "mycred"
    ),
    match: (addon) => addon.plan === "professional",
    viewAll: { type: "filter", value: "professional" },
    limit: 4,
  },
  {
    id: "business",
    title: __("Business Plan Add-ons", "mycred"),
    description: __(
      "Included with the myCred Toolkit Pro Business plan ($299/year).",
      "mycred"
    ),
    match: (addon) => addon.plan === "business",
    viewAll: { type: "filter", value: "business" },
    limit: 4,
  },
];

export function getAddonPlan(addon) {
  if (!addon || addon.type !== "pro") {
    return null;
  }

  return ADDON_PLANS[addon.slug] || null;
}
