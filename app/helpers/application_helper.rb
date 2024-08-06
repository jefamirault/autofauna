module ApplicationHelper
  def format_date(date, options = {})
    if options[:time]
      date ? date.strftime('%A %-m/%-d/%y %r') : ""
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
               else
                 'Today'
               end
             else
               days_ago = (Time.zone.now.to_date - date.to_date).to_i
               if days_ago == 1
                 'Yesterday'
               else
                 "#{days_ago} days ago"
               end
             end

      options[:parentheses] ? "(#{text})" : text
    end
  end
end
