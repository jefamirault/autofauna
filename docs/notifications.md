# Notifications (Email + Web Push)

## Channels

- **Email:** `PlantNotificationMailer` sends watering reminders via Mailgun SMTP.
- **Push:** Web Push via the `web-push` gem + Service Worker (`public/service-worker.js`).
- **VAPID keys:** stored in Rails credentials.
- **Test buttons:** the Settings page has "Send Test Email" and "Send Test Push Notification".
- **Sending job:** `PlantNotificationJob` runs hourly (sidekiq-cron). See `docs/background-jobs.md`.

## Push subscriptions

- `PushSubscription` model has an `enabled` boolean. Browser permission is requested on enable.
- **Per-device control:** each subscription can be individually disabled/enabled via an inline
  toggle (no page reload). "Forget" deletes the record entirely.
- **Notification sending uses the `PushSubscription.enabled` scope** — disabled devices don't
  receive notifications.

**Global ↔ device sync** (bidirectional, `push_notification_controller` +
`notification_settings_controller`):
- Enabling the global toggle auto-enables the current device if all are disabled.
- Disabling the global toggle disables all devices.
- Disabling the last device auto-unchecks the global toggle (without collapsing the card).
- Enabling any device auto-checks the global toggle.

**Test button states:** "Send Test Push" is disabled (gray) when no enabled devices; "Send Test
Email" is disabled when the email toggle is off.

## Gotchas

- **Dual state (browser vs server):** browser push subscriptions and server `PushSubscription`
  records are independent. The `enabled` flag soft-disables without deleting; "Forget" deletes.
  If the browser is subscribed but no server record exists, the JS auto-re-registers. If a
  **disabled** record exists for the endpoint, it does NOT re-register (the endpoint still matches).
- **"Forget" button visibility:** only shown when the device is disabled; never for the current
  device (CSS `!important` rule on `.current-device .push-device-forget-wrap`).
- **Cross-controller communication:** `notification-settings` dispatches
  `notification-enabled` / `notification-disabled` custom events on the `push-notification`
  controller element; the push controller listens in `connect()`. A `_suppressHeaderSync` flag
  prevents feedback loops when the global toggle triggers bulk device changes.
- **Card collapse:** `notification-settings` collapses card bodies to `height: 0; overflow: hidden`.
  Stimulus controllers inside still connect and can inject DOM, but content is invisible until the
  toggle expands the body. Don't remove visible fallback UI (like subscribe buttons) without
  ensuring the JS replacement works in both collapsed and expanded states.
- **`button_to` form ordering:** the push card has `button_to "Forget"` forms before the
  frequency-settings form, so `querySelector("form")` returns the wrong one. Query the specific
  input on `this.element` (e.g. `this.element.querySelector('input[type="time"]')`) or use Stimulus
  targets. See `app/javascript/controllers/CLAUDE.md`.
