class Watering < ApplicationRecord
  belongs_to :plant
  validates :date, presence: true

  after_save_commit :update_frequency
  after_save_commit :schedule_next_watering
  after_destroy :schedule_next_watering

  # interval: integer # of days between this watering and the last watering for the same plant
  def interval
    if super.nil?
      current = plant.waterings.index self
      if current > 0
        prev_watering = plant.waterings[current - 1]
        self.interval = (self.date.to_date - prev_watering.date.to_date).to_i
      else
        # this is the first watering logged for this plant
        self.interval = -1
      end
      self.interval if save
    else
      super
    end
  end

  def interval_text
    if interval >= 0
      "#{interval} days"
    else
      "n/a"
    end
  end

  private

  def update_frequency
    if plant && !plant.manual_watering_frequency
      if previous_changes[:plant_id]
        # If the plant was changed when the watering gets updated, recalculate watering freq for both plants
        previous_changes[:plant_id].compact.map {|id| Plant.find(id)}.each &:calculate_watering_frequency
      else
        plant.calculate_watering_frequency
      end
    end
  end

  def schedule_next_watering(options = {})
    # run on create/delete, or if date changed
    if previous_changes[:id] || previous_changes[:date] || self.destroyed? || options[:force]
      plant.schedule_next_watering
    end
  end
end
