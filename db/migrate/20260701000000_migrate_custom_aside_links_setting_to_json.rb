# frozen_string_literal: true

class MigrateCustomAsideLinksSettingToJson < ActiveRecord::Migration[7.2]
  def up
    old_value = DB.query_single(
      "SELECT value FROM site_settings WHERE name = 'custom_aside_links'",
    ).first

    return if old_value.blank?
    return if old_value.strip.start_with?("[")

    links =
      old_value
        .split("|")
        .filter_map do |entry|
          icon, label, href = entry.split(",").map(&:strip)
          next if label.blank? || href.blank?

          { icon: icon.presence || "link", label: label, href: href }
        end

    DB.exec(
      "UPDATE site_settings SET value = :value WHERE name = 'custom_aside_links'",
      value: links.to_json,
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
