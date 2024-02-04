class Plant < ApplicationRecord
  has_many :waterings, -> { order 'waterings.date' }

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
    if !super.nil?
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
    suggested_watering ? (suggested_watering - Date.today).to_i : nil
  end

  def time_until_watering_text
    if suggested_watering
      days = time_until_watering
      style = if days < 0
                'color: red'
              elsif days == 0
                'color: blue'
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
end
