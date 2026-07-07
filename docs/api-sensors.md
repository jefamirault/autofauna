# API / Sensor Integration

Projects have an `api_key` for sensor data ingestion.

## Transmit endpoint (`GET /transmit`)

```
/transmit?project_id=1&API_KEY=xxx&sensor_id=1&temp=72&humidity=45&error=optional
```

| Param | Required | Description |
|---|---|---|
| `project_id` | Yes | Project ID |
| `API_KEY` | Yes | Must match `project.api_key` |
| `sensor_id` | Yes | Sensor ID |
| `temp` | Yes | Temperature reading |
| `humidity` | Yes | Humidity reading |
| `error` | No | Error message if the sensor failed |

**Unauthenticated** — it authorizes via the API-key param, not a session. Tests must set
`api_key` on the project in setup (see `test/CLAUDE.md`).

## Other sensor routes

| Route | Purpose |
|---|---|
| `GET /sensor_readings` | View last 1000 readings (requires auth) |
| `POST /sensor_readings/import` | JSON file import |
