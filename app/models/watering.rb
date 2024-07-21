class Watering < ApplicationRecord
  belongs_to :plant
  validates :date, presence: true

  after_save_commit :schedule_next_watering
  after_destroy :schedule_next_watering

  after_save_commit :update_watering_intervals
  after_destroy :update_watering_intervals

  # interval: integer # of days between this watering and the last watering for the same plant
  def interval
    if super.nil?
      set_interval
    else
      super
    end
  end

  def set_interval
    current = plant.waterings.index self
    if current > 0
      prev_watering = plant.waterings[current - 1]
      self.interval = (self.date.to_date - prev_watering.date.to_date).to_i
    else
      # this is the first watering logged for this plant
      self.interval = -1
    end
    self.interval if save
  end

  def interval_text
    if interval >= 0
      "#{interval} days"
    else
      "n/a"
    end
  end

  private

  def schedule_next_watering(options = {})
    # run on create/delete, or if date changed
    if previous_changes[:id] || previous_changes[:date] || self.destroyed? || options[:force]
      plant.schedule_next_watering
    end
  end

  def update_watering_intervals
    if previous_changes[:id] || previous_changes[:date] || self.destroyed?
      later_waterings = plant.waterings.select {|w| w.date > self.date}
      later_waterings.each &:set_interval
    end
  end
end
