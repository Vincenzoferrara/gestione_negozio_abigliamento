import { isChildAddon } from "../childAddonConfig";
import { isAddonIncludedInPlanTier } from "../planConfig";

export { isChildAddon };

export function isAddonActive(activeSlugs, slug) {
  if (Array.isArray(activeSlugs)) {
    return activeSlugs.includes(slug);
  }
  if (activeSlugs && typeof activeSlugs === "object") {
    return Object.values(activeSlugs).includes(slug);
  }
  return false;
}

export function isAddonLocked(addon, activeSlugs) {
  const toolkitProActive = window.mycredAddonsData?.toolkitProActive;
  const isEnabled = isAddonActive(activeSlugs, addon.slug);

  if (isEnabled) {
    return false;
  }

  if (addon.type !== "pro") {
    return false;
  }

  return addon.status === "locked" || !toolkitProActive;
}

export function shouldShowProUpgrade(addon, isEnabled) {
  if (isEnabled || addon.type !== "pro") {
    return false;
  }

  const toolkitProActive = window.mycredAddonsData?.toolkitProActive;

  return addon.status === "locked" || !toolkitProActive;
}

export function matchesSearch(addon, query) {
  if (!query) {
    return true;
  }
  const q = query.trim().toLowerCase();
  const haystack = `${addon.title} ${addon.description || ""}`.toLowerCase();
  return haystack.includes(q);
}

export function matchesFilterType(addon, filterType, activeSlugs) {
  switch (filterType) {
    case "all":
      return true;
    case "builtin":
      return addon.type === "builtin";
    case "free":
      return addon.type === "free" || addon.type === "builtin";
    case "pro":
      return addon.type === "pro";
    case "active":
      return isAddonActive(activeSlugs, addon.slug);
    case "plan:basic":
      return addon.type === "pro" && isAddonIncludedInPlanTier(addon.plan, "basic");
    case "plan:professional":
      return addon.type === "pro" && isAddonIncludedInPlanTier(addon.plan, "professional");
    case "plan:business":
      return addon.type === "pro" && isAddonIncludedInPlanTier(addon.plan, "business");
    default:
      return true;
  }
}

export function matchesTab(addon, activeTab, sectionTabId) {
  if (activeTab === "all") {
    return true;
  }
  return sectionTabId === activeTab;
}

export function filterAddon(addon, { searchTerm, filterType, activeTab, sectionTabId, activeSlugs }) {
  if (isChildAddon(addon.slug)) {
    return false;
  }

  return (
    matchesSearch(addon, searchTerm) &&
    matchesFilterType(addon, filterType, activeSlugs) &&
    matchesTab(addon, activeTab, sectionTabId)
  );
}

export function sortAddons(addons, sortMode, activeSlugs) {
  const items = [...addons];

  if (sortMode === "az") {
    return items.sort((a, b) => a.title.localeCompare(b.title));
  }

  if (sortMode === "za") {
    return items.sort((a, b) => b.title.localeCompare(a.title));
  }

  if (sortMode === "active") {
    return items.sort((a, b) => {
      const aOn = isAddonActive(activeSlugs, a.slug) ? 1 : 0;
      const bOn = isAddonActive(activeSlugs, b.slug) ? 1 : 0;
      return bOn - aOn || a.title.localeCompare(b.title);
    });
  }

  return items;
}

export function computeStats(addonsData, activeSlugs) {
  const visible = addonsData.filter((a) => !isChildAddon(a.slug));
  const total = visible.length;
  const active = visible.filter((a) => isAddonActive(activeSlugs, a.slug)).length;
  const proCount = visible.filter((a) => a.type === "pro").length;

  return {
    total,
    active,
    inactive: total - active,
    proCount,
  };
}

export function countVisibleForTab(addonsData, activeTab, sections, activeSlugs, searchTerm, filterType) {
  if (activeTab === "all") {
    return addonsData.filter((addon) =>
      !isChildAddon(addon.slug) &&
      matchesSearch(addon, searchTerm) && matchesFilterType(addon, filterType, activeSlugs)
    ).length;
  }

  const section = sections.find((s) => s.tabId === activeTab);
  if (!section) {
    return 0;
  }

  return addonsData
    .filter(section.match)
    .filter((addon) => filterAddon(addon, { searchTerm, filterType, activeTab, sectionTabId: activeTab, activeSlugs }))
    .length;
}
