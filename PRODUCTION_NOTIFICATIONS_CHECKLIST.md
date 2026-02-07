# Production Deployment Checklist: Email + Push Notifications

## Prerequisites

### 1. Redis Installation
```bash
# On production server (Ubuntu/Debian)
sudo apt update
sudo apt install redis-server

# Start and enable Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verify Redis is running
redis-cli ping  # Should return "PONG"
```

### 2. Verify Ruby & Dependencies
```bash
cd /home/deploy/autofauna
bundle install  # Install new gems (sidekiq, sidekiq-cron, web-push)
```

## Environment Variables

### 3. Update `.rbenv-vars` on Production Server
Edit `/home/deploy/autofauna/.rbenv-vars` and ensure these variables are set:

```bash
# Existing
RAILS_MASTER_KEY=<your_master_key>

# Redis (local or remote URL)
REDIS_URL=redis://localhost:6379/0

# Mailgun SMTP (for email notifications)
MAILGUN_SMTP_USERNAME=<your_mailgun_username>
MAILGUN_SMTP_PASSWORD=<your_mailgun_api_key>
```

**Notes:**
- If Redis is on a separate server, use full URL: `redis://username:password@host:port/db`
- Mailgun credentials should already be configured from previous email setup
- RAILS_MASTER_KEY must match your local `config/master.key` (needed to decrypt credentials including VAPID keys)

### 4. Verify Rails Credentials (VAPID Keys)
Run locally to confirm web push keys are in credentials:
```bash
cd /home/jef/autofauna
bin/rails credentials:show
```

Should include:
```yaml
web_push:
  public_key: <vapid_public_key>
  private_key: <vapid_private_key>
```

**If missing:** Generate VAPID keys and add them:
```bash
# Generate keys
bundle exec rake webpush:generate_key

# Edit credentials
EDITOR=nano bin/rails credentials:edit

# Add the web_push section, save, and update RAILS_MASTER_KEY on server
```

## Code Deployment

### 5. Deploy Application
```bash
# From your local machine
cd /home/jef/autofauna
cap production deploy
```

This will:
- Push latest code to production
- Run `bundle install`
- Precompile assets (including service-worker.js)
- Restart Puma

**Important:** Verify that `public/service-worker.js` is deployed and accessible at `https://autofauna.org/service-worker.js`

## Sidekiq Setup

### 6. Create Sidekiq Systemd Service
SSH into production server and create service file:

```bash
# On production server
sudo nano /etc/systemd/system/sidekiq.service
```

Add this configuration:
```ini
[Unit]
Description=Sidekiq Background Worker for Autofauna
After=network.target redis-server.service

[Service]
Type=simple
User=deploy
WorkingDirectory=/home/deploy/autofauna
Environment=RAILS_ENV=production
Environment=RBENV_ROOT=/home/deploy/.rbenv
Environment=RBENV_VERSION=3.2.2

# Load environment variables from .rbenv-vars
ExecStart=/bin/bash -lc 'cd /home/deploy/autofauna && bundle exec sidekiq -C config/sidekiq.yml'
ExecReload=/bin/kill -TSTP $MAINPID

# Restart on failure
Restart=on-failure
RestartSec=10

# Logging
StandardOutput=append:/home/deploy/autofauna/log/sidekiq.log
StandardError=append:/home/deploy/autofauna/log/sidekiq_error.log

# Graceful shutdown
TimeoutStopSec=30
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

### 7. Enable and Start Sidekiq
```bash
# Reload systemd to recognize new service
sudo systemctl daemon-reload

# Enable Sidekiq to start on boot
sudo systemctl enable sidekiq

# Start Sidekiq
sudo systemctl start sidekiq

# Check status
sudo systemctl status sidekiq

# View logs
tail -f /home/deploy/autofauna/log/sidekiq.log
```

### 8. Verify Sidekiq Cron Schedule
```bash
# On production server
cd /home/deploy/autofauna
RAILS_ENV=production bundle exec rails runner "puts Sidekiq::Cron::Job.all.map(&:name)"
```

Should output: `plant_notifications`

To see full cron details:
```bash
RAILS_ENV=production bundle exec rails runner "Sidekiq::Cron::Job.all.each { |job| puts job.inspect }"
```

## Testing

### 9. Test Background Jobs (via Rails Console)
```bash
cd /home/deploy/autofauna
RAILS_ENV=production bundle exec rails console
```

In console:
```ruby
# Check Redis connection
Sidekiq.redis { |conn| conn.ping }  # Should return "PONG"

# Queue a test job
PlantNotificationJob.perform_later

