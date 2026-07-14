import { apiInitializer } from "discourse/lib/api";

const ENTRY_SEPARATOR = "|";
const LINK_FIELD_SEPARATOR = ",";
const SECTION_NAME = "custom-aside-links";

// Site settings of type `list`/`group_list` are exposed client-side as a
// raw pipe-delimited string, not an array — split on "|" ourselves.
function parseLinks(rawList) {
  return (rawList || "")
    .split(ENTRY_SEPARATOR)
    .filter(Boolean)
    .map((line) => line.split(LINK_FIELD_SEPARATOR).map((part) => part.trim()))
    .filter(([, label, href]) => label && href)
    .map(([icon, label, href]) => ({ icon: icon || "link", label, href }));
}

function parseGroupIds(rawGroupList) {
  return (rawGroupList || "")
    .split(ENTRY_SEPARATOR)
    .filter(Boolean)
    .map((id) => parseInt(id, 10));
}

export default apiInitializer((api) => {
  const siteSettings = api.container.lookup("service:site-settings");

  if (!siteSettings.custom_aside_links_enabled) {
    return;
  }

  const links = parseLinks(siteSettings.custom_aside_links);
  if (!links.length) {
    return;
  }

  const allowedGroupIds = parseGroupIds(siteSettings.custom_aside_links_visible_groups);

  api.addSidebarSection((BaseCustomSidebarSection, BaseCustomSidebarSectionLink) => {
    const sectionLinks = links.map((link, index) => {
      return class extends BaseCustomSidebarSectionLink {
        get name() {
          return `${SECTION_NAME}-${index}`;
        }

        get title() {
          return link.label;
        }

        get text() {
          return link.label;
        }

        get href() {
          return link.href;
        }

        get prefixType() {
          return "icon";
        }

        get prefixValue() {
          return link.icon;
        }
      };
    });

    return class extends BaseCustomSidebarSection {
      get name() {
        return SECTION_NAME;
      }

      get text() {
        return siteSettings.custom_aside_links_section_title;
      }

      get title() {
        return siteSettings.custom_aside_links_section_title;
      }

      get links() {
        return sectionLinks;
      }

      get displaySection() {
        if (!allowedGroupIds.length) {
          return true;
        }

        const currentUser = api.getCurrentUser();
        if (!currentUser) {
          return false;
        }

        const userGroupIds = (currentUser.groups || []).map((group) => group.id);
        return userGroupIds.some((id) => allowedGroupIds.includes(id));
      }
    };
  });
});
