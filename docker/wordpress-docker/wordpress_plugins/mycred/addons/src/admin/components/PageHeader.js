import React, { useEffect, useRef } from "react";
import { __ } from "@wordpress/i18n";
import { getUserPlanBadgeClass, getUserPlanLabel } from "../planConfig";

const FILTER_OPTIONS = [
  { value: "all", label: __("All", "mycred"), group: "filter" },
  { value: "builtin", label: __("Built-in Add-ons", "mycred"), group: "filter" },
  { value: "free", label: __("Free Add-ons", "mycred"), group: "filter" },
  { value: "pro", label: __("Pro Add-ons", "mycred"), group: "filter" },
  { value: "active", label: __("Active Add-ons", "mycred"), group: "filter" },
  { value: "plan:basic", label: __("Basic Plan", "mycred"), group: "plan" },
  { value: "plan:professional", label: __("Professional Plan", "mycred"), group: "plan" },
  { value: "plan:business", label: __("Business Plan", "mycred"), group: "plan" },
];

const SearchIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
    <circle cx="11" cy="11" r="7" />
    <path d="M21 21l-4.3-4.3" />
  </svg>
);

const FilterIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
    <path d="M22 3H2l8 9.5V19l4 2v-8.5L22 3z" />
  </svg>
);

const TickIcon = () => (
  <svg className="mycred-addons-tick" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
    <path d="M20 6 9 17l-5-5" />
  </svg>
);

const PageHeader = ({
  stats,
  userPlan,
  searchTerm,
  onSearchChange,
  filterType,
  onFilterChange,
}) => {
  const [filterOpen, setFilterOpen] = React.useState(false);
  const filterWrapRef = useRef(null);

  const selectedFilter = FILTER_OPTIONS.find((o) => o.value === filterType);
  const filterLabel =
    filterType === "all" ? "" : `· ${selectedFilter ? selectedFilter.label : ""}`;

  useEffect(() => {
    const handleOutside = (e) => {
      if (filterWrapRef.current && !filterWrapRef.current.contains(e.target)) {
        setFilterOpen(false);
      }
    };
    document.addEventListener("click", handleOutside);
    return () => document.removeEventListener("click", handleOutside);
  }, []);

  const handleFilterSelect = (value) => {
    onFilterChange(value);
    setFilterOpen(false);
  };

  const planLabel = userPlan ? getUserPlanLabel(userPlan) : null;

  return (
    <header className="mycred-addons-page-header">
      <div className="mycred-addons-page-header-main">
        <div className="mycred-addons-page-header-left">
          <h1 className="mycred-addons-page-title">{__("Add-ons", "mycred")}</h1>
          <div className="mycred-addons-page-meta">
            {planLabel ? (
              <span
                className={`mycred-addons-user-plan-badge ${getUserPlanBadgeClass(userPlan)}`}
              >
                {planLabel}
              </span>
            ) : (
              <span
                className="mycred-addons-user-plan-badge mycred-addons-user-plan-badge-skeleton"
                aria-hidden="true"
              />
            )}
            <div className="mycred-addons-stats">
              <span>
                <b>{stats.total}</b> {__("total", "mycred")} {__("add-ons", "mycred")}
              </span>
              <span className="mycred-addons-stats-sep" aria-hidden="true" />
              <span className="mycred-addons-stats-on">
                <b>{stats.active}</b> {__("active", "mycred")}
              </span>
              <span className="mycred-addons-stats-sep" aria-hidden="true" />
              <span>
                <b>{stats.inactive}</b> {__("inactive", "mycred")}
              </span>
            </div>
          </div>
        </div>

        <div className="mycred-addons-page-header-controls">
          <div className="mycred-addons-search mycred-addons-search-header">
            <SearchIcon />
            <input
              type="search"
              value={searchTerm}
              onChange={(e) => onSearchChange(e.target.value)}
              placeholder={__("Search add-ons…", "mycred")}
              aria-label={__("Search add-ons", "mycred")}
            />
          </div>

          <div className="mycred-addons-filter-wrap" ref={filterWrapRef}>
            <button
              type="button"
              className="mycred-addons-ctl"
              aria-haspopup="true"
              aria-expanded={filterOpen}
              onClick={(e) => {
                e.stopPropagation();
                setFilterOpen((prev) => !prev);
              }}
            >
              <FilterIcon />
              {__("Filter", "mycred")}{" "}
              <span className="mycred-addons-ctl-val">{filterLabel}</span>
            </button>
            <div
              className={`mycred-addons-menu${filterOpen ? " mycred-addons-open" : ""}`}
              role="menu"
            >
              <div className="mycred-addons-menu-label">{__("Filter", "mycred")}</div>
              {FILTER_OPTIONS.filter((o) => o.group === "filter").map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  role="menuitem"
                  className={filterType === opt.value ? "mycred-addons-sel" : ""}
                  onClick={() => handleFilterSelect(opt.value)}
                >
                  {opt.label}
                  <TickIcon />
                </button>
              ))}
              <hr />
              <div className="mycred-addons-menu-label">{__("Toolkit Pro Plans", "mycred")}</div>
              {FILTER_OPTIONS.filter((o) => o.group === "plan").map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  role="menuitem"
                  className={filterType === opt.value ? "mycred-addons-sel" : ""}
                  onClick={() => handleFilterSelect(opt.value)}
                >
                  {opt.label}
                  <TickIcon />
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default PageHeader;
