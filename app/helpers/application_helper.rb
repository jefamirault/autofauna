module ApplicationHelper
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
      text = if date == Time.zone.now.to_date
               if options[:precise]
                 time_ago_in_words date
                 byebug
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
    "<div class='navItem#{selected ? ' selected' : ''}'>#{name}</div>".html_safe
  end

  def nav_link(controller, options = {})

    text = t(".#{options[:text] || controller}")
    action = options[:action] || 'index'
    path = options[:path] || send("#{controller}_path")
    if params[:controller] == controller && params[:action] == action
      nav_item(text, true)
    else
      link_to(text, path, class: 'navItem')
    end
  end
end
