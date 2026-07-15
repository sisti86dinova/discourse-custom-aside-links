import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/ui-kit/d-button";
import CustomAsideLinksEditorModal from "./modal/custom-aside-links-editor";

const SETTING_NAME = "custom_aside_links";

export default class CustomAsideLinksEditButton extends Component {
  @service modal;

  get setting() {
    return this.args.outletArgs?.setting;
  }

  get shouldShow() {
    return this.setting?.setting === SETTING_NAME;
  }

  @action
  openEditor() {
    this.modal.show(CustomAsideLinksEditorModal, {
      model: {
        value: this.setting.value,
        save: (value) =>
          ajax(`/admin/site_settings/${SETTING_NAME}`, {
            type: "PUT",
            data: { [SETTING_NAME]: value },
          }),
      },
    });
  }

  <template>
    {{#if this.shouldShow}}
      <DButton
        @action={{this.openEditor}}
        @icon="pencil"
        @label="admin.site_settings.json_schema.edit"
        class="btn-default custom-aside-links-edit-button"
      />
    {{/if}}
  </template>
}
