# Shared photo-attachment behavior for records that carry a single `:picture`
# (Tank, Location). Plants use a different, plant-specific system
# (concerns/plant_graphics.rb with custom_image) — this concern is only for the
# straightforward "one uploaded photo" pattern.
module HasPicture
  extend ActiveSupport::Concern

  ACCEPTED_PICTURE_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_PICTURE_SIZE = 20.megabytes

  # Cap displayed size; the original upload is kept in storage.
  PICTURE_VARIANT = { resize_to_limit: [800, 800] }.freeze
  PICTURE_THUMB_VARIANT = { resize_to_fill: [128, 128] }.freeze

  included do
    has_one_attached :picture

    validate :picture_must_be_valid, if: -> { picture.attached? }
  end

  # True only when a *persisted* upload exists. After a failed save the new attachment is
  # staged with an unpersisted blob, which can't generate a variant URL — treat that as
  # "no picture" so the form/show can re-render validation errors instead of 500ing.
  def picture_attached?
    picture.attached? && picture.blob&.persisted?
  end

  private

  def picture_must_be_valid
    unless picture.content_type.in?(ACCEPTED_PICTURE_TYPES)
      errors.add(:picture, "must be a PNG, JPEG, WEBP, or GIF image")
    end

    if picture.byte_size.to_i > MAX_PICTURE_SIZE
      errors.add(:picture, "is too large (maximum 20MB)")
    end
  end
end
