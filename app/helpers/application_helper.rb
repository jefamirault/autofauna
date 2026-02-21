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
      icon = action.in?(%w[show edit]) && @plant&.graphic_path ? @plant.graphic_path : 'autofauna_icon.png'
      title = action.in?(%w[show edit]) && @plant ? @plant.to_s : t('layouts.application.plants')
      { icon: icon, title: title, gradient_class: 'header-plants header-graphic' }
    when 'waterings'
      icon = action.in?(%w[show edit]) && @watering&.plant&.graphic_path ? @watering.plant.graphic_path : 'water_icon.png'
      { icon: icon, title: t('layouts.application.waterings'), gradient_class: 'header-waterings header-graphic' }
    when 'recipes'
      title = action.in?(%w[show edit]) && @recipe ? @recipe.to_s : t('layouts.application.waterings')
      { icon: 'water_icon.png', title: title, gradient_class: 'header-waterings header-graphic' }
    when 'recipe_batches'
      title = action.in?(%w[show edit]) && @recipe_batch ? @recipe_batch.to_s : t('layouts.application.waterings')
      { icon: 'water_icon.png', title: title, gradient_class: 'header-waterings header-graphic' }
    when 'recipe_sources'
      title = action.in?(%w[show edit]) && @recipe_source ? @recipe_source.to_s : t('layouts.application.waterings')
      { icon: 'water_icon.png', title: title, gradient_class: 'header-waterings header-graphic' }
    when 'tanks', 'water_tests'
      { icon: 'tank_icon.png', title: (action == 'show' && controller == 'tanks' && @tank ? @tank.to_s : t('layouts.application.tanks')), gradient_class: 'header-tanks header-graphic' }
    when 'locations'
      title = action.in?(%w[show edit]) && @location ? @location.to_s : t('layouts.application.locations')
      { icon: 'location_icon.png', title: title, gradient_class: 'header-locations header-graphic' }
    when 'zones'
      title = action.in?(%w[show edit]) && @zone ? @zone.to_s : t('layouts.application.locations')
      { icon: 'location_icon.png', title: title, gradient_class: 'header-locations header-graphic' }
    when 'sensors', 'sensor_readings', 'sensor_types'
      title = action.in?(%w[show edit]) && controller == 'sensors' && @sensor ? @sensor.to_s : t('layouts.application.sensors')
      { icon: 'sensor_icon.png', title: title, gradient_class: 'header-sensors header-graphic' }
    when 'users'
      { icon: 'users_icon.png', title: t('layouts.application.users'), gradient_class: 'header-users header-graphic' }
    when 'settings'
      { icon: 'settings_icon.png', title: t('layouts.application.account_settings'), gradient_class: 'header-settings header-graphic' }
    when 'projects'
      { icon: 'project_icon.png', title: t('layouts.application.project_settings'), gradient_class: 'header-settings header-graphic' }
    else
      { icon: 'autofauna_icon.png', title: 'Autofauna', gradient_class: 'header-default header-graphic' }
    end
  end

  def mobile_device?
    user_agent = request.user_agent.to_s.downcase
    user_agent.match?(/mobile|android|iphone|ipad|ipod|blackberry|iemobile|opera mini/)
  end
end
