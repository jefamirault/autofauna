class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true

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
