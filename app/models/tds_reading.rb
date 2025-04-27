class TdsReading < ApplicationRecord
  belongs_to :tank
  validates_presence_of :tds
end
