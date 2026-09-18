import React, { useMemo } from "react";

function getLogoUrl() {
  const script = document.querySelector('script[src*="admin.bundle.js"]');
  if (!script) {
    return "";
  }

  return script.src.replace(
    /addons\/build\/admin\.bundle\.js(\?.*)?$/,
    "addons/src/admin/icons/mycred-logo.svg$1"
  );
}

const HeaderLogo = ({ className }) => {
  const logoUrl = useMemo(getLogoUrl, []);

  if (!logoUrl) {
    return null;
  }

  return (
    <img
      src={logoUrl}
      alt="myCred"
      className={className}
      height={30}
      width={102}
      decoding="async"
    />
  );
};

export default HeaderLogo;
