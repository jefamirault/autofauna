# Agent Log

Current session log. Previous logs archived in `agent_log/`.

---

## 2026-02-09: Migrate from Solid Queue to Sidekiq + Redis

**Goal:** Replace Solid Queue with Sidekiq + Redis for background job processing, maintaining existing notification functionality.

**Plan:**
1. Update Gemfile (remove solid_queue, add sidekiq + sidekiq-cron)
2. Update production.rb (change job adapter to sidekiq)
3. Create Sidekiq configuration files (sidekiq.yml, initializers/sidekiq.rb, schedule.yml)
4. Remove Solid Queue-specific files (recurring.yml, queue.yml, queue_schema.rb, bin/jobs)
5. Update puma.rb (remove solid_queue plugin)

**Status:** Complete

**Changes Made:**
1. **Gemfile**: Removed `solid_queue`, added `sidekiq ~> 7.0` and `sidekiq-cron ~> 1.12`
2. **config/environments/production.rb**: Changed `queue_adapter` from `:solid_queue` to `:sidekiq`, removed `solid_queue.connects_to` config
3. **config/puma.rb**: Removed Solid Queue plugin
4. **config/sidekiq.yml** (new): Created Sidekiq worker configuration with concurrency settings per environment
5. **config/initializers/sidekiq.rb** (new): Created Redis configuration and sidekiq-cron schedule loader
6. **config/schedule.yml** (new): Created cron schedule for PlantNotificationJob (hourly at minute 0)
7. **Removed files**:
   - config/recurring.yml
   - config/queue.yml
   - db/queue_schema.rb
   - bin/jobs
8. **.gitignore**: Added `dump.rdb` for Redis dump files

**Next Steps for User:**
1. Run `bundle install` to install Sidekiq gems
2. Ensure Redis is installed and running (development: `redis-server`, production: systemd service)
3. Start Sidekiq in development: `bundle exec sidekiq`
4. Set `REDIS_URL` environment variable in production (e.g., in `.rbenv-vars`)
5. Set up systemd service for Sidekiq on production server (see plan for service file template)
6. Test notification job manually: `bin/rails runner "PlantNotificationJob.perform_now"`
7. Verify cron schedule in Rails console: `Sidekiq::Cron::Job.all`

**Optional:** Add Sidekiq Web UI to routes.rb for monitoring (requires authentication in production)

---

## 2026-02-09: Add Test Buttons for Email and Push Notifications

**Goal:** Allow users to test their notification settings by sending sample email and push notifications on demand from the Account Settings page.

**Changes Made:**
1. **app/controllers/settings_controller.rb**: Added two new actions:
   - `send_test_email`: Sends test email with up to 3 plants as examples (requires at least 1 plant)
   - `send_test_push`: Sends test push notification to all registered browser subscriptions (requires at least 1 active subscription)
   - Both actions handle edge cases (no plants, no subscriptions, delivery failures) with appropriate flash messages

2. **config/routes.rb**: Added POST routes for test actions:
   - `POST /settings/send_test_email` → `settings#send_test_email`
   - `POST /settings/send_test_push` → `settings#send_test_push`

3. **app/views/settings/index.html.erb**: Added "Test Notifications" section with:
   - "Send Test Email" button (disabled if no plants, with helper text)
   - "Send Test Push Notification" button (disabled if no push subscriptions, with helper text)
   - SVG icons (envelope for email, bell for push)
   - Loading state with `disable_with: "Sending..."` to prevent double-clicks
   - Tailwind CSS styling for consistent appearance

**Testing:**
- Email test: Queues test email via Sidekiq using `PlantNotificationMailer.watering_reminder`
- Push test: Sends synchronously to all active subscriptions with graceful error handling
- Both respect user's current settings (email address, active subscriptions)

**User Verification Steps:**
1. Navigate to Account Settings (`/settings`)
2. Test email: Click "Send Test Email" (requires at least 1 plant in account)
3. Test push: Enable push notifications, then click "Send Test Push Notification"
4. Check email inbox and browser notifications for test messages

---

## 2026-02-09: Fix Push Notification Permission Request

**Goal:** Fix the bug where clicking "Enable push notifications" does not trigger the browser permission prompt, preventing users from subscribing to push notifications.

**Problem:** The `subscribe()` method in `push_notifications.js` attempted to create a push subscription without first requesting browser notification permission via `Notification.requestPermission()`. This caused the browser to silently fail or deny the subscription without showing the permission prompt to users.

**Solution:** Modified the `subscribe()` method to:
1. First call `Notification.requestPermission()` to trigger the browser permission prompt
2. Check if permission was granted before proceeding
3. Throw a clear error if permission is denied (caught by existing error handling)

**Changes Made:**
1. **app/javascript/push_notifications.js** (lines 15-24): Updated `subscribe()` method to:
   - Request notification permission before attempting subscription
   - Only proceed with push subscription if permission is granted
   - Provide clear error message if user denies permission

**Important:** After implementing this fix, the Rails server must be restarted for the JavaScript changes to take effect. The importmap needs to reload the modified push_notifications.js file.

**Testing Results:**
- Permission prompt now appears correctly when clicking "Enable push notifications"
- Subscriptions are successfully created and saved to database
- Test push notifications are delivered to browser successfully
- Error handling works correctly for permission denial

**Note:** The `web-push` gem was already in the Gemfile but the server restart was required for both the JavaScript changes and to ensure the gem was properly loaded.

---

## 2026-02-09: Production Deployment Checklist for Notifications

**Goal:** Create comprehensive documentation for deploying email and push notification functionality to production.

**Changes Made:**
1. **PRODUCTION_NOTIFICATIONS_CHECKLIST.md** (new): Created detailed step-by-step checklist covering:
   - Redis installation and configuration
   - Environment variables setup (REDIS_URL, Mailgun SMTP, RAILS_MASTER_KEY)
   - VAPID keys verification in Rails credentials
   - Code deployment via Capistrano
   - Sidekiq systemd service creation and configuration
   - Testing procedures (email, push, cron jobs)
   - Monitoring and troubleshooting commands
   - Rollback plan
   - Success criteria

**Key Requirements for Production:**
- Redis server installed and running
- Sidekiq systemd service configured for background job processing
- Environment variables in `/home/deploy/autofauna/.rbenv-vars`: REDIS_URL, MAILGUN_SMTP_USERNAME, MAILGUN_SMTP_PASSWORD
- RAILS_MASTER_KEY must match local master.key (for decrypting VAPID keys)
- HTTPS enabled (required for service workers and push notifications)
- Service worker deployed to `public/service-worker.js`

**Testing Checklist:**
1. Redis connection test
2. Email test notification from settings page
3. Push notification permission prompt and test notification
4. Hourly cron job execution (PlantNotificationJob)
5. Multi-device push notification delivery
6. Sidekiq queue monitoring

**Location:** `/home/jef/autofauna/PRODUCTION_NOTIFICATIONS_CHECKLIST.md`

