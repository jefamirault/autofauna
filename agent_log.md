# Agent Log

Current session log. Previous logs archived in `agent_log/`.

---

## 2026-02-22 — Update CLAUDE.md with Context from Agent Logs

Read all 9 archived agent logs and extracted useful context into CLAUDE.md. Added the following sections:

- **Stack:** Added Sidekiq + Redis, capistrano-sidekiq
- **Domain Model:** Expanded with all new models (Recipe, RecipeSource, RecipeIngredient, RecipeBatch, SoilMoistureReading, PushSubscription), updated User/Project/Plant/Watering/Location attributes
- **Key Files:** Added plant_graphics concern, application_helper, Stimulus controllers directory
- **Conventions:** Added guest accounts, Google auth, advanced_mode documentation
- **Design System:** New section documenting CSS component classes (resource-card, info-card, settings-card)
- **Background Jobs:** New section covering Sidekiq/Redis configuration, queues, cron jobs
- **Notifications:** New section covering email (Mailgun) and push (web-push gem) notifications
- **Plants Index UI:** New section documenting display modes, filters, pagination, search
- **Stimulus Controllers:** New section listing all 11 controllers with their purposes
- **Layout Architecture:** New section covering grid layout, context-aware header, sidebar states, FOUC prevention, mobile behavior
- **Key Routes:** Expanded with recipe, moisture, sharing, guest, and Google auth routes
- **Deployment:** Added env vars (REDIS_URL, Mailgun), Sidekiq production config
- **Common Patterns & Gotchas:** New section with 10 documented pitfalls (Turbo frames, Google Sign-In, Ransack params, N+1 queries, etc.)

