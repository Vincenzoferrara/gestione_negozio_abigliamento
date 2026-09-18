import React, { useState } from "react";
import { __ } from "@wordpress/i18n";
import { getUserPlanLabel } from "../planConfig";

const DISMISS_STORAGE_KEY = "mycred_addons_plan_banner_dismissed";

const InfoIcon = () => (
  <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z" />
  </svg>
);

const CloseIcon = () => (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
    <path d="M18.3 5.71a1 1 0 0 0-1.41 0L12 10.59 7.11 5.7A1 1 0 0 0 5.7 7.11L10.59 12l-4.89 4.89a1 1 0 1 0 1.41 1.41L12 13.41l4.89 4.89a1 1 0 0 0 1.41-1.41L13.41 12l4.89-4.89a1 1 0 0 0 0-1.4z" />
  </svg>
);

function isBannerDismissed(userPlan) {
  try {
    return window.localStorage.getItem(`${DISMISS_STORAGE_KEY}_${userPlan}`) === "1";
  } catch (error) {
    return false;
  }
}

function getPlanBannerContent(userPlan, planLabel) {
  switch (userPlan) {
    case "basic":
      return (
        <>
          {__("With your", "mycred")}{" "}
          <strong>{planLabel}</strong>
          {__(", only Basic plan add-ons are available to you.", "mycred")}
        </>
      );
    case "professional":
      return (
        <>
          {__("With your", "mycred")}{" "}
          <strong>{planLabel}</strong>
          {__(", Basic and Professional plan add-ons are available to you.", "mycred")}
        </>
      );
    case "business":
      return (
        <>
          {__("With your", "mycred")}{" "}
          <strong>{planLabel}</strong>
          {__(
            ", Basic, Professional, and Business plan add-ons are all available to you.",
            "mycred"
          )}
        </>
      );
    default:
      return null;
  }
}

const PlanBanner = ({ userPlan }) => {
  const [dismissed, setDismissed] = useState(() =>
    userPlan ? isBannerDismissed(userPlan) : false
  );

  if (!userPlan || userPlan === "free" || dismissed) {
    return null;
  }

  const planLabel = getUserPlanLabel(userPlan);
  const content = getPlanBannerContent(userPlan, planLabel);

  if (!content) {
    return null;
  }

  const handleDismiss = () => {
    setDismissed(true);
    try {
      window.localStorage.setItem(`${DISMISS_STORAGE_KEY}_${userPlan}`, "1");
    } catch (error) {
      // Ignore storage errors; banner still hides for this session.
    }
  };

  return (
    <div className="mycred-addons-plan-banner" role="status">
      <div className="mycred-addons-plan-banner-content">
        <span className="mycred-addons-plan-banner-icon" aria-hidden="true">
          <InfoIcon />
        </span>
        <p>{content}</p>
      </div>
      <button
        type="button"
        className="mycred-addons-plan-banner-close"
        aria-label={__("Dismiss", "mycred")}
        onClick={handleDismiss}
      >
        <CloseIcon />
      </button>
    </div>
  );
};

export default PlanBanner;
