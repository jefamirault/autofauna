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
      return 'Never' if plant.date_last_watering.nil?
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

  # Inline custom properties for the plant card's watering-window gauge.
  # The track runs from the last watering to the max due date — or to today when
  # overdue, so the fill visibly overshoots the min→max window band.
  def watering_gauge_style(plant)
    return nil unless plant.date_last_watering && plant.min_watering_freq.present? && plant.max_watering_freq.present?
    return nil unless plant.max_watering_freq.positive?

    elapsed = (Time.zone.now.to_date - plant.date_last_watering.to_date).to_i
    return nil if elapsed.negative?

    total = [elapsed, plant.max_watering_freq].max.to_f
    window_start = (plant.min_watering_freq / total * 100).clamp(0, 94)
    window_end = (plant.max_watering_freq / total * 100).clamp(window_start + 4, 100)
    fill = (elapsed / total * 100).clamp(3, 100)

    format("--window-start: %.1f%%; --window-end: %.1f%%; --fill: %.1f%%", window_start, window_end, fill)
  end
end
