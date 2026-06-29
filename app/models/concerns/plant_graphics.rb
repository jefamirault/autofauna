module PlantGraphics
  extend ActiveSupport::Concern

  GRAPHICS_DIR = Rails.root.join("app", "assets", "images", "plant_graphics")

  # Cap uploaded images to a sensible display size; the original is kept in storage.
  GRAPHIC_VARIANT = { resize_to_limit: [600, 600] }.freeze

  ACCEPTED_IMAGE_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_IMAGE_SIZE = 10.megabytes

  included do
    has_one_attached :custom_image

    validate :graphic_must_be_available, if: :graphic?
    validate :custom_image_must_be_valid, if: -> { custom_image.attached? }
  end

  class_methods do
    def available_graphics
      return [] unless File.directory?(GRAPHICS_DIR)

      Dir.glob(File.join(GRAPHICS_DIR, "*.png")).map do |path|
        File.basename(path, ".png")
      end.sort
    end

    def graphics_for_select
      available_graphics.map { |name| [name.humanize, name] }
    end

    def match_graphic_for_name(name)
      return nil if name.blank?

      normalized_name = name.to_s.downcase.gsub(/[_-]/, " ").strip
      available_graphics.find do |graphic_name|
        # Check if the plant name contains the graphic name (with underscores replaced by spaces)
        graphic_words = graphic_name.downcase.gsub(/[_-]/, " ")
        normalized_name.include?(graphic_words)
      end
    end
  end

  # True when the plant has any displayable graphic — an uploaded image or a library graphic.
  def has_graphic?
    custom_image.attached? || library_graphic_path.present?
  end

  # Something `image_tag` can render: a resized Active Storage variant when the user has
  # uploaded a custom image, otherwise the library asset-path string, otherwise nil.
  # A custom upload always takes precedence over the library selection.
  def display_graphic
    if custom_image.attached?
      custom_image.variant(GRAPHIC_VARIANT)
    else
      library_graphic_path
    end
  end

  # Backwards-compatible: the library asset path only (ignores any custom upload).
  def graphic_path
    library_graphic_path
  end

  private

  def library_graphic_path
    return nil unless graphic.present? && self.class.available_graphics.include?(graphic)

    "plant_graphics/#{graphic}.png"
  end

  def graphic_must_be_available
    unless self.class.available_graphics.include?(graphic)
      errors.add(:graphic, "is not available in the graphics library")
    end
  end

  def custom_image_must_be_valid
    unless custom_image.content_type.in?(ACCEPTED_IMAGE_TYPES)
      errors.add(:custom_image, "must be a PNG, JPEG, WEBP, or GIF image")
    end

    if custom_image.byte_size.to_i > MAX_IMAGE_SIZE
      errors.add(:custom_image, "is too large (maximum 10MB)")
    end
  end
end
