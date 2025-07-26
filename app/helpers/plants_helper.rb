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
end
