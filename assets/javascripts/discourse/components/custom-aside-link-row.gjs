import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import withEventValue from "discourse/helpers/with-event-value";
import discourseLater from "discourse/lib/later";
import DButton from "discourse/ui-kit/d-button";
import DIconGridPicker from "discourse/ui-kit/d-icon-grid-picker";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class CustomAsideLinkRow extends Component {
  @service site;

  @tracked dragCssClass;
  dragCount = 0;

  isAboveElement(event) {
    event.preventDefault();
    const domRect = event.currentTarget.getBoundingClientRect();
    return event.offsetY < domRect.height / 2;
  }

  @action
  dragHasStarted(event) {
    event.dataTransfer.effectAllowed = "move";
    this.args.setDraggedLinkCallback(this.args.link);
    this.dragCssClass = "dragging";
  }

  @action
  dragOver(event) {
    event.preventDefault();
    if (this.dragCssClass !== "dragging") {
      this.dragCssClass = this.isAboveElement(event)
        ? "drag-above"
        : "drag-below";
    }
  }

  @action
  dragEnter() {
    this.dragCount++;
  }

  @action
  dragLeave() {
    this.dragCount--;
    if (
      this.dragCount === 0 &&
      (this.dragCssClass === "drag-above" || this.dragCssClass === "drag-below")
    ) {
      discourseLater(() => {
        this.dragCssClass = null;
      }, 10);
    }
  }

  @action
  dropItem(event) {
    event.stopPropagation();
    this.dragCount = 0;
    this.args.reorderCallback(this.args.link, this.isAboveElement(event));
    this.dragCssClass = null;
  }

  @action
  dragEnd() {
    this.dragCount = 0;
    this.dragCssClass = null;
  }

  <template>
    <div
      {{on "dragover" this.dragOver}}
      {{on "dragenter" this.dragEnter}}
      {{on "dragleave" this.dragLeave}}
      {{on "dragend" this.dragEnd}}
      {{on "drop" this.dropItem}}
      role="row"
      data-row-id={{@link.objectId}}
      class={{dConcatClass
        "sidebar-section-form-link"
        "row-wrapper"
        this.dragCssClass
      }}
    >
      {{#if this.site.desktopView}}
        <div
          {{on "dragstart" this.dragHasStarted}}
          class="draggable"
          draggable="true"
        >
          {{dIcon "grip-lines"}}
        </div>
      {{/if}}

      <div class="input-group" role="cell">
        <DIconGridPicker
          @value={{@link.icon}}
          @onChange={{fn (mut @link.icon)}}
          @showCaret={{true}}
          aria-label={{i18n "sidebar.sections.custom.links.icon.label"}}
        />
      </div>

      <div class="input-group" role="cell">
        {{! eslint-disable-next-line ember/template-no-nested-interactive }}
        <Input
          {{on "input" (withEventValue (fn (mut @link.label)))}}
          @type="text"
          @value={{@link.label}}
          name="link-name"
          aria-label={{i18n "sidebar.sections.custom.links.name.label"}}
        />
      </div>

      <div class="input-group" role="cell">
        {{! eslint-disable-next-line ember/template-no-nested-interactive }}
        <Input
          {{on "input" (withEventValue (fn (mut @link.href)))}}
          @type="text"
          @value={{@link.href}}
          name="link-url"
          aria-label={{i18n "sidebar.sections.custom.links.value.label"}}
        />
      </div>

      <DButton
        @icon="trash-can"
        @action={{fn @deleteLink @link}}
        @title="sidebar.sections.custom.links.delete"
        role="cell"
        class="btn-flat delete-link"
      />
    </div>
  </template>
}
