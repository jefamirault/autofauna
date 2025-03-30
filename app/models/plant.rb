class Plant < ApplicationRecord
  belongs_to :project
  belongs_to :location, optional: true
  has_many :waterings, -> { order 'waterings.date' }, dependent: :destroy
  belongs_to :last_watering, class_name: 'Watering', optional: true

  before_validation :strip_whitespace

  validates_uniqueness_of :uid, scope: :project_id

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

  def first_watering
    waterings.any? ? waterings.first.date.to_date : nil
  end

  def last_watering
    super || waterings.any? ? waterings.last : nil
  end

  def calculate_watering_frequency
    if waterings.count < 2
      return nil
    end
    min = 999999 # this will only work until 2739, RemindMe! in 725 years
    max = 0
    last = waterings.first.date
    watering_dates = waterings.map {|w| w.date }
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
      "#{min_watering_freq} day#{min_watering_freq == 1 ? '' : 's'}"
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
        "#{max_watering_days * -1} days late"
      elsif max_watering_days == 0
        "Today"
      elsif min_watering_days > 0
        "Water in #{min_watering_days} - #{max_watering_days} days"
      else
        "Water within #{max_watering_days} day#{max_watering_days > 1 ? 's' : ''}"
      end
    else
      "Unscheduled"
    end
  end

  def last_fertilized
    if waterings.nil? || waterings.empty?
      nil
    else
      last_fertilization = waterings.order(:date).reverse.find {|w| w.notes =~ /fertilizer/}
      last_fertilization ? last_fertilization.date : nil
    end
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
    %w[uid name location name pot date_last_watering
        date_sort_watering min_watering_freq max_watering_freq date_min_watering date_max_watering
        archived created_at updated_at project_id, date_last_watering]
  end
  def self.ransackable_associations(auth_object = nil)
    %w[]
  end

  # private

  def update_watering_dates
    dates = waterings.map &:date
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
