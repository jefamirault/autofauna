class User < ApplicationRecord
  FEATURE_FLAGS = %i[track_waterings use_fertilizers precise_measurements track_soil_moisture has_aquarium].freeze

  has_secure_password validations: false

  has_many :collaborations, dependent: :destroy
  has_many :projects, foreign_key: :owner_id, dependent: :destroy
  has_many :plants, through: :projects
  has_many :push_subscriptions, dependent: :destroy
  has_many :weather_locations, dependent: :destroy
  has_many :saved_searches, dependent: :destroy

  after_create :create_default_project

  validates :password, presence: true, length: { minimum: 6 }, if: -> { !guest? && (new_record? || password_digest_changed?) }
  validates :email, presence: true, unless: :guest?
  normalizes :email, with: -> { _1.strip.downcase }
  validates :email, uniqueness: true, allow_blank: true

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email
  end

  def convert_from_guest!(email:, password:, password_confirmation:)
    raise "Not a guest account" unless guest?

    self.guest = false
    self.email = email
    self.password = password
    self.password_confirmation = password_confirmation
    save!
  end

  def convert_from_guest_google!(email:, google_uid:, avatar_url: nil)
    raise "Not a guest account" unless guest?

    self.guest = false
    self.email = email
    self.google_uid = google_uid
    self.avatar_url = avatar_url
    self.password = SecureRandom.hex(32)
    save!
  end

  def merge_guest!(guest_user)
    raise "Source must be a guest" unless guest_user.guest?

    transaction do
      if advanced_mode?
        guest_user.projects.update_all(owner_id: id)
      else
        target_project = projects.first
        guest_user.projects.each do |guest_project|
          max_uid = target_project.plants.maximum(:uid) || 0
          guest_project.plants.order(:uid).each_with_index do |plant, i|
            plant.update_columns(project_id: target_project.id, uid: max_uid + i + 1)
          end
          guest_project.zones.update_all(project_id: target_project.id)
          guest_project.locations.update_all(project_id: target_project.id)
          guest_project.sensors.update_all(project_id: target_project.id)
          HygroSensorReading.where(project_id: guest_project.id).update_all(project_id: target_project.id)
          Tank.where(project_id: guest_project.id).update_all(project_id: target_project.id)
          SensorType.where(project_id: guest_project.id).update_all(project_id: target_project.id)
          guest_project.destroy!
        end
      end

      guest_user.collaborations.where.not(project_id: collaborations.select(:project_id)).update_all(user_id: id)
      LogEntry.where(user_id: guest_user.id).update_all(user_id: id)
      guest_user.reload.destroy!
    end
  end

  def onboarding_completed?
    onboarding_completed_at.present?
  end

  def complete_onboarding!
    update!(onboarding_completed_at: Time.current) unless onboarding_completed?
  end

  # Turn a feature flag on the first time the user actually uses the feature.
  # Idempotent: a no-op when already enabled. Skips validations/callbacks.
  def enable_feature!(flag)
    flag = flag.to_sym
    raise ArgumentError, "unknown feature flag: #{flag}" unless FEATURE_FLAGS.include?(flag)
    update_column(flag, true) unless public_send("#{flag}?")
  end

  def plants_needing_water
    project_ids = projects.pluck(:id) + collaborations.pluck(:project_id)
    Plant.where(project_id: project_ids, archived: false)
      .where.not(date_sort_watering: nil)
      .where("date_sort_watering <= ?", Date.current)
      .where("snoozed_until IS NULL OR snoozed_until <= ?", Time.current)
  end

  def should_send_notification?(channel)
    enabled = send("#{channel}_notifications_enabled?")
    return false unless enabled

    freq_type = send("#{channel}_notification_frequency_type") || "daily"
    freq_value = send("#{channel}_notification_frequency_value") || 1
    notif_time = send("#{channel}_notification_time")
    last_sent = send("last_#{channel}_notification_sent_at")
    now = Time.current

    notif_hour = notif_time&.hour || 9
    notif_min = notif_time&.min || 0

    case freq_type
    when "daily"
      return false if last_sent&.to_date == now.to_date
      now.hour == notif_hour && now.min == notif_min
    when "days"
      return false unless now.hour == notif_hour && now.min == notif_min
      last_sent.nil? || last_sent < (now - freq_value.days).end_of_day
    when "hourly"
      start_minutes = notif_hour * 60 + notif_min
      current_minutes = now.hour * 60 + now.min
      interval_minutes = freq_value * 60
      return false if current_minutes < start_minutes
      offset = (current_minutes - start_minutes) % interval_minutes
      return false unless offset == 0
      last_sent.nil? || last_sent < now.beginning_of_minute
    else
      false
    end
  end

  def mark_email_notification_sent!
    update_column(:last_email_notification_sent_at, Time.current)
  end

  def mark_push_notification_sent!
    update_column(:last_push_notification_sent_at, Time.current)
  end

  def to_s
    self.email || "Guest"
  end

  private

  def create_default_project
    projects.create(name: "My Plants")
  end
end
