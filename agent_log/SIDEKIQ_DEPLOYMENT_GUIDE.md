# Sidekiq Deployment Guide

## What Was Changed

The following changes have been made to enable automated Sidekiq worker management via Capistrano:

1. **Gemfile**: Added `capistrano-sidekiq ~> 2.3`
2. **Capfile**: Added `require "capistrano/sidekiq"`
3. **config/deploy.rb**:
   - Added `config/sidekiq.yml` to linked files
   - Configured Sidekiq deployment settings

## Prerequisites (Production Server)

Before deploying, verify these are in place on the production server:

### 1. Redis Server

```bash
# SSH to production
ssh deploy@159.223.100.164

# Check if Redis is running
redis-cli ping
# Should return: PONG

# If not installed:
sudo apt update
sudo apt install redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

### 2. Environment Variables

Ensure `/home/deploy/autofauna/.rbenv-vars` contains:

```bash
REDIS_URL=redis://localhost:6379/0
MAILGUN_SMTP_USERNAME=postmaster@mg.autofauna.org
MAILGUN_SMTP_PASSWORD=<your-mailgun-password>
RAILS_MASTER_KEY=<matches-your-local-master.key>
```

To check:
```bash
ssh deploy@159.223.100.164
cat /home/deploy/autofauna/.rbenv-vars
```

### 3. Sidekiq Config File

The `config/sidekiq.yml` file needs to exist in the shared directory on production:

```bash
# On production server
ssh deploy@159.223.100.164

# Copy sidekiq.yml to shared directory if not already there
mkdir -p /home/deploy/autofauna/shared/config
# You'll need to upload this file during first deployment
```

## Deployment Steps

### Step 1: Install Gems Locally

```bash
cd /home/jef/autofauna
bundle install
```

### Step 2: Commit and Push Changes

```bash
git add Gemfile Gemfile.lock Capfile config/deploy.rb
git commit -m "Add capistrano-sidekiq for automated worker management"
git push origin notifications
```

### Step 3: Deploy to Production

```bash
# Deploy from local machine
cap production deploy
```

**What happens during deployment:**
- Capistrano-sidekiq will automatically create a systemd service file
- The service will be named `sidekiq-autofauna.service`
- Sidekiq will start automatically after deployment
- On future deployments, Sidekiq will restart gracefully

### Step 4: Verify Sidekiq is Running

```bash
# Check service status
cap production sidekiq:status

# Or SSH to server and check directly
ssh deploy@159.223.100.164
sudo systemctl status sidekiq-autofauna
```

You should see output like:
```
● sidekiq-autofauna.service - sidekiq for autofauna (production)
   Loaded: loaded
   Active: active (running)
```

### Step 5: Check Logs

```bash
# View Sidekiq logs on production
ssh deploy@159.223.100.164
tail -f /home/deploy/autofauna/shared/log/sidekiq.log
```

## Testing Email Delivery

After deployment, test the email functionality:

1. Visit https://autofauna.org/settings
2. Click "Send Test Email" button
3. Check the logs:
   ```bash
   # Production logs
   tail -f /home/deploy/autofauna/shared/log/production.log

   # Sidekiq logs
   tail -f /home/deploy/autofauna/shared/log/sidekiq.log
   ```
4. Verify email arrives in inbox

Expected log output:
```
[ActiveJob] Enqueued ActionMailer::MailDeliveryJob
[Sidekiq] PlantNotificationMailer#watering_reminder: start
[Sidekiq] Delivered mail
[Sidekiq] PlantNotificationMailer#watering_reminder: done
```

## Useful Capistrano Commands

```bash
# Start Sidekiq
cap production sidekiq:start

# Stop Sidekiq
cap production sidekiq:stop

# Restart Sidekiq
cap production sidekiq:restart

# Check Sidekiq status
cap production sidekiq:status

# View Sidekiq processes
cap production sidekiq:processes
```

## Troubleshooting

### Sidekiq Won't Start

1. **Check Redis connection:**
   ```bash
   ssh deploy@159.223.100.164
   redis-cli ping
   ```

2. **Check environment variables:**
   ```bash
   cat /home/deploy/autofauna/.rbenv-vars | grep REDIS
   ```

3. **Check systemd service:**
   ```bash
   sudo systemctl status sidekiq-autofauna
   sudo journalctl -u sidekiq-autofauna -n 50
   ```

### Emails Still Not Sending

1. **Verify Sidekiq is processing jobs:**
   ```bash
   # On production server
   cd /home/deploy/autofauna/current
   bundle exec rails console production
   > Sidekiq::Queue.all.map { |q| [q.name, q.size] }
   # Should show empty or decreasing queue sizes
   ```

2. **Check Mailgun credentials:**
   ```bash
   cat /home/deploy/autofauna/.rbenv-vars | grep MAILGUN
   ```

3. **Test Mailgun SMTP directly:**
   ```bash
   # In Rails console on production
   ActionMailer::Base.smtp_settings
   # Verify credentials are loaded correctly
   ```

### View Job Queue in Rails Console

```ruby
# On production server
cd /home/deploy/autofauna/current
bundle exec rails console production

# Check queues
Sidekiq::Queue.all.map { |q| [q.name, q.size] }

# Check scheduled jobs
Sidekiq::ScheduledSet.new.size

# View cron jobs
Sidekiq::Cron::Job.all
```

## Verification Checklist

After deployment, verify:

- [ ] Redis is running: `redis-cli ping` returns PONG
- [ ] Environment variables are set in `.rbenv-vars`
- [ ] Sidekiq service is active: `sudo systemctl status sidekiq-autofauna`
- [ ] Sidekiq logs show worker started
- [ ] Test email sends successfully from settings page
- [ ] Email arrives in inbox
- [ ] Production logs show email delivery
- [ ] Sidekiq queue sizes decrease to zero
- [ ] Hourly cron job appears in Sidekiq::Cron::Job.all

## Next Steps

Once Sidekiq is running:

1. Monitor the hourly plant notification job (should run at minute 0 of each hour)
2. Check that automated watering reminder emails are being sent
3. Set up monitoring/alerting for Sidekiq (optional)
4. Consider adding Sidekiq Web UI for visual queue monitoring (optional)

## Rollback Plan

If issues occur:

1. **Stop Sidekiq:**
   ```bash
   cap production sidekiq:stop
   ```

2. **Revert deployment:**
   ```bash
   cap production deploy:rollback
   ```

3. **Remove systemd service (if needed):**
   ```bash
   ssh deploy@159.223.100.164
   sudo systemctl stop sidekiq-autofauna
   sudo systemctl disable sidekiq-autofauna
   sudo rm /etc/systemd/system/sidekiq-autofauna.service
   sudo systemctl daemon-reload
   ```
