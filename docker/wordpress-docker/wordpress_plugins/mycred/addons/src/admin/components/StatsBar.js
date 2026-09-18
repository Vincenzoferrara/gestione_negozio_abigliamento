import React from "react";
import { __ } from "@wordpress/i18n";

const StatsBar = ({ stats }) => {
  return (
    <div className="mycred-addons-stats">
      <span>
        <b>{stats.total}</b> {__("add-ons", "mycred")}
      </span>
      <span className="mycred-addons-stats-sep" aria-hidden="true" />
      <span className="mycred-addons-stats-on">
        <b>{stats.active}</b> {__("active", "mycred")}
      </span>
      <span className="mycred-addons-stats-sep" aria-hidden="true" />
      <span>
        <b>{stats.inactive}</b> {__("inactive", "mycred")}
      </span>
      <span className="mycred-addons-stats-sep" aria-hidden="true" />
      <span>
        <b>{stats.proCount}</b> {__("available with PRO", "mycred")}
      </span>
    </div>
  );
};

export default StatsBar;
