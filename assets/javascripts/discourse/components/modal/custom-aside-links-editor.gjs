import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { isEmpty } from "@ember/utils";
import { extractError } from "discourse/lib/ajax-error";
import { removeValueFromArray } from "discourse/lib/array-tools";
import { afterRender, bind } from "discourse/lib/decorators";
import { autoTrackedArray } from "discourse/lib/tracked-tools";
import { sanitize } from "discourse/lib/text";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import CustomAsideLinkRow from "../custom-aside-link-row";

class Link {
  @tracked icon;
  @tracked label;
  @tracked href;

  constructor({ icon, label, href, objectId }) {
    this.icon = icon || "link";
    this.label = label || "";
    this.href = href || "";
    this.objectId = objectId;
  }

  get valid() {
    return !isEmpty(this.icon) && !isEmpty(this.label) && !isEmpty(this.href);
  }
}

function parseLinks(rawValue) {
  try {
    const parsed = JSON.parse(rawValue || "[]");
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export default class CustomAsideLinksEditorModal extends Component {
  @tracked flash;
  @tracked flashType;
  @tracked saving = false;

  nextObjectId = 0;

  @autoTrackedArray links = parseLinks(this.args.model.value).map((link) => {
    this.nextObjectId++;
    return new Link({ ...link, objectId: this.nextObjectId });
  });

  get valid() {
    return this.links.length > 0 && this.links.every((link) => link.valid);
  }

  @bind
  setDraggedLink(link) {
    this.draggedLink = link;
  }

  @bind
  reorder(targetLink, above) {
    if (this.draggedLink === targetLink) {
      return;
    }

    removeValueFromArray(this.links, this.draggedLink);
    const toPosition = this.links.indexOf(targetLink);
    this.links.splice(above ? toPosition : toPosition + 1, 0, this.draggedLink);
  }

  @bind
  deleteLink(link) {
    removeValueFromArray(this.links, link);
  }

  @afterRender
  focusNewRowInput(id) {
    document
      .querySelector(`[data-row-id="${id}"] .d-icon-grid-picker-trigger`)
      ?.focus();
  }

  @action
  addLink() {
    this.nextObjectId++;
    this.links.push(new Link({ icon: "link", objectId: this.nextObjectId }));
    this.focusNewRowInput(this.nextObjectId);
  }

  @action
  async save() {
    this.saving = true;
    this.flash = null;

    const value = JSON.stringify(
      this.links.map((link) => ({
        icon: link.icon,
        label: link.label,
        href: link.href,
      }))
    );

    try {
      await this.args.model.save(value);
      // Reload so the settings row picks up the new value/overridden state —
      // we saved via a direct ajax call, bypassing the row's own buffered
      // state that a page refresh would otherwise keep in sync.
      window.location.reload();
    } catch (e) {
      this.flash = sanitize(extractError(e));
      this.flashType = "error";
    } finally {
      this.saving = false;
    }
  }

  <template>
    <DModal
      @closeModal={{@closeModal}}
      @flash={{this.flash}}
      @flashType={{this.flashType}}
      @title={{i18n
        "admin.site_settings.json_schema.modal_title"
        name="custom aside links"
      }}
      class="sidebar-section-form-modal custom-aside-links-editor-modal"
    >
      <:body>
        <div
          role="table"
          aria-rowcount={{this.links.length}}
          class="sidebar-section-form__links-wrapper"
        >
          <div class="row-wrapper header" role="row">
            <div class="input-group link-icon" role="columnheader">
              {{! eslint-disable-next-line ember/template-no-nested-interactive }}
              <label>{{i18n "sidebar.sections.custom.links.icon.label"}}</label>
            </div>
            <div class="input-group link-name" role="columnheader">
              {{! eslint-disable-next-line ember/template-no-nested-interactive }}
              <label>{{i18n "sidebar.sections.custom.links.name.label"}}</label>
            </div>
            <div class="input-group link-url" role="columnheader">
              {{! eslint-disable-next-line ember/template-no-nested-interactive }}
              <label>{{i18n "sidebar.sections.custom.links.value.label"}}</label>
            </div>
          </div>

          {{#each this.links as |link|}}
            <CustomAsideLinkRow
              @link={{link}}
              @deleteLink={{this.deleteLink}}
              @reorderCallback={{this.reorder}}
              @setDraggedLinkCallback={{this.setDraggedLink}}
            />
          {{/each}}
        </div>

        <DButton
          @action={{this.addLink}}
          @icon="plus"
          @label="sidebar.sections.custom.links.add"
          @ariaLabel="sidebar.sections.custom.links.add"
          class="btn-flat btn-text add-link"
        />
      </:body>
      <:footer>
        <DButton
          @action={{this.save}}
          @label="save"
          @isLoading={{this.saving}}
          @disabled={{not this.valid}}
          class="btn-primary"
        />
      </:footer>
    </DModal>
  </template>
}
