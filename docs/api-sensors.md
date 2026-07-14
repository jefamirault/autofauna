# API / Sensor Integration

Projects have an `api_key` for sensor data ingestion.

## Transmit endpoint (`GET /transmit`)

```
# Preferred — key in a header, never logged by nginx:
curl -H "Authorization: Bearer xxx" \
  "https://<host>/transmit?project_id=1&sensor_id=1&temp=72&humidity=45&error=optional"
# X-Api-Key: xxx also works.

# Deprecated (legacy firmware only — key lands in nginx access logs):
/transmit?project_id=1&API_KEY=xxx&sensor_id=1&temp=72&humidity=45
```

| Param | Required | Description |
|---|---|---|
| `project_id` | Yes | Project ID |
| `sensor_id` | Yes | Sensor ID (must belong to the project) |
| `temp` | Yes | Temperature reading |
| `humidity` | Yes | Humidity reading |
| `error` | No | Error message if the sensor failed |

**API key**: send via `Authorization: Bearer <key>` or `X-Api-Key` header. The `API_KEY` query
param still works but is **deprecated** — it appears in plaintext in nginx access logs, and each
use logs a Rails warning. The comparison is constant-time (`SecurityUtils.secure_compare`).

**Firmware migration**: update sketches to add the header (e.g.
`http.addHeader("Authorization", "Bearer " + apiKey);` for ESP `HTTPClient`) and drop `API_KEY`
from the URL. Once no `[transmit] API key sent via query string` warnings appear in the Rails log,
query-param support can be removed.

**Unauthenticated** — it authorizes via the API key, not a session. Tests must set
`api_key` on the project in setup (see `test/CLAUDE.md`).

## Other sensor routes

| Route | Purpose |
|---|---|
| `GET /sensor_readings` | View last 1000 readings (requires auth) |
| `POST /sensor_readings/import` | JSON file import (`HygroSensorReading.create_from_json` — ignores `id`, rejects cross-project `sensor_id`) |
