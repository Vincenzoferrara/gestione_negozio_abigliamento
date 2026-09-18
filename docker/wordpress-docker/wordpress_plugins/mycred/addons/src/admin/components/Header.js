import React from "react";
import { __ } from "@wordpress/i18n";
import HeaderLogo from "./HeaderLogo";

const PRO_URL = "https://mycred.me/pricing/";

const Header = ({ handleOpen, upgraded }) => {
  return (
    <div className="mycred-addons-head">
      <div>
        <div className="mycred-addons-head-title">
          <HeaderLogo className="mycred-addons-head-logo" />
          <h1>{__("Add-ons", "mycred")}</h1>
        </div>
        <div className="mycred-addons-head-sub">
          {__(
            "Extend myCred with forms, booking, gamification, integrations and more.",
            "mycred"
          )}
        </div>
      </div>
      <div className="mycred-addons-spacer" />
      {upgraded && (
        <button
          type="button"
          className="mycred-addons-btn-pro"
          onClick={handleOpen}
        >
          <span className="mycred-addons-btn-pro-text">
            {__("Supercharge with", "mycred")}{" "}
            <span className="mycred-addons-btn-pro-badge">PRO</span>
          </span>
        </button>
      )}
    </div>
  );
};

export { PRO_URL };
export default Header;
