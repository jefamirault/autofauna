class Plant < ApplicationRecord
  include PlantGraphics

  belongs_to :project
  belongs_to :location, optional: true
  belongs_to :recipe, optional: true  # primary recipe (cached for filtering/Ransack)
  has_many :plant_recipes, -> { order(:position) }, dependent: :destroy
  has_many :recipes, through: :plant_recipes
  has_one :zone, through: :location
  has_many :waterings, -> { order 'waterings.watered_at' }, dependent: :destroy
  belongs_to :last_watering, class_name: 'Watering', optional: true
  has_many :log_entries, as: :loggable, dependent: :destroy
  has_many :soil_moisture_readings, dependent: :destroy
  has_many :plant_group_memberships, dependent: :destroy
  has_many :plant_groups, through: :plant_group_memberships

  before_validation :strip_whitespace
  before_validation :set_default_max_watering_freq, on: :create
  before_validation :clear_layout_on_location_change

  # Keep recipe_id in sync with the first plant_recipe entry
  def sync_primary_recipe!
    first_recipe = plant_recipes.order(:position).first&.recipe
    update_column(:recipe_id, first_recipe&.id)
  end

  validates_uniqueness_of :uid, scope: :project_id

  # Diagram position on the location canvas — normalized, so 0 is the left/top edge and 1
  # the right/bottom edge regardless of how wide the canvas renders.
  validates :layout_x, :layout_y,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true

  after_save_commit :sync_watering_dates_if_schedule_changed

  # Placed on its location's diagram. Both coordinates are written together, but check
  # each — a half-written pair should read as unplaced rather than land at an edge.
  def layout_placed?
    layout_x.present? && layout_y.present?
  end

  def container
    self.pot
  end

  def container=(string)
    self.pot = string
  end

  def label
    "##{uid} #{name}"
  end

  def to_s
    label
  end

  def generate_share_token!
    if share_token.nil?
      update!(share_token: SecureRandom.urlsafe_base64(16), share_enabled: true)
    else
      update!(share_enabled: true)
    end
  end

  def revoke_share_token!
    update!(share_enabled: false)
  end

  def regenerate_share_token!
    update!(share_token: SecureRandom.urlsafe_base64(16), share_enabled: true)
  end

  def shared?
    share_token.present? && share_enabled?
  end

  # One-click watering: carry forward the last watering's details and create a new one.
  # Shared by PlantsController#quick_water and group/location bulk watering.
  def quick_water!(at: Time.current, overrides: {})
    attrs = { watered_at: at }
    if (last = last_watering)
      attrs.merge!(
        volume: last.volume,
        units: last.units,
        notes: last.notes,
        recipe_id: last.recipe_id,
        recipe_batch_id: last.recipe_batch_id,
        tds: last.tds
      )
    end
    attrs.merge!(overrides.compact_blank) # explicit values win; blanks keep carry-forward
    waterings.create!(attrs)
  end

  def first_watering
    waterings.any? ? waterings.first.watered_at&.to_date : nil
  end

  def last_watering
    super || (waterings.any? ? waterings.last : nil)
  end

  def suggested_watering_unit
    waterings.any? ? waterings.sort_by {|w| [w.watered_at, w.updated_at]}.last.units : 'cups'
  end

  def calculate_watering_frequency
    if waterings.count < 2
      return nil
    end
    min = 999999 # this will only work until 2739, RemindMe! in 725 years
    max = 0
    last = waterings.first.watered_at.to_date
    watering_dates = waterings.map {|w| w.watered_at.to_date }
    # get all waterings except the first one
    watering_dates[1..-1].each do |date|
      interval = date - last
      if interval < min
        min = interval
      end
      if interval > max
        max = interval
      end
      last = date
    end
    self.min_watering_freq = min
    self.max_watering_freq = max
    save
  end
  def watering_frequency
    [min_watering_freq, max_watering_freq]
  end

  def watering_frequency_text
    return '' if min_watering_freq.nil? && max_watering_freq.nil?
    if min_watering_freq == max_watering_freq
      "Every #{min_watering_freq} day#{min_watering_freq == 1 ? '' : 's'}"
    else
      "#{min_watering_freq} - #{max_watering_freq} days"
    end
  end

  def suggested_watering
    if waterings.count <= 1
      nil
    else
      first_watering && last_watering ? (last_watering + watering_frequency).to_date : Time.zone.now.to_date
    end
  end

  def time_until_watering
    date_min_watering ? (date_min_watering - Time.zone.now.to_date).to_i : nil
  end

  def time_until_watering_text
    if date_last_watering && min_watering_freq && max_watering_freq
      min_watering_days = ((date_last_watering + min_watering_freq.days) - Time.zone.now.to_date).to_i
      max_watering_days = ((date_last_watering + max_watering_freq.days) - Time.zone.now.to_date).to_i
      if max_watering_days < 0
        late_days = max_watering_days * -1
        I18n.t("plants.watering_status.late", count: late_days, days: late_days)
      elsif max_watering_days == 0
        I18n.t("plants.watering_status.today")
      elsif min_watering_days > 0
        if min_watering_freq == max_watering_freq
          I18n.t("plants.watering_status.in_days", count: min_watering_days, days: min_watering_days)
        else
          I18n.t("plants.watering_status.in_range", min: min_watering_days, max: max_watering_days)
        end
      else
        I18n.t("plants.watering_status.within", count: max_watering_days, days: max_watering_days)
      end
    else
      if date_last_watering.nil?
        I18n.t("plants.watering_status.never_watered", default: "Water this plant to begin tracking")
      else
        I18n.t("plants.watering_status.unscheduled")
      end
    end
  end

  def time_until_watering_short_text
    if date_last_watering && min_watering_freq && max_watering_freq
      max_watering_days = ((date_last_watering + max_watering_freq.days) - Time.zone.now.to_date).to_i
      if max_watering_days < 0
        late_days = max_watering_days * -1
        I18n.t("plants.watering_status.short_late", count: late_days, days: late_days)
      elsif max_watering_days == 0
        I18n.t("plants.watering_status.short_today")
      else
        min_watering_days = ((date_last_watering + min_watering_freq.days) - Time.zone.now.to_date).to_i
        if min_watering_days > 0
          if min_watering_freq == max_watering_freq
            I18n.t("plants.watering_status.short_in_days", count: min_watering_days, days: min_watering_days)
          else
            I18n.t("plants.watering_status.short_in_range", min: min_watering_days, max: max_watering_days)
          end
        else
          I18n.t("plants.watering_status.short_within", count: max_watering_days, days: max_watering_days)
        end
      end
    else
      "—"
    end
  end

  def snoozed?
    snoozed_until.present? && snoozed_until > Time.current
  end

  def snooze!(duration_days)
    update!(snoozed_until: duration_days.days.from_now)
  end

  def unsnooze!
    update!(snoozed_until: nil)
  end

  def watering_urgency
    return :scheduled unless date_last_watering && max_watering_freq
    max_watering_days = ((date_last_watering + max_watering_freq.days) - Time.zone.now.to_date).to_i
    max_watering_days <= 0 ? :needs_water : :scheduled
  end

  def last_fertilized
    if waterings.nil? || waterings.empty?
      nil
    else
      last_fertilization = waterings.order(:watered_at).reverse.find {|w| w.notes =~ /fertilizer/}
      last_fertilization ? last_fertilization.watered_at&.to_date : nil
    end
  end

  def set_default_max_watering_freq
    if min_watering_freq.present? && max_watering_freq.blank?
      self.max_watering_freq = min_watering_freq
    end
  end

  def generate_view_share_token!
    if view_share_token.nil?
      update!(view_share_token: SecureRandom.urlsafe_base64(16), view_share_enabled: true)
    else
      update!(view_share_enabled: true)
    end
  end

  def revoke_view_share_token!
    update!(view_share_enabled: false)
  end

  def regenerate_view_share_token!
    update!(view_share_token: SecureRandom.urlsafe_base64(16), view_share_enabled: true)
  end

  def view_shared?
    view_share_token.present? && view_share_enabled?
  end

  def strip_whitespace
    if changes['location']
      self.location = self.location.strip
    end
    if changes['name']
      self.name = self.name.strip
    end
    if changes['pot']
      self.pot = self.pot.strip
    end
  end

  # Coordinates are meaningful only against the diagram they were placed on, so moving a
  # plant to another location sends it back to that location's tray instead of dropping it
  # at whatever spot it happened to occupy before.
  # NOTE: `plants#bulk_set_location` reassigns with `update_all` and skips this callback —
  # it clears the columns itself.
  def clear_layout_on_location_change
    return unless will_save_change_to_location_id?

    self.layout_x = nil
    self.layout_y = nil
  end

  def self.create_from_json(json, project)
    p = Plant.new do |p|
      p.id = json['id']
      p.uid = json['uid']
      p.project = project
      p.name = json['name']
      p.location = json['location']
      p.container = json['container']
      p.min_watering_freq = json['min_watering_freq'] || json['watering_frequency']
      p.max_watering_freq = json['max_watering_freq'] || json['watering_frequency']
      p.date_last_watering = json['date_last_watering']
      p.archived = json['archived']
      p.created_at = json['created_at']
    end
    p.save
    p
  end

  def self.next_uid
    starting_id = 1
    max = Plant.pluck(:uid).max
    max ? max + 1 : starting_id
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[uid name pot date_last_watering location_id recipe_id
        date_sort_watering min_watering_freq max_watering_freq date_min_watering date_max_watering
        archived created_at updated_at project_id date_last_watering graphic]
  end
  def self.ransackable_associations(auth_object = nil)
    %w[location recipe]
  end

  def location_with_zone
    if location.nil?
      nil
    elsif zone.nil?
      self.location
    else
      "#{self.location} - #{self.zone}"
    end
  end

  def last_watering_text
    self.last_watering&.watering_text
  end

  def latest_moisture_reading
    soil_moisture_readings.recent.first
  end

  def latest_moisture_value
    latest_moisture_reading&.display_value
  end

  # private

  def sync_watering_dates_if_schedule_changed
    if previous_changes[:min_watering_freq] || previous_changes[:max_watering_freq]
      update_watering_dates
    end
  end

  def update_watering_dates
    dates = waterings.map { |w| w.watered_at&.to_date }.compact
    self.date_last_watering = dates.last
    if self.date_last_watering
      self.date_min_watering = min_watering_freq ? date_last_watering + min_watering_freq : nil
      self.date_max_watering = max_watering_freq ? date_last_watering + max_watering_freq : nil
      self.date_sort_watering = min_watering_freq && max_watering_freq ? date_last_watering + (max_watering_freq + min_watering_freq) / 2 : nil
    else
      self.date_min_watering = nil
      self.date_max_watering = nil
      self.date_sort_watering = nil
    end
    save
  end
end
