class DeleteUserDataJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    user.destroy
  rescue ActiveRecord::RecordNotFound
    # User already deleted
  end
end
