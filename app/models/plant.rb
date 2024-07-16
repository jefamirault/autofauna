class Plant < ApplicationRecord
  has_many :waterings, -> { order 'waterings.date' }, dependent: :destroy


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
      first_watering && last_watering ? (last_watering + watering_frequency).to_date : Date.today
    end
  end

  def time_until_watering
    scheduled_watering ? (scheduled_watering - Date.today).to_i : nil
  end

  def time_until_watering_text
    if scheduled_watering
      days = time_until_watering
      style = if days < 0
                'color: #D81B60'
              elsif days == 0
                'color: #0E487B'
              else
                ''
              end
      "<span style=\"#{style}\">#{days} days</span>".html_safe
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

  def schedule_next_watering
    waterings = self.waterings.order(:date)
    last = waterings[-1]
    if self.manual_watering_frequency
      self.update(scheduled_watering: last.date + self.watering_frequency * 1.day )
    elsif waterings.count > 1
      waterings = self.waterings.order(date: :desc)
      last_interval = last.date - waterings[-2].date
      self.update(scheduled_watering: last.date + last_interval)
    end
  end
end
