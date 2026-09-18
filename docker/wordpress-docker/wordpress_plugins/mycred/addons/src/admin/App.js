import React, { useState, useEffect, useMemo } from "react";
import { __ } from "@wordpress/i18n";
import "./styles/addons-page.css";
import Notification, { showToast } from "./components/Notification";

import UpgradeDialog from "./components/UpgradeDialog";
import AddonSection from "./components/AddonSection";
import PageHeader from "./components/PageHeader";
import PlanBanner from "./components/PlanBanner";
import Toolbar from "./components/Toolbar";
import { ADDON_SECTIONS } from "./sectionConfig";
import { getAddonPlan, resolveUserPlanFromStatuses } from "./planConfig";
import addOnsData from "./addons.json";
import {
  computeStats,
  filterAddon,
  sortAddons,
  matchesSearch,
  matchesFilterType,
  isChildAddon,
} from "./utils/filterAddons";

const enrichAddonsWithPlan = (addons) =>
  addons.map((addon) => ({
    ...addon,
    plan: getAddonPlan(addon),
  }));

function contains(data, value) {
  if (Array.isArray(data)) {
    return data.includes(value);
  }
  if (data && typeof data === "object") {
    return Object.values(data).includes(value);
  }
  return false;
}

function parseJsonArrayResponse(text) {
  if (!text || typeof text !== "string") {
    return [];
  }

  const trimmed = text.trim();
  if (trimmed.startsWith("[")) {
    return JSON.parse(trimmed);
  }

  const jsonStart = trimmed.indexOf("[");
  if (jsonStart === -1) {
    throw new Error("No JSON array found in response");
  }

  return JSON.parse(trimmed.slice(jsonStart));
}

const getInitialActiveSlugs = () => {
  const slugs = window.mycredAddonsData?.activeSlugs;
  return Array.isArray(slugs) ? slugs : [];
};

const getInitialUserPlan = () => {
  const data = window.mycredAddonsData;
  if (!data?.toolkitActive && !data?.toolkitProActive) {
    return "free";
  }
  return null;
};

