# Sidekiq + Redis Setup Guide

This guide covers Redis and Sidekiq setup, verification, and troubleshooting for the Autofauna Rails application.

## Overview

Sidekiq is configured to handle background jobs and scheduled tasks:
- **Background jobs**: Email notifications, async processing
- **Scheduled jobs**: Hourly plant watering reminders via `PlantNotificationJob`

## 1. Redis Verification

### Check if Redis is Running

**Important**: Redis is NOT an HTTP service. You cannot access it via a web browser at `http://localhost:6379/`. Attempting to do so will show "connection reset" - this is normal and expected.

Redis uses its own protocol (RESP - Redis Serialization Protocol), so you must use `redis-cli` to verify connectivity.

#### Proper verification commands:

```bash
# Ping test (should return PONG)
redis-cli ping

# Check server info
redis-cli info server

# Test read/write
redis-cli set test "hello"
redis-cli get test

# Check process status
ps aux | grep redis
```

#### Expected output:
```
$ redis-cli ping
PONG

$ ps aux | grep redis
redis      71961  0.3  0.0 158628 17664 ?  Ssl  18:42  0:02 /usr/bin/redis-server 127.0.0.1:6379
```

### Starting Redis (if not running)

```bash
# Ubuntu/Debian
sudo systemctl start redis-server
sudo systemctl status redis-server

# macOS
brew services start redis
```

## 2. Starting Sidekiq

### Development Mode

From the project root directory:

```bash
cd /home/jef/autofauna
bundle exec sidekiq
```

### Expected Output

When Sidekiq starts successfully, you should see:

```
         m,
         `$b
    .ss,  $$:         .,d$
    `$$P,d$P'    .,md$P"'
     ,$$$$$b/md$$$P^'
   .d$$$$$$/$$$P'
   $$^' `"/$$$'       ____  _     _      _    _
   $:    ',$$:       / ___|(_) __| | ___| | _(_) __ _
   `b     :$$        \___ \| |/ _` |/ _ \ |/ / |/ _` |
          $$:         ___) | | (_| |  __/   <| | (_| |
          $$         |____/|_|\__,_|\___|_|\_\_|\__, |
        .d$$                                        |_|

2024-XX-XX 12:34:56 UTC m=12345 pid=12345 tid=abcd INFO: Booting Sidekiq 7.x.x
2024-XX-XX 12:34:56 UTC m=12345 pid=12345 tid=abcd INFO: Running in ruby 3.2.2
2024-XX-XX 12:34:56 UTC m=12345 pid=12345 tid=abcd INFO: Upgrade to Sidekiq Pro for more features and support
2024-XX-XX 12:34:56 UTC m=12345 pid=12345 tid=abcd INFO: Starting processing, hit Ctrl-C to stop
```

### Production Mode

Sidekiq is typically run as a systemd service in production. The Capistrano deployment handles this automatically.

## 3. Configuration

### Connection Settings

**Location**: `/home/jef/autofauna/config/initializers/sidekiq.rb`

```ruby
Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end
```

