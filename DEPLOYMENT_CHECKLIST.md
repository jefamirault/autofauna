# Quick Deployment Checklist

## Pre-Deployment (Do Once)

### On Production Server (SSH to deploy@159.223.100.164)

- [ ] **Install Redis**
  ```bash
  sudo apt update
  sudo apt install redis-server
  sudo systemctl enable redis-server
  sudo systemctl start redis-server
  redis-cli ping  # Should return PONG
  ```

- [ ] **Verify Environment Variables** (`/home/deploy/autofauna/.rbenv-vars`)
  ```bash
  cat /home/deploy/autofauna/.rbenv-vars
  ```
  Should contain:
  - `REDIS_URL=redis://localhost:6379/0`
  - `MAILGUN_SMTP_USERNAME=postmaster@mg.autofauna.org`
  - `MAILGUN_SMTP_PASSWORD=<password>`
  - `RAILS_MASTER_KEY=<key>`

- [ ] **Create shared config directory**
  ```bash
  mkdir -p /home/deploy/autofauna/shared/config
  ```

## Deployment

### On Local Machine

- [ ] **Install gems**
  ```bash
  cd /home/jef/autofauna
  bundle install
  ```

- [ ] **Commit and push**
  ```bash
  git add Gemfile Gemfile.lock Capfile config/deploy.rb
  git commit -m "Add capistrano-sidekiq for automated worker management"
  git push origin notifications
  ```

- [ ] **Deploy**
  ```bash
  cap production deploy
  ```

## Post-Deployment Verification

### Check Sidekiq Status

- [ ] **Via Capistrano** (from local machine)
  ```bash
  cap production sidekiq:status
  ```

- [ ] **Via SSH** (on production server)
  ```bash
  ssh deploy@159.223.100.164
  sudo systemctl status sidekiq-autofauna
  ps aux | grep sidekiq
  ```

### Test Email Sending

- [ ] **Send test email**
  1. Visit https://autofauna.org/settings
  2. Click "Send Test Email"
  3. Check inbox for email

- [ ] **Check logs**
  ```bash
  # Production logs
  tail -f /home/deploy/autofauna/shared/log/production.log

  # Sidekiq logs
  tail -f /home/deploy/autofauna/shared/log/sidekiq.log
  ```

- [ ] **Verify queue is empty**
  ```bash
  cd /home/deploy/autofauna/current
  bundle exec rails console production
  > Sidekiq::Queue.all.map { |q| [q.name, q.size] }
  # Should show [["default", 0], ["mailers", 0]]
  ```

### Check Cron Job

- [ ] **Verify hourly notification job**
  ```bash
  cd /home/deploy/autofauna/current
  bundle exec rails console production
  > Sidekiq::Cron::Job.all
  # Should show plant_notifications job scheduled
  ```

## Success Criteria

All checks passed when:
- ✓ Redis responds to `ping` command
- ✓ Sidekiq service is "active (running)"
- ✓ Test email arrives in inbox
- ✓ Sidekiq logs show "Delivered mail" message
- ✓ Queue sizes are 0 or decreasing
- ✓ Cron job appears in Sidekiq::Cron::Job.all

## Quick Commands Reference

```bash
# Start/Stop/Restart Sidekiq (from local machine)
cap production sidekiq:start
cap production sidekiq:stop
cap production sidekiq:restart
cap production sidekiq:status

# View logs (on production server)
tail -f /home/deploy/autofauna/shared/log/sidekiq.log
tail -f /home/deploy/autofauna/shared/log/production.log

# Check Redis (on production server)
redis-cli ping
redis-cli info stats

# Rails console (on production server)
cd /home/deploy/autofauna/current
bundle exec rails console production
```

## If Something Goes Wrong

1. **Check Sidekiq logs:**
   ```bash
   tail -100 /home/deploy/autofauna/shared/log/sidekiq.log
   ```

2. **Check systemd service:**
   ```bash
   sudo journalctl -u sidekiq-autofauna -n 50
   ```

3. **Restart Sidekiq:**
   ```bash
   cap production sidekiq:restart
   ```

4. **Full rollback if needed:**
   ```bash
   cap production deploy:rollback
   ```

See `SIDEKIQ_DEPLOYMENT_GUIDE.md` for detailed troubleshooting steps.
