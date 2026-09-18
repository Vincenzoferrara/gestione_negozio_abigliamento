import React from "react";
import { __ } from "@wordpress/i18n";
import { ADDON_SECTIONS } from "../sectionConfig";

const TAB_OPTIONS = [
  { tabId: "all", label: __("All", "mycred") },
  ...ADDON_SECTIONS.map((s) => ({
    tabId: s.tabId,
    label: s.tabLabel || s.title,
  })),
];

const Toolbar = ({ activeTab, onTabChange, tabCounts }) => {
  return (
    <div className="mycred-addons-toolbar">
      <div className="mycred-addons-tabs" role="tablist">
        {TAB_OPTIONS.map((tab) => (
          <button
            key={tab.tabId}
            type="button"
            role="tab"
            aria-selected={activeTab === tab.tabId}
            className={`mycred-addons-tab${activeTab === tab.tabId ? " mycred-addons-active" : ""}`}
            onClick={() => onTabChange(tab.tabId)}
          >
            {tab.label}
            <span className="mycred-addons-tab-n">{tabCounts[tab.tabId] ?? 0}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default Toolbar;
