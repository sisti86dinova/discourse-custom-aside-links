# frozen_string_literal: true

module DiscourseCustomAsideLinks
  class CustomAsideLinksJsonSchema
    def self.schema
      @schema ||= {
        type: "array",
        uniqueItems: true,
        items: {
          type: "object",
          title: "Link",
          properties: {
            icon: {
              type: "string",
              default: "link",
              description: "Font Awesome icon name (e.g. far-pen-to-square)",
            },
            label: {
              type: "string",
              description: "Link text",
            },
            href: {
              type: "string",
              description: "URL, relative (e.g. /w/documento) or absolute",
            },
          },
          required: %w[label href],
        },
      }
    end
  end
end
