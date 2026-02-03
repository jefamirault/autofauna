class User < ApplicationRecord
  has_secure_password validations: false

  has_many :collaborations, dependent: :destroy
  has_many :projects, foreign_key: :owner_id, dependent: :destroy

  after_create :create_default_project

  validates :password, presence: true, length: { minimum: 6 }, if: -> { !guest? && (new_record? || password_digest_changed?) }
  validates :email, presence: true, unless: :guest?
  normalizes :email, with: -> { _1.strip.downcase }
  validates :email, uniqueness: true, allow_blank: true

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email
  end

  def convert_from_guest!(email:, password:, password_confirmation:)
    raise "Not a guest account" unless guest?

    self.guest = false
    self.email = email
    self.password = password
    self.password_confirmation = password_confirmation
    save!
  end

  def convert_from_guest_google!(email:, google_uid:, avatar_url: nil)
    raise "Not a guest account" unless guest?

    self.guest = false
    self.email = email
    self.google_uid = google_uid
    self.avatar_url = avatar_url
    self.password = SecureRandom.hex(32)
    save!
  end

  def to_s
    self.email || "Guest"
  end

  private

  def create_default_project
    projects.create(name: "My Plants")
  end
end
