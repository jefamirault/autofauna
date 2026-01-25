# Autofauna

Plant care and environmental monitoring Rails app. Multi-tenant with project-based collaboration.

## Stack

- Rails 8.0 / Ruby 3.2.2
- PostgreSQL
- Hotwire (Turbo + Stimulus)
- Importmap (no Node/Webpack)
- Capistrano deployment
- Minitest

## Commands

```bash
bin/rails server           # Start dev server
bin/rails console          # Rails console
bin/rails test             # Run tests
bin/rails db:migrate       # Run migrations
bin/rails routes           # Show routes

# Deployment
cap production deploy
```

## Domain Model

```
User
 └── Collaboration (role) ──► Project
                                ├── Zone
                                │    └── Location
                                │         └── Plant (watering schedule)
                                ├── Sensor (sensor_type)
                                │    └── HygroSensorReading
                                └── Tank
                                     └── WaterTest (jsonb parameters)
```

**Key relationships:**
- Projects are multi-tenant containers (owner_id + collaborations)
- Plants track watering frequency and last watering date
- Sensors post readings via API (api_key on Project)
- LogEntries are polymorphic (loggable)

## Key Files

| Path | Purpose |
|------|---------|
| `app/models/` | Domain logic |
| `app/controllers/` | Request handling |
| `app/views/` | ERB templates |
| `config/routes.rb` | URL routing |
| `db/schema.rb` | Current DB structure |

## Conventions

- Custom auth (no Devise) - User has_secure_password
- Ransack for search/filtering
- SASS for styles (sassc-rails)
- System tests with Capybara + Selenium

## API / Sensor Integration

Projects have `api_key` for sensor data ingestion.

**Transmit endpoint** (`GET /transmit`):
```
/transmit?project_id=1&API_KEY=xxx&sensor_id=1&temp=72&humidity=45&error=optional
```
| Param | Required | Description |
|-------|----------|-------------|
| `project_id` | Yes | Project ID |
| `API_KEY` | Yes | Must match `project.api_key` |
| `sensor_id` | Yes | Sensor ID |
| `temp` | Yes | Temperature reading |
| `humidity` | Yes | Humidity reading |
| `error` | No | Error message if sensor failed |

**Other sensor routes:**
| Route | Purpose |
|-------|---------|
| `GET /sensor_readings` | View last 1000 readings (requires auth) |
| `POST /sensor_readings/import` | JSON file import |

## Key Routes

- `/plants` - Main resource (root)
- `/plants/:id/water` - Quick watering action
- `/projects` - Multi-tenant containers
- `/zones` → `/locations` - Spatial hierarchy
- `/tanks/:tank_id/water_tests` - Nested water quality tests
- `/settings` - User preferences (includes locale: `/en`, `/es`)

## Testing

```bash
bin/rails test                    # All tests
bin/rails test test/models        # Model tests only
bin/rails test:system             # System tests (browser)
```

## Deployment

Capistrano to production server:
```bash
cap production deploy
```

Config in `config/deploy.rb` and `config/deploy/production.rb`