# Check Sidekiq queues
Sidekiq::Queue.new.size
```

### 10. Test Email Notifications
1. Log into production app: https://autofauna.org
2. Navigate to Account Settings: https://autofauna.org/settings
3. Ensure email notifications are enabled
4. Click "Send Test Email" button
5. Check inbox for test email

**Verify:**
- Email arrives within 1-2 minutes
- Check Sidekiq logs: `tail -f log/sidekiq.log`
- Check Rails logs: `tail -f log/production.log`

### 11. Test Push Notifications

#### From Desktop Browser:
1. Navigate to https://autofauna.org/settings
2. Click "Enable push notifications"
3. Browser shows permission prompt → Click "Allow"
4. Button changes to "Disable push notifications"
5. Click "Send Test Push Notification"
6. Browser notification should appear immediately

#### From Mobile Browser:
1. Open https://autofauna.org/settings on phone
2. Enable push notifications (grant permission)
3. Send test notification
4. Notification should appear in phone's notification tray

**Troubleshooting:**
- If no permission prompt appears → Clear browser cache, check HTTPS is working
- If "uninitialized constant WebPush" error → Run `bundle install` and restart Puma
- Check browser console for JavaScript errors
- Verify service worker is registered: Open DevTools → Application → Service Workers

### 12. Test Automatic Hourly Notifications
Wait for the top of the hour (or trigger manually):

```bash
# Trigger cron job manually
RAILS_ENV=production bundle exec rails runner "PlantNotificationJob.perform_now"
```

**Verify:**
- Users with plants due for watering receive email and/or push notifications
- Check logs for any errors
- Verify notification preferences are respected (users can disable email/push individually)

## Monitoring

### 13. Set Up Monitoring (Optional but Recommended)

#### View Sidekiq Queue Stats:
```bash
cd /home/deploy/autofauna
RAILS_ENV=production bundle exec rails runner "
  puts 'Enqueued: ' + Sidekiq::Queue.new.size.to_s
  puts 'Processed: ' + Sidekiq::Stats.new.processed.to_s
  puts 'Failed: ' + Sidekiq::Stats.new.failed.to_s
"
```

#### Enable Sidekiq Web UI (Optional):
Add to `config/routes.rb`:
```ruby
require 'sidekiq/web'

# Protect Sidekiq Web UI in production
if Rails.env.production?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, ENV['SIDEKIQ_USERNAME']) &&
      ActiveSupport::SecurityUtils.secure_compare(password, ENV['SIDEKIQ_PASSWORD'])
  end
end

mount Sidekiq::Web => '/sidekiq'
```

Then access at: https://autofauna.org/sidekiq

## Common Issues

### Sidekiq won't start:
```bash
# Check logs
sudo journalctl -u sidekiq -n 50 --no-pager

# Verify Redis connection
redis-cli ping

# Check environment variables
cat /home/deploy/autofauna/.rbenv-vars
```

### Push notifications not working:
- Verify HTTPS is enabled (required for service workers)
- Check VAPID keys in credentials match between local and production
- Verify `public/service-worker.js` is accessible
- Check browser console for errors
- Ensure RAILS_MASTER_KEY on server matches your local master.key

### Email notifications not sending:
- Verify MAILGUN_SMTP_USERNAME and MAILGUN_SMTP_PASSWORD are set
- Check Sidekiq is processing jobs: `systemctl status sidekiq`
- Check Mailgun dashboard for delivery logs
- Review Sidekiq logs: `tail -f log/sidekiq.log`

### Cron jobs not running:
```bash
# Verify cron schedule is loaded
RAILS_ENV=production bundle exec rails runner "puts Sidekiq::Cron::Job.count"

# Should return 1 (plant_notifications job)

# Reload cron schedule if needed
RAILS_ENV=production bundle exec rails runner "Sidekiq::Cron::Job.load_from_hash YAML.load_file('config/schedule.yml')"
```

## Useful Commands

```bash
# Restart Sidekiq
sudo systemctl restart sidekiq

# View Sidekiq logs in real-time
tail -f /home/deploy/autofauna/log/sidekiq.log

# View Rails production logs
tail -f /home/deploy/autofauna/log/production.log

# Clear failed jobs
RAILS_ENV=production bundle exec rails runner "Sidekiq::RetrySet.new.clear; Sidekiq::DeadSet.new.clear"

# List all push subscriptions
RAILS_ENV=production bundle exec rails runner "puts PushSubscription.count"

# Test notification for specific user
RAILS_ENV=production bundle exec rails runner "user = User.find(1); PlantNotificationJob.perform_now"
```

## Rollback Plan

If notifications aren't working and you need to rollback:

1. **Stop Sidekiq:** `sudo systemctl stop sidekiq`
2. **Rollback deployment:** `cap production deploy:rollback`
3. **Restart Puma:** The rollback should handle this automatically
4. **Investigate logs before trying again**

## Success Criteria

- ✅ Redis is running and accessible
- ✅ Sidekiq service is running (`systemctl status sidekiq`)
- ✅ Hourly cron job is scheduled and executing
- ✅ Test email sends successfully from settings page
- ✅ Test push notification sends successfully from settings page
- ✅ Service worker is registered in browser (check DevTools)
- ✅ Users receive automatic notifications at configured times
- ✅ No errors in Sidekiq or Rails logs

---

**Last Updated:** 2026-02-09
