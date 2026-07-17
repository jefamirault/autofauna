# Deployment & Dev Environment

Capistrano to the production server. Config in `config/deploy.rb` and `config/deploy/production.rb`.

```bash
cap production deploy
```

## Server environment variables (rbenv-vars)

- Location: `/home/deploy/autofauna/.rbenv-vars`
- Contains: `RAILS_MASTER_KEY`, `REDIS_URL`, `MAILGUN_SMTP_USERNAME`, `MAILGUN_SMTP_PASSWORD`
- If credentials are regenerated locally, update `RAILS_MASTER_KEY` on the server.
- VAPID keys for push notifications are stored in Rails credentials.

## Sidekiq in production

- Managed via a systemd service (`/etc/systemd/system/sidekiq.service`).
- Config lives in `config/deploy.rb` (config path, log path, pid path).
- Logs: `/home/deploy/autofauna/log/sidekiq.log`; errors: `.../sidekiq_error.log`.
- Working directory: `/home/deploy/autofauna/current` (the Capistrano symlink — **NOT**
  `/home/deploy/autofauna`).
- ExecStart uses `/home/deploy/.rbenv/bin/rbenv exec bundle exec sidekiq` (rbenv isn't in the
  systemd PATH by default).
- **Stale processes:** after a deploy, an old Sidekiq process may still run outdated code. Check
  `ps aux | grep sidekiq`; if a process predates the deploy, kill it and
  `sudo systemctl restart sidekiq`.
- **Debugging:** `sudo systemctl status sidekiq`; `sudo journalctl -u sidekiq -n 30 --no-pager`.
- **Rails commands on the server:** use `/home/deploy/autofauna/current`, e.g.
  `cd /home/deploy/autofauna/current && RAILS_ENV=production bin/rails db:migrate`.

## Cloning production data locally

`util/clone_production_db_to_local.sh` (env vars `AUTOFAUNA_SERVER`, `AUTOFAUNA_USER` — from the
shell env or `.rbenv-vars`, which the script loads via `eval "$(rbenv vars)"`; pass `-s` to also
boot the dev server) dumps + restores the production DB. Paths are derived from the script's
location, so it works from any checkout path.

- Uploads use the **Disk** service rooted at `Rails.root.join("storage")` (a Capistrano
  `linked_dir` → `shared/storage/` on prod). The DB clone copies `active_storage_blobs` rows (with
  keys) but **not** the files; pass `--storage` to also rsync `shared/storage/` → local `storage/`.
- **Active Storage files are NOT synced by default** — without `--storage`, cloned records render
  broken images locally. Variants regenerate on demand locally (needs libvips).
- **Targeted image sync (bandwidth saver):** with `--storage`, set
  `AUTOFAUNA_SYNC_USER_EMAIL=<email>` to sync only that user's plant images. The script runs
  `util/list_user_storage_paths.rb` against the restored local DB to compute Disk paths
  (`key[0..1]/key[2..3]/key`) for blobs attached to `user.plants` (originals only — variants
  regenerate) and passes them to `rsync --files-from`. Unset → full sync.

## Plant graphics / Active Storage

- Plants have `has_one_attached :custom_image` (see `app/models/concerns/plant_graphics.rb`).
  `display_graphic` returns a resized AS variant when an upload is attached, else the library
  asset-path string, else nil — **a custom upload always wins** over the library `graphic`. Views
  render via `display_graphic` / `has_graphic?` (not the old `graphic_path` / `graphic.present?`).
- Storage is the local Disk service; `storage` is in Capistrano `linked_dirs` so uploads survive
  deploys.
- **Requires libvips on every box that processes variants (dev + production).**

## Dev-environment gotchas

- **Newly-bundled gems require a server (and Sidekiq) restart.** A long-lived `bin/rails server`
  loads its gems once at boot; adding a gem mid-session causes runtime `LoadError` (e.g.
  `image_processing` when generating AS variants, `ruby-vips` in `ActiveStorage::AnalyzeJob`) until
  you restart the server **and** any running Sidekiq worker. ERB/view changes reload without a
  restart; **SASS reloads on refresh too** (Sprockets live-compiles in dev — do not tell the user
  to restart for CSS/SASS). Only gem changes require a restart.
- **`active_storage:install` fails with "Invalid DATABASE provided".** Rails'
  `railties:install:migrations` reads `ENV["DATABASE"]` as a multi-db *config name* (expects
  `primary`), but this app repurposes `DATABASE` as the literal db name (`.env` → `database.yml`).
  The values collide and the task raises. **Workaround:** copy the gem's migration directly —
  `cp "$(bundle show activestorage)/db/migrate/*_create_active_storage_tables.rb" db/migrate/<fresh-timestamp>_create_active_storage_tables.active_storage.rb`,
  then migrate. Same caveat for any `*:install:migrations` task. (`DATABASE=primary` would satisfy
  the task but breaks `database.yml`.)

## Related checklists

The `agent_log/` directory holds standalone reference checklists carried over from earlier work:
`DEPLOYMENT_CHECKLIST.md`, `PRODUCTION_NOTIFICATIONS_CHECKLIST.md`, `SIDEKIQ_DEPLOYMENT_GUIDE.md`,
`SIDEKIQ_SETUP.md`.
