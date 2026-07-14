# frozen_string_literal: true

# name: discourse-custom-aside-links
# about: Adds an admin-configurable collapsible sidebar section with custom links, restricted to selected groups
# meta_topic_id:
# version: 0.1.0
# authors: Stefano Sisti
# url: https://github.com/dinova-one/discourse-custom-aside-links
# required_version: 2.7.0

require_relative "lib/discourse_custom_aside_links/custom_aside_links_json_schema"

enabled_site_setting :custom_aside_links_enabled
