# Be sure to restart your server when you modify this file.

# Content Security Policy — baseline backstop against XSS in user-generated
# content (plant names/notes, sensor payloads).
#
# Currently REPORT-ONLY (issue #108): violations are logged by the browser
# console / Report-To but nothing is blocked. Before flipping to enforcing,
# watch for violations during normal use — the known remaining offenders are
# inline event handlers (`onclick:`/`onchange:` in views), which report as
# script-src violations and need migrating to Stimulus actions first.
# To enforce: remove the `content_security_policy_report_only` line below.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self, "https://accounts.google.com" # Google Sign-In (GSI) client
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com", "https://accounts.google.com"
    policy.font_src    :self, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, :blob
    policy.connect_src :self, "https://accounts.google.com"
    policy.frame_src   "https://accounts.google.com" # GSI button renders in an iframe
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self
  end

  # Nonces for inline scripts (importmap JSON, layout bootstrap scripts). Not
  # applied to style-src: a style nonce would make browsers ignore
  # 'unsafe-inline', breaking the style="" attributes used across views.
  config.content_security_policy_nonce_generator = ->(request) do
    request.session.id.to_s.presence || SecureRandom.base64(16)
  end
  config.content_security_policy_nonce_directives = %w(script-src)

  # Report violations without enforcing the policy (rollout phase).
  config.content_security_policy_report_only = true
end
