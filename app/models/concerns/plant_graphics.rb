module PlantGraphics
  extend ActiveSupport::Concern

  GRAPHICS_DIR = Rails.root.join("app", "assets", "images", "plant_graphics")

  included do
    validate :graphic_must_be_available, if: :graphic?
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

  def graphic_path
    return nil unless graphic.present? && self.class.available_graphics.include?(graphic)

    "plant_graphics/#{graphic}.png"
  end

  private

  def graphic_must_be_available
    unless self.class.available_graphics.include?(graphic)
      errors.add(:graphic, "is not available in the graphics library")
    end
  end
end
