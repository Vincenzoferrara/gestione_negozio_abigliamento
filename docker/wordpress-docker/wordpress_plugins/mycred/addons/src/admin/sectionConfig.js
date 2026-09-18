import { __ } from "@wordpress/i18n";

export const ADDON_SECTIONS = [
  {
    id: "builtin",
    tabId: "builtin",
    tabLabel: __("Built-in", "mycred"),
    title: __("Built-in Add-ons", "mycred"),
    description: __(
      "Essential features included with every installation",
      "mycred"
    ),
    match: (addon) => addon.type === "builtin",
  },
  {
    id: "Forms",
    tabId: "forms",
    tabLabel: __("Forms", "mycred"),
    title: __("Forms", "mycred"),
    description: __(
      "Award points for form submissions across popular form builders",
      "mycred"
    ),
    match: (addon) => addon.category === "Forms",
  },
  {
    id: "Booking",
    tabId: "booking",
    tabLabel: __("Booking", "mycred"),
    title: __("Booking", "mycred"),
    description: __(
      "Integrate myCred with booking and appointment plugins",
      "mycred"
    ),
    match: (addon) => addon.category === "Booking",
  },
  {
    id: "Gamifications",
    tabId: "gamification",
    tabLabel: __("Gamifications", "mycred"),
    title: __("Gamifications", "mycred"),
    description: __(
      "Engage users with games, wheels, and interactive reward experiences",
      "mycred"
    ),
    match: (addon) => addon.category === "Gamifications",
  },
  {
    id: "Enhancements",
    tabId: "enhancements",
    tabLabel: __("Enhancements", "mycred"),
    title: __("Enhancements", "mycred"),
    description: __(
      "Extend myCred with powerful features to improve your points economy",
      "mycred"
    ),
    match: (addon) => addon.category === "Enhancements",
  },
  {
    id: "Integrations",
    tabId: "integrations",
    tabLabel: __("Integrations", "mycred"),
    title: __("Integrations", "mycred"),
    description: __(
      "Connect myCred with e-commerce, membership, and third-party platforms",
      "mycred"
    ),
    match: (addon) => addon.category === "Integrations",
  },
  {
    id: "LMS",
    tabId: "lms",
    tabLabel: __("LMS", "mycred"),
    title: __("LMS", "mycred"),
    description: __(
      "Reward learners with points for course progress and achievements",
      "mycred"
    ),
    match: (addon) => addon.category === "LMS",
  },
];
