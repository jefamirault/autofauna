module ApplicationHelper
  def format_date(date, options = {})
    if options[:time]
      date ? date.strftime('%A %-m/%-d/%y %r') : ""
    else
      date ? date.strftime('%a %-m/%-d/%y') : ""
    end
  end

  def time_ago(date, options = {})
    if date.nil?
      nil
    else
      text = if date.today?
               if options[:precise]
                 time_ago_in_words date
               else
                 'Today'
               end
             else
               days_ago = (Date.today - date.to_date).to_i
               "#{days_ago} days ago"
             end

      options[:parentheses] ? "(#{text})" : text
    end
  end
end
