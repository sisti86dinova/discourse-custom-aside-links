import { apiInitializer } from "discourse/lib/api";
import CustomAsideLinksEditButton from "../components/custom-aside-links-edit-button";

const ENTRY_SEPARATOR = "|";
const SECTION_NAME = "custom-aside-links";

// Site settings backed by a `json_schema` are exposed client-side as a raw
// JSON string, not an array — parse it ourselves.
function parseLinks(rawJson) {
  let links;
  try {
    links = JSON.parse(rawJson || "[]");
  } catch {
    return [];
  }

  if (!Array.isArray(links)) {
    return [];
  }

  return links
    .filter(({ label, href } = {}) => label && href)
    .map(({ icon, label, href }) => ({ icon: icon || "link", label, href }));
}

// Site settings of type `group_list` are exposed client-side as a raw
// pipe-delimited string, not an array — split on "|" ourselves.
function parseGroupIds(rawGroupList) {
  return (rawGroupList || "")
    .split(ENTRY_SEPARATOR)
    .filter(Boolean)
    .map((id) => parseInt(id, 10));
}

export default apiInitializer((api) => {
  api.renderInOutlet("site-setting-after-label", CustomAsideLinksEditButton);

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
        return sectionLinks.map((Link) => new Link());
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
