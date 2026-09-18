import React from "react";
import { getCategoryIcon } from "./categoryIcons";

export function renderAddonIcon(slug, tabId) {
  try {
    const IconModule = require(`./icons/${slug}.svg`).default;

    if (typeof IconModule === "string" && IconModule.startsWith("data:image/svg+xml")) {
      return (
        <span
          className="mycred-addons-icon-svg"
          dangerouslySetInnerHTML={{
            __html: atob(IconModule.split(",")[1]),
          }}
        />
      );
    }

    const IconComponent = IconModule;
    return (
      <span className="mycred-addons-icon-svg">
        <IconComponent width={40} height={40} aria-hidden="true" />
      </span>
    );
  } catch (error) {
    return (
      <span className="mycred-addons-icon-svg mycred-addons-icon-fallback">
        {getCategoryIcon(tabId)}
      </span>
    );
  }
}