**Note on SSL Verification**: The configuration includes `ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }`. This disables SSL certificate verification. This is acceptable for local development with `redis://localhost:6379` (which doesn't use SSL anyway), but in production:
- If using a managed Redis service with SSL (e.g., `rediss://` URL), consider enabling proper SSL verification
- For local/unencrypted Redis connections, this setting has no effect

### Queue Configuration

**Location**: `/home/jef/autofauna/config/sidekiq.yml`

```yaml
:concurrency: 5
:queues:
  - default
  - mailers

production:
  :concurrency: 10

development:
  :concurrency: 2
```

- **Concurrency**: Number of threads processing jobs simultaneously
- **Queues**:
  - `default` - General background jobs
  - `mailers` - Email-related jobs

### Scheduled Jobs (Cron)

**Location**: `/home/jef/autofauna/config/schedule.yml`

```yaml
plant_notifications:
  cron: '0 * * * *'  # Every hour at minute 0
  class: 'PlantNotificationJob'
  queue: 'default'
  description: 'Send watering reminder notifications to users'
```

The `PlantNotificationJob` runs hourly to check plants needing water and send notifications to users.

## 4. Monitoring Jobs

### Rails Console

```bash
cd /home/jef/autofauna && bin/rails console
```

Then in console:

```ruby
# Check scheduled jobs
Sidekiq::Cron::Job.all

# Check job details
Sidekiq::Cron::Job.find('plant_notifications')

# View queue stats
Sidekiq::Stats.new

# View queues
Sidekiq::Queue.all

# Check specific queue
Sidekiq::Queue.new('default').size
```

### Sidekiq Web UI (Optional)

The Sidekiq web UI is not currently mounted in routes. To add it, edit `/home/jef/autofauna/config/routes.rb`:

```ruby
require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  # Add authentication in production!
  mount Sidekiq::Web => '/sidekiq'

  # ... rest of routes
end
```

Then access at `http://localhost:3000/sidekiq` (development).

**Security Note**: In production, protect this endpoint with authentication.

### Log Files

Sidekiq output goes to:
- **Development**: Terminal where Sidekiq was started
- **Production**: `/home/jef/autofauna/log/sidekiq.log` (configured via Capistrano)

## 5. Common Issues & Troubleshooting

### "Connection refused" when starting Sidekiq

**Problem**: Sidekiq can't connect to Redis.

**Solutions**:
1. Verify Redis is running: `redis-cli ping`
2. Check Redis is listening on expected port: `ps aux | grep redis`
3. Verify `REDIS_URL` environment variable (if set): `echo $REDIS_URL`
4. Check firewall isn't blocking port 6379

### Jobs not processing

**Problem**: Jobs are queued but not executing.

**Solutions**:
1. Ensure Sidekiq is actually running (check terminal/logs)
2. Check queue configuration matches job queue names
3. Verify concurrency settings aren't set to 0
4. Check for errors in Sidekiq logs

### Scheduled jobs (cron) not running

**Problem**: `PlantNotificationJob` isn't running hourly.

**Solutions**:
1. Verify `schedule.yml` exists and is loaded:
   ```ruby
   # In Rails console
   Sidekiq::Cron::Job.all
   ```
2. Check cron job was loaded properly:
   ```ruby
   Sidekiq::Cron::Job.find('plant_notifications')
   ```
3. Ensure sidekiq-cron gem is installed: `bundle list | grep sidekiq-cron`
4. Check Sidekiq server (not just client) is running

### "SSL_connect" errors in production

**Problem**: SSL certificate verification failures when connecting to Redis.

**Current config**: SSL verification is disabled (`verify_mode: OpenSSL::SSL::VERIFY_NONE`).

**If you want to enable SSL verification**:
1. Remove or modify `ssl_params` in `config/initializers/sidekiq.rb`
2. Ensure valid SSL certificates are in place
3. For managed Redis services, consult provider documentation for SSL setup

### Memory issues

**Problem**: Sidekiq consuming too much memory.

**Solutions**:
1. Reduce concurrency in `config/sidekiq.yml`
2. Monitor job memory usage and optimize heavy jobs
3. Consider splitting queues across multiple Sidekiq processes
4. Use `MemoryKiller` middleware for automatic restarts

## 6. Testing

### Manually trigger a job

```ruby
# In Rails console
PlantNotificationJob.perform_now  # Synchronous (immediate)
PlantNotificationJob.perform_later  # Async (queued via Sidekiq)
```

### Check job was queued

```ruby
# In Rails console
Sidekiq::Queue.new('default').size  # Should increase by 1
```

### Monitor job execution

Watch the Sidekiq terminal/logs for job processing messages:

```
2024-XX-XX 12:34:56 UTC m=12345 pid=12345 tid=abcd PlantNotificationJob JID-xxx INFO: start
2024-XX-XX 12:34:57 UTC m=12345 pid=12345 tid=abcd PlantNotificationJob JID-xxx INFO: done: 0.123 sec
```

## 7. Development Workflow

Typical development workflow:

1. **Start Redis** (if not already running):
   ```bash
   sudo systemctl start redis-server
   # or: brew services start redis
   ```

2. **Start Rails server** (terminal 1):
   ```bash
   cd /home/jef/autofauna && bin/rails server
   ```

3. **Start Sidekiq** (terminal 2):
   ```bash
   cd /home/jef/autofauna && bundle exec sidekiq
   ```

4. **Make changes**, and Sidekiq will auto-reload in development mode (for most changes)

5. **Test jobs** via Rails console or application usage

## 8. Production Deployment

When deploying via Capistrano:

```bash
cap production deploy
```

The deployment automatically:
- Restarts Sidekiq service on the server
- Loads new code and configuration
- Reloads scheduled cron jobs

### Environment Variables

Production uses `/home/deploy/autofauna/.rbenv-vars` for configuration:
- `REDIS_URL` - If using remote/managed Redis
- `RAILS_MASTER_KEY` - For credentials decryption

## Additional Resources

- [Sidekiq Documentation](https://github.com/sidekiq/sidekiq/wiki)
- [Sidekiq-Cron Documentation](https://github.com/sidekiq-cron/sidekiq-cron)
- [Redis Documentation](https://redis.io/documentation)
- [Redis CLI Guide](https://redis.io/docs/ui/cli/)
