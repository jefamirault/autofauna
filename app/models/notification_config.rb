class NotificationConfig < ApplicationRecord
  DEFAULT_EMAIL_BODY = <<~HTML
    <h2>Your plants need watering!</h2>

    <p>Hi {{user_email}},</p>

    <p>The following plants are due for watering:</p>

    {{plant_list}}

    <p><a href="{{app_url}}">Open Autofauna</a></p>
  HTML

  validates :cron_expression, presence: true
  validates :email_subject_template, presence: true
  validates :push_title_template, presence: true
  validates :push_body_template, presence: true

  after_save :update_cron_job, if: :saved_change_to_cron_expression?

  def self.instance
    first || create!(email_body_template: DEFAULT_EMAIL_BODY.strip)
  end

  def render_email_subject(count:)
    email_subject_template
      .gsub("{{count}}", count.to_s)
  end

  def render_email_body(user:, plants:)
    plant_list_html = "<ul>" + plants.map { |plant|
      li = "<li><a href=\"#{Rails.application.routes.url_helpers.plant_url(plant, host: default_host)}\">#{ERB::Util.html_escape(plant.label)}</a>"
      if plant.date_last_watering
        li += " &mdash; last watered #{plant.date_last_watering.strftime('%b %d')}"
      end
      li + "</li>"
    }.join("\n") + "</ul>"

    email_body_template
      .gsub("{{user_email}}", ERB::Util.html_escape(user.email))
      .gsub("{{plant_list}}", plant_list_html)
      .gsub("{{app_url}}", Rails.application.routes.url_helpers.root_url(host: default_host))
      .gsub("{{count}}", plants.size.to_s)
  end

  def render_push_title(plant:)
    push_title_template
      .gsub("{{plant_name}}", plant.name)
      .gsub("{{plant_label}}", plant.label)
  end

  def render_push_body(plant:)
    push_body_template
      .gsub("{{plant_name}}", plant.name)
      .gsub("{{plant_label}}", plant.label)
  end

  private

  def default_host
    Rails.application.config.action_mailer.default_url_options&.fetch(:host, "localhost:3000")
  end

  def update_cron_job
    Sidekiq::Cron::Job.create(
      name: "plant_notifications",
      cron: cron_expression,
      class: "PlantNotificationJob",
      active_job: true
    )
  end
end
