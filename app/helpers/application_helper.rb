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
    "<a class='#{default_class}#{selected ? ' selected' : ''}'>#{name}</a>".html_safe
  end

  def nav_link(controller, options = {})
    default_class = 'navItem'
    text = options[:text] || t(".#{controller}")
    action = options[:action] || 'index'
    path = options[:path] || send("#{controller}_path")
    if params[:controller] == controller
        if params[:action] == action
          nav_item(text, true)
        else
          link_to(text, path, class: default_class)
        end
    else
      link_to(text, path, class: default_class)
    end
  end

  def header_config
    controller = params[:controller]
    action = params[:action]

    case controller
    when 'plants', 'log_entries'
      { icon: 'autofauna_icon.png', title: (action == 'show' && @plant ? @plant.to_s : t('layouts.application.plants')), gradient_class: 'header-plants' }
    when 'waterings', 'recipes', 'recipe_batches', 'recipe_sources'
      { icon: 'water_icon.png', title: t('layouts.application.waterings'), gradient_class: 'header-waterings' }
    when 'tanks', 'water_tests'
      { icon: 'tank_icon.png', title: (action == 'show' && controller == 'tanks' && @tank ? @tank.to_s : t('layouts.application.tanks')), gradient_class: 'header-tanks' }
    when 'locations', 'zones'
      { icon: 'location_icon.png', title: t('layouts.application.locations'), gradient_class: 'header-locations' }
    when 'sensors', 'sensor_readings', 'sensor_types'
      { icon: 'sensor_icon.png', title: t('layouts.application.sensors'), gradient_class: 'header-sensors' }
    when 'users'
      { icon: 'users_icon.png', title: t('layouts.application.users'), gradient_class: 'header-users' }
    when 'settings'
      { icon: 'settings_icon.png', title: t('layouts.application.account_settings'), gradient_class: 'header-settings' }
    when 'projects'
      { icon: 'project_icon.png', title: t('layouts.application.project_settings'), gradient_class: 'header-settings' }
    else
      { icon: 'autofauna_icon.png', title: 'Autofauna', gradient_class: 'header-default' }
    end
  end

  def mobile_device?
    user_agent = request.user_agent.to_s.downcase
    user_agent.match?(/mobile|android|iphone|ipad|ipod|blackberry|iemobile|opera mini/)
  end
end
