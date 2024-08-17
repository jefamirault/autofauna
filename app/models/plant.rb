class Plant < ApplicationRecord
  belongs_to :project
  has_many :waterings, -> { order 'waterings.date' }, dependent: :destroy

  before_validation :strip_whitespace
  after_save_commit :determine_schedule_change

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
    waterings.any? ? waterings.last.date.to_date : nil
  end

  def calculate_watering_frequency
    calculated = waterings.count > 1 ? (last_watering - first_watering).to_i / (waterings.count - 1) : nil
    self.watering_frequency = calculated
    calculated if save
  end
  def watering_frequency
    if self.new_record?
      nil
    elsif !super.nil?
      super
    else
      calculate_watering_frequency
    end
  end

  def watering_frequency_text
    watering_frequency ? "#{watering_frequency} days" : nil
  end

  def suggested_watering
    if waterings.count <= 1
      nil
    else
      first_watering && last_watering ? (last_watering + watering_frequency).to_date : Time.zone.now.to_date
    end
  end

  def time_until_watering
    scheduled_watering ? (scheduled_watering - Time.zone.now.to_date).to_i : nil
  end

  def time_until_watering_text
    if scheduled_watering

      days = time_until_watering
      if days < 0
        style = 'color: #D81B60'
        if days == -1
          text = I18n.t 'time.yesterday'
        else
          text = "#{days} #{I18n.t 'time.days'}".html_safe
        end
      elsif days == 0
        style = 'color: #0E487B'
        text = I18n.t('time.today')
      elsif days == 1
        text = I18n.t('time.tomorrow')
      else # days > 1
        text = "#{days} #{I18n.t 'time.days'}".html_safe
      end
      "<span style=\"#{style}\">#{text}</span>".html_safe
    else
      nil
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

  def determine_schedule_change
    if self.previous_changes['manual_watering_frequency'] || self.previous_changes['watering_frequency']
      schedule_next_watering
    end
  end
  def schedule_next_watering
    waterings = self.waterings.order(:date)
    last = waterings[-1]
    return if last.nil?
    if self.manual_watering_frequency
      self.update(scheduled_watering: last.date + self.watering_frequency * 1.day )
    elsif waterings.count > 1
      waterings = self.waterings.order(date: :desc)
      last_interval = last.date - waterings[-2].date
      self.update(scheduled_watering: last.date + last_interval)
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
      p.uid = Plant.next_uid
      p.project = project
      p.name = json['name']
      p.location = json['location']
      p.pot = json['pot']
      p.scheduled_watering = json['scheduled_watering']
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
end
