module PlantsHelper
  def plant_log_entry_form_path(options = {})
    if params[:action] == 'edit'
      plant_log_entry_path(plant_id: options[:plant].id, id: options[:log_entry].id)
    else
      plant_log_entries_path(options[:plant])
    end
  end

  def last_watering_text(plant)
    watering = plant.last_watering
    if watering.nil?
      'Never'
    else
      if watering.volume.nil? && (watering.notes.nil? || watering.notes == '')
        time_ago plant.date_last_watering
      else
        "#{time_ago plant.date_last_watering} - #{watering.volume_and_notes}"
      end
    end
  end

  def last_watering_time_text(plant)
    watering = plant.last_watering
    if watering.nil?
      'Never'
    else
      "Watered <strong>#{time_ago plant.date_last_watering}</strong>"
    end
  end

  def last_watering_time_short_text(plant)
    watering = plant.last_watering
    if watering.nil?
      'Never'
    else
      days_ago = (Time.zone.now.to_date - plant.date_last_watering.to_date).to_i
      if days_ago == 0
        '<strong>Today</strong>'
      elsif days_ago == 1
        '<strong>1 day</strong>'
      else
        "<strong>#{days_ago} days</strong>"
      end
    end
  end

  def last_watering_volume_text(plant)
    watering = plant.last_watering
    return nil if watering.nil? || watering.volume.nil?
    watering.print_volume
  end

  def last_watering_notes_text(plant)
    watering = plant.last_watering
    return nil if watering.nil? || watering.notes.blank?
    watering.notes
  end
end
