class LogEntry < ApplicationRecord
  belongs_to :loggable, polymorphic: true
  belongs_to :user
end
