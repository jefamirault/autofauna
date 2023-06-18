module ApplicationHelper
  def format_date(date)
    # date ? date.strftime('%A %-m/%-d/%y') : ""
    date ? date.strftime('%a %-m/%-d/%y') : ""
  end

  def time_ago(date, options = {})
    if date.nil?
      nil
    else
      text = if date.today?
               'Today'
             else
               days_ago = (Date.today - date).to_i
               "#{days_ago} days ago"
             end

      options[:parentheses] ? "(#{text})" : text
    end
  end
end
