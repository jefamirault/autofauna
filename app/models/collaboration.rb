class Collaboration < ApplicationRecord
  belongs_to :user
  belongs_to :project

  # Prohibit a user from having more than one role per project
  validates :user_id, uniqueness: { scope: :project_id }

  enum :role, [ :viewer, :editor ]
end