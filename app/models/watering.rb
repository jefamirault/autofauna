class Watering < ApplicationRecord
  belongs_to :plant

  after_commit :update_frequency

  # interval: integer # of days between this watering and the last watering for the same plant
  def interval
    if super.nil?
      current = plant.waterings.index self
      if current > 0
        prev_watering = plant.waterings[current - 1]
        self.interval = (self.date - prev_watering.date).to_i
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
    if plant
      if previous_changes[:plant_id]
        # If the plant was changed when the watering gets updated, recalculate watering freq for both plants
        previous_changes[:plant_id].compact.map {|id| Plant.find(id)}.each &:calculate_watering_frequency
      else
        plant.calculate_watering_frequency
      end
    end
  end
end
