class User < ApplicationRecord
  has_secure_password

  has_many :collaborations, dependent: :destroy
  has_many :projects, foreign_key: :owner_id, dependent: :destroy

  after_create :create_default_project

  validates :email, presence: true
  normalizes :email, with: -> { _1.strip.downcase }
  validates :email, uniqueness: true

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email
  end

  def to_s
    self.email
  end

  private

  def create_default_project
    projects.create(name: "My Plants")
  end
end
