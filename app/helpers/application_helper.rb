module ApplicationHelper

  def time_or_date(datetime)
    return '' if datetime.nil?
    format_string = datetime.today? ? '%I:%M %p' : datetime.strftime('%B %d, %Y')
    datetime.strftime format_string
  end
  def format_date(date, options = {})
    if options[:time]
      if options[:long]
        date ? date.strftime('%A %-m/%-d/%y %r') : ""
      else
        date ? date.strftime('%r %-m/%-d/%y') : ""
      end
    elsif options[:long]
      date ? date.strftime('%A %-m/%-d/%y') : ""
    else
      date ? date.strftime('%a %-m/%-d/%y') : ""
    end
  end

  def format_time(time, options = {})
    format_date time, time: true
  end

  def time_ago(date, options = {})
    if date.nil?
      nil
    else
      text = if date.to_date == Time.zone.now.to_date
               if options[:precise]
                 time_ago_in_words date
               else
                 t 'time.today'
               end
             else
               days_ago = (Time.zone.now.to_date - date.to_date).to_i
               if days_ago == 1
                 t 'time.yesterday'
               else
                 t 'time.days_ago', days: days_ago
               end
             end

      options[:parentheses] ? "(#{text})" : text
    end
  end

  def nav_item(name, selected = false)
    default_class = 'navItem'
    "<a class='#{default_class}#{selected ? ' selected' : ''}'>#{nav_label(name)}</a>".html_safe
  end

  def nav_link(controller, options = {})
    default_class = 'navItem'
    text = options[:text] || t(".#{controller}")
    action = options[:action] || 'index'
    path = options[:path] || send("#{controller}_path")
    label = nav_label(text)
    if params[:controller] == controller
        if params[:action] == action
          nav_item(text, true)
        else
          link_to(label, path, class: default_class)
        end
    else
      link_to(label, path, class: default_class)
    end
  end

  # Split "🌱 Plants" into emoji + <span class="nav-label">Plants</span>
  def nav_label(text)
    parts = text.split(' ', 2)
    if parts.length == 2
      "#{parts[0]} <span class=\"nav-label\">#{ERB::Util.html_escape(parts[1])}</span>".html_safe
    else
      text
    end
  end

  def header_config
    controller = params[:controller]
    action = params[:action]

    case controller
    when 'plants', 'log_entries'
      section_title = t('layouts.application.plants')
      title = action.in?(%w[show edit]) && @plant ? @plant.to_s : section_title
      graphic = action.in?(%w[show edit]) ? @plant&.graphic_path : nil
      { icon: 'autofauna_icon.png', title: title, section_title: section_title, gradient_class: 'header-plants', nav_path: plants_path, plant_graphic: nil, sidebar_graphic: graphic }
    when 'waterings'
      section_title = t('layouts.application.waterings')
      plant = @watering&.plant || @plant
      title = action.in?(%w[show edit water quick_water]) && plant ? plant.to_s : section_title
      graphic = action.in?(%w[show edit new water quick_water]) ? plant&.graphic_path : nil
      { icon: 'water_icon.png', title: title, section_title: section_title, gradient_class: 'header-waterings', nav_path: waterings_path, plant_graphic: nil, sidebar_graphic: graphic }
    when 'recipes'
      section_title = t('layouts.application.waterings')
      title = action.in?(%w[show edit]) && @recipe ? @recipe.to_s : section_title
      { icon: 'water_icon.png', title: title, section_title: section_title, gradient_class: 'header-waterings', nav_path: recipes_path, plant_graphic: nil }
    when 'recipe_batches'
      section_title = t('layouts.application.waterings')
      title = action.in?(%w[show edit]) && @recipe_batch ? @recipe_batch.to_s : section_title
      { icon: 'water_icon.png', title: title, section_title: section_title, gradient_class: 'header-waterings', nav_path: recipe_batches_path, plant_graphic: nil }
    when 'recipe_sources'
      section_title = t('layouts.application.waterings')
      title = action.in?(%w[show edit]) && @recipe_source ? @recipe_source.to_s : section_title
      { icon: 'water_icon.png', title: title, section_title: section_title, gradient_class: 'header-waterings', nav_path: recipe_sources_path, plant_graphic: nil }
    when 'tanks', 'water_tests', 'water_changes', 'feeding_instructions', 'equipment', 'maintenance_logs'
      section_title = t('layouts.application.tanks')
      title = action == 'show' && controller == 'tanks' && @tank ? @tank.to_s : section_title
      { icon: 'tank_icon.png', title: title, section_title: section_title, gradient_class: 'header-tanks', nav_path: tanks_path, plant_graphic: nil }
    when 'locations'
      section_title = t('layouts.application.locations')
      title = action.in?(%w[show edit]) && @location ? @location.to_s : section_title
      { icon: 'location_icon.png', title: title, section_title: section_title, gradient_class: 'header-locations', nav_path: locations_path, plant_graphic: nil }
    when 'zones'
      section_title = t('layouts.application.locations')
      title = action.in?(%w[show edit]) && @zone ? @zone.to_s : section_title
      { icon: 'location_icon.png', title: title, section_title: section_title, gradient_class: 'header-locations', nav_path: zones_path, plant_graphic: nil }
    when 'sensors', 'sensor_readings', 'sensor_types'
      section_title = t('layouts.application.sensors')
      title = action.in?(%w[show edit]) && controller == 'sensors' && @sensor ? @sensor.to_s : section_title
      { icon: 'sensor_icon.png', title: title, section_title: section_title, gradient_class: 'header-sensors', nav_path: sensors_path, plant_graphic: nil }
    when 'users'
      section_title = t('layouts.application.users')
      { icon: 'users_icon.png', title: section_title, section_title: section_title, gradient_class: 'header-users', nav_path: users_path, plant_graphic: nil }
    when 'admin/notifications'
      { icon: 'settings_icon.png', title: 'Notifications', section_title: 'Notifications', gradient_class: 'header-admin', nav_path: admin_notifications_path, plant_graphic: nil }
    when 'weather'
      section_title = 'Weather'
      { icon: 'autofauna_icon.png', title: section_title, section_title: section_title, gradient_class: 'header-weather', nav_path: weather_path, plant_graphic: nil }
    when 'settings'
      section_title = t('layouts.application.account_settings')
      { icon: 'settings_icon.png', title: section_title, section_title: section_title, gradient_class: 'header-settings', nav_path: settings_path, plant_graphic: nil }
    when 'projects'
      section_title = t('layouts.application.project_settings')
      { icon: 'project_icon.png', title: section_title, section_title: section_title, gradient_class: 'header-settings', nav_path: projects_path, plant_graphic: nil }
    else
      { icon: 'autofauna_icon.png', title: 'Autofauna', section_title: 'Autofauna', gradient_class: 'header-default', nav_path: plants_path, plant_graphic: nil }
    end
  end

  def mobile_device?
    user_agent = request.user_agent.to_s.downcase
    user_agent.match?(/mobile|android|iphone|ipad|ipod|blackberry|iemobile|opera mini/)
  end
end
