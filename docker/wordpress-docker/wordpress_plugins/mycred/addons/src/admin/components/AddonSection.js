import React from "react";
import AddonCard from "./AddonCard";

const AddonSection = ({
  title,
  description,
  tabId,
  addons,
  initialLoading,
  cardLoading,
  activeSlugs,
  handleToggleClick,
  installToolkit,
  activateToolkit,
  openUpgradeDialog,
}) => {
  if (!addons.length) {
    return null;
  }

  return (
    <section className="mycred-addons-section" data-cat={tabId}>
      <div className="mycred-addons-sec-head">
        <h2>{title}</h2>
        {description && (
          <span className="mycred-addons-sec-head-sub">— {description}</span>
        )}
      </div>
      <div className="mycred-addons-grid">
        {addons.map((addOn) => (
          <AddonCard
            key={addOn.slug}
            addOn={addOn}
            tabId={tabId}
            loading={initialLoading || cardLoading.has(addOn.slug)}
            activeSlugs={activeSlugs}
            handleToggleClick={handleToggleClick}
            installToolkit={installToolkit}
            activateToolkit={activateToolkit}
            openUpgradeDialog={openUpgradeDialog}
          />
        ))}
      </div>
    </section>
  );
};

export default AddonSection;