const App = () => {
  const [initialLoading, setInitialLoading] = useState(false);
  const [cardLoading, setCardLoading] = useState(new Set());
  const [Addons, setAddons] = useState(getInitialActiveSlugs);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterType, setFilterType] = useState("all");
  const [activeTab, setActiveTab] = useState("all");
  const [open, setOpen] = useState(false);
  const [addonsData, setAddonsData] = useState(() => enrichAddonsWithPlan(addOnsData));
  const [userPlan, setUserPlan] = useState(getInitialUserPlan);
  const [toolkitInstalled, setToolkitInstalled] = useState(() =>
    Boolean(window.mycredAddonsData?.toolkitInstalled)
  );

  const handleOpen = () => setOpen(true);
  const handleClose = () => setOpen(false);

  const fetchAddOns = async (affectGlobalLoading = false) => {
    try {
      if (affectGlobalLoading) setInitialLoading(true);
      const siteUrl = `${window.mycredAddonsData.root}mycred/v1/get-core-addons`;

      const response = await fetch(siteUrl, {
        method: "GET",
        headers: {
          "X-WP-Nonce": window.mycredAddonsData.nonce,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error("Network response was not ok");
      }

      const activeSlugs = parseJsonArrayResponse(await response.text());
      setAddons(activeSlugs || []);
    } catch (error) {
      showToast("Error fetching add-ons: " + error.message, "error");
    } finally {
      if (affectGlobalLoading) setInitialLoading(false);
    }
  };

  const checkProaddonsfile = async () => {
    if (!window.mycredAddonsData.toolkitActive && !window.mycredAddonsData.toolkitProActive) {
      setUserPlan("free");
      return;
    }
    try {
      const siteUrl = `${window.mycredAddonsData.root}mycred-toolkit/v1/check-addons-files`;

      const proAddOns = addonsData.filter((addon) => addon.type === "pro");

      const response = await fetch(siteUrl, {
        method: "POST",
        headers: {
          "X-WP-Nonce": window.mycredAddonsData.nonce,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          proAddOns: proAddOns,
        }),
      });

      if (!response.ok) {
        throw new Error("Network response was not ok");
      }

      const fileStatuses = parseJsonArrayResponse(await response.text());

      setUserPlan(resolveUserPlanFromStatuses(fileStatuses));

      setAddonsData((prev) =>
        prev.map((addon) => {
          const matchingAddon = fileStatuses.find((item) => item.slug === addon.slug);
          return matchingAddon
            ? { ...addon, status: matchingAddon.status }
            : addon;
        })
      );
    } catch (error) {
      setUserPlan("free");
      // Silent fail — file check is optional.
    }
  };

  useEffect(() => {
    fetchAddOns(false);

    if (window.mycredAddonsData && Array.isArray(window.mycredAddonsData.addons)) {
      setAddonsData(enrichAddonsWithPlan(window.mycredAddonsData.addons));
    }

    checkProaddonsfile();
  }, []);

  const withCardLoading = async (slug, fn) => {
    setCardLoading((prev) => {
      const next = new Set(prev);
      next.add(slug);
      return next;
    });
    try {
      await fn();
    } finally {
      setCardLoading((prev) => {
        const next = new Set(prev);
        next.delete(slug);
        return next;
      });
    }
  };

  const installToolkit = async (slug) => {
    return withCardLoading(slug, async () => {
      const url = `${window.mycredAddonsData.root}mycred/v1/install-toolkit`;
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-WP-Nonce": window.mycredAddonsData.nonce,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ addon_slug: slug }),
      });
      const result = await response.json();
      if (response.ok && result.status === "success") {
        const hasAddonDependencyError =
          Boolean(slug) &&
          !result.addon_activated &&
          (result.addon_error_code === "dependency_missing" ||
            !!result.addon_error_message);

        if (hasAddonDependencyError) {
          showToast(
            result.addon_error_message ||
              result.message ||
              "Addons package installed but add-on dependency is missing",
            "error"
          );
        } else {
          showToast(result.message || "Addons package installed", "success");
        }
        window.mycredAddonsData.toolkitInstalled = true;
        setToolkitInstalled(true);
        if (result.activated) {
          window.mycredAddonsData.toolkitActive = true;
        }
        if (result.addon_activated) {
          fetchAddOns(false);
        }
      } else {
        showToast(result.message || "Addons package install failed", "error");
      }
    }).catch(() => showToast("Addons package install failed", "error"));
  };

  const activateToolkit = async (slug) => {
    return withCardLoading(slug, async () => {
      const url = `${window.mycredAddonsData.root}mycred/v1/install-toolkit`;
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-WP-Nonce": window.mycredAddonsData.nonce,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ addon_slug: slug }),
      });
      const result = await response.json();
      if (response.ok && result.status === "success") {
        const hasAddonDependencyError =
          Boolean(slug) &&
          !result.addon_activated &&
          (result.addon_error_code === "dependency_missing" ||
            !!result.addon_error_message);

        if (hasAddonDependencyError) {
          showToast(
            result.addon_error_message ||
              result.message ||
              "Addons package activated but add-on dependency is missing",
            "error"
          );
        } else {
          showToast(result.message || "Addons package activated", "success");
        }
        window.mycredAddonsData.toolkitActive = true;
        if (result.addon_activated) {
          fetchAddOns(false);
        }
      } else {
        showToast(result.message || "Addons package activation failed", "error");
      }
    }).catch(() => showToast("Addons package activation failed", "error"));
  };

  const handleToggleClick = async (addOn) => {
    const toolkitActive = window.mycredAddonsData.toolkitActive;
    const toolkitProActive = window.mycredAddonsData.toolkitProActive;
    const isEnabled = contains(Addons, addOn.slug);

    if (addOn.source === "toolkit") {
      if (addOn.type === "pro") {
        if (addOn.status === "locked" && !isEnabled) {
          handleOpen();
          return;
        }
        if (!toolkitProActive) {
          if (!toolkitActive) {
            await installToolkit(addOn.slug);
          }
          handleOpen();
          return;
        }
      }
      if (!toolkitActive) {
        await installToolkit(addOn.slug);
        return;
      }
    }

    if (cardLoading.has(addOn.slug)) return;

    try {
      await withCardLoading(addOn.slug, async () => {
        const siteUrl = `${window.mycredAddonsData.root}mycred/v1/enable-core-addon`;
        const response = await fetch(siteUrl, {
          method: "POST",
          headers: {
            "X-WP-Nonce": window.mycredAddonsData.nonce,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            addOnSlug: addOn.slug,
            addOnTitle: addOn.title,
            source: addOn.source || "core",
            dependency: addOn.dependency || "",
            dependencyName: addOn.dependencyName || "",
          }),
        });
        const result = await response.json();
        if (result.status === "error") {
          const isLockedError =
            result.code === "addon_locked" ||
            (typeof result.message === "string" &&
              result.message.toLowerCase().includes("does not exist"));

          if (isLockedError && addOn.type === "pro") {
            handleOpen();
          } else {
            showToast(result.message || "Toggle failed", "error");
          }
        } else {
          showToast(result.message || "Toggled successfully", "success");
          fetchAddOns(false);
        }
      });
    } catch (error) {
      showToast("An error occurred while toggling the addon", "error");
    }
  };

  const stats = useMemo(
    () => computeStats(addonsData, Addons),
    [addonsData, Addons]
  );

  const tabCounts = useMemo(() => {
    const counts = { all: 0 };

    counts.all = addonsData.filter(
      (addon) =>
        !isChildAddon(addon.slug) &&
        matchesSearch(addon, searchTerm) &&
        matchesFilterType(addon, filterType, Addons)
    ).length;

    ADDON_SECTIONS.forEach((section) => {
      counts[section.tabId] = addonsData
        .filter(section.match)
        .filter(
          (addon) =>
            !isChildAddon(addon.slug) &&
            matchesSearch(addon, searchTerm) &&
            matchesFilterType(addon, filterType, Addons)
        ).length;
    });

    return counts;
  }, [addonsData, searchTerm, filterType, Addons]);

  const sectionsToRender = useMemo(() => {
    const sections =
      activeTab === "all"
        ? ADDON_SECTIONS
        : ADDON_SECTIONS.filter((s) => s.tabId === activeTab);

    return sections
      .map((section) => {
        const visible = sortAddons(
          addonsData
            .filter(section.match)
            .filter((addon) =>
              filterAddon(addon, {
                searchTerm,
                filterType,
                activeTab,
                sectionTabId: section.tabId,
                activeSlugs: Addons,
              })
            ),
          "default",
          Addons
        );

        return { section, visible };
      })
      .filter(({ visible }) => visible.length > 0);
  }, [addonsData, searchTerm, filterType, activeTab, Addons]);

  const totalVisible = sectionsToRender.reduce(
    (sum, { visible }) => sum + visible.length,
    0
  );

  const sharedCardProps = {
    activeSlugs: Addons,
    handleToggleClick,
    installToolkit,
    activateToolkit,
    openUpgradeDialog: handleOpen,
    initialLoading,
    cardLoading,
  };

  return (
    <>
      <div className="mycred-addons-wrap">
        <div className="mycred-addons-shell">
          <PageHeader
            stats={stats}
            userPlan={userPlan}
            searchTerm={searchTerm}
            onSearchChange={setSearchTerm}
            filterType={filterType}
            onFilterChange={setFilterType}
          />

          <PlanBanner userPlan={userPlan} />

          <div className="mycred-addons-shell-body">
            <Toolbar
              activeTab={activeTab}
              onTabChange={setActiveTab}
              tabCounts={tabCounts}
            />

            {sectionsToRender.map(({ section, visible }) => (
              <AddonSection
                key={section.id}
                title={section.title}
                description={section.description}
                tabId={section.tabId}
                addons={visible}
                {...sharedCardProps}
              />
            ))}

            {!initialLoading && totalVisible === 0 && (
              <div className="mycred-addons-empty">
                {__(
                  "No add-ons match the current filters. Clear the search or choose a different filter.",
                  "mycred"
                )}
              </div>
            )}

            {!toolkitInstalled && (
              <p className="mycred-addons-install-note">
                {__(
                  "When you install the Addons Package, the myCred Addons plugin will be downloaded from WordPress.org and installed on your site automatically.",
                  "mycred"
                )}
              </p>
            )}
          </div>
        </div>
      </div>

      <UpgradeDialog open={open} handleClose={handleClose} />
      <Notification />
    </>
  );
};

export default App;
