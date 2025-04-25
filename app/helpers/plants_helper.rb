module PlantsHelper
  def plant_log_entry_form_path(options = {})
    if params[:action] == 'edit'
      plant_log_entry_path(plant_id: options[:plant].id, id: options[:log_entry].id)
    else
      plant_log_entries_path(options[:plant])
    end
  end
end
