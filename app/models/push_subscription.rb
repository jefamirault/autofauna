class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true

  scope :enabled, -> { where(enabled: true) }

  def device_name
    return "Unknown device" if user_agent.blank?

    browser = case user_agent
              when /Edg/i then "Edge"
              when /OPR|Opera/i then "Opera"
              when /Chrome/i then "Chrome"
              when /Safari/i then "Safari"
              when /Firefox/i then "Firefox"
              else "Browser"
              end

    os = case user_agent
         when /iPhone|iPad/i then "iOS"
         when /Android/i then "Android"
         when /Windows/i then "Windows"
         when /Macintosh|Mac OS/i then "macOS"
         when /Linux/i then "Linux"
         when /CrOS/i then "ChromeOS"
         else nil
         end

    os ? "#{browser} on #{os}" : browser
  end

  def send_notification(title:, body:, url: nil)
    payload = { title: title, body: body, url: url }.compact.to_json

    WebPush.payload_send(
      message: payload,
      endpoint: endpoint,
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: {
        subject: "mailto:support@autofauna.org",
        public_key: Rails.application.credentials.dig(:web_push, :public_key),
        private_key: Rails.application.credentials.dig(:web_push, :private_key)
      }
    )
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    destroy
  end
end
