class SavedSearch < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :name, presence: true, length: { maximum: 50 }
  validates :query_term, presence: true
end
