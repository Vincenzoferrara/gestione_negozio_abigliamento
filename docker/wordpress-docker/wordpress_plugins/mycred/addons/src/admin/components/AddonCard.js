import React from "react";
import { __, sprintf } from "@wordpress/i18n";
import { PLAN_LABELS } from "../planConfig";
import { renderAddonIcon } from "../addonIcons";
import { isAddonActive, isAddonLocked, shouldShowProUpgrade } from "../utils/filterAddons";

const FlashIcon = () => (
  <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
    <path d="M13 2 3 14h8l-1 8 10-12h-8l1-8z" />
  </svg>
);

const AddonCard = ({
  addOn,
  loading,
  tabId,
  activeSlugs,
  handleToggleClick,
  installToolkit,
  activateToolkit,
  openUpgradeDialog,
}) => {
  const isEnabled = isAddonActive(activeSlugs, addOn.slug);
  const locked = isAddonLocked(addOn, activeSlugs);
  const toolkitActive = window.mycredAddonsData?.toolkitActive;
  const toolkitInstalled = window.mycredAddonsData?.toolkitInstalled;

  const docsUrl = addOn.addonUrl || addOn.link || "";
  const settingsEnabled = isEnabled && addOn.status !== "locked" && addOn.settingUrl;

  const handleSettings = () => {
    if (!settingsEnabled) return;
    const url = addOn.settingUrl.startsWith("http")
      ? addOn.settingUrl
      : `${window.location.origin}/${addOn.settingUrl}`;
    window.location.href = url;
  };

  const handleDocs = () => {
    if (docsUrl) {
      window.open(docsUrl, "_blank", "noopener,noreferrer");
    }
  };

  const showToolkitInstall =
    addOn.source === "toolkit" &&
    addOn.type === "free" &&
    !toolkitActive;

  if (loading) {
    return (
      <article className="mycred-addons-card">
        <div className="mycred-addons-card-top">
          <div className="mycred-addons-icon mycred-addons-skeleton" style={{ width: 48, height: 48, borderRadius: "50%" }} />
        </div>
        <div className="mycred-addons-skeleton" style={{ height: 16, marginTop: 12, width: "70%" }} />
        <div className="mycred-addons-skeleton" style={{ height: 36, marginTop: 8 }} />
        <div className="mycred-addons-card-foot">
          <div className="mycred-addons-skeleton" style={{ height: 14, width: 60 }} />
        </div>
      </article>
    );
  }

  return (
    <article
      className={`mycred-addons-card${isEnabled ? " mycred-addons-on" : ""}${locked ? " mycred-addons-locked" : ""}`}
    >
      <div className="mycred-addons-card-top">
        <div className="mycred-addons-icon">{renderAddonIcon(addOn.slug, tabId)}</div>
        {addOn.type === "pro" && addOn.plan && (
          <span className={`mycred-addons-tier mycred-addons-${addOn.plan}`}>
            {PLAN_LABELS[addOn.plan]}
          </span>
        )}
      </div>

      <h3>{addOn.title}</h3>

      <p className="mycred-addons-card-desc">{addOn.description}</p>

      <div className="mycred-addons-card-foot">
        {locked ? (
          <>
            <button type="button" className="mycred-addons-link" onClick={handleDocs}>
              {__("Learn more", "mycred")}
            </button>
            <button
              type="button"
              className="mycred-addons-upgrade-btn"
              onClick={openUpgradeDialog}
            >
              {__("Upgrade", "mycred")}
              <FlashIcon />
            </button>
          </>
        ) : showToolkitInstall ? (
          <>
            <button type="button" className="mycred-addons-link" onClick={handleDocs}>
              {__("Docs", "mycred")}
            </button>
            <button
              type="button"
              className="mycred-addons-install-btn"
              disabled={loading}
              onClick={() => {
                if (!toolkitInstalled) {
                  installToolkit(addOn.slug);
                } else {
                  activateToolkit(addOn.slug);
                }
              }}
            >
              {!toolkitInstalled
                ? __("Install Addons Package", "mycred")
                : __("Activate Addons Package", "mycred")}
            </button>
          </>
        ) : (
          <>
            <span className="mycred-addons-foot-links">
              <button type="button" className="mycred-addons-link" onClick={handleDocs}>
                {__("Docs", "mycred")}
              </button>
              <span className="mycred-addons-foot-sep" aria-hidden="true">
                ·
              </span>
              <button
                type="button"
                className={`mycred-addons-link${!settingsEnabled ? " mycred-addons-disabled" : ""}`}
                onClick={handleSettings}
                disabled={!settingsEnabled}
              >
                {__("Settings", "mycred")}
              </button>
            </span>
            <span className="mycred-addons-state">
              <span className="mycred-addons-state-txt">
                {isEnabled ? __("Active", "mycred") : __("Inactive", "mycred")}
              </span>
              <label className="mycred-addons-switch">
                <input
                  type="checkbox"
                  checked={isEnabled}
                  disabled={loading}
                  aria-label={sprintf(
                    /* translators: %s: add-on title */
                    __("Toggle %s", "mycred"),
                    addOn.title
                  )}
                  onChange={() => {
                    if (shouldShowProUpgrade(addOn, isEnabled)) {
                      openUpgradeDialog();
                      return;
                    }
                    handleToggleClick(addOn);
                  }}
                />
                <span className="mycred-addons-track">
                  <span className="mycred-addons-knob" />
                </span>
              </label>
            </span>
          </>
        )}
      </div>
    </article>
  );
};

export default AddonCard;
