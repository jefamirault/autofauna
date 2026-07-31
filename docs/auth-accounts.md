# Auth & Accounts

Custom auth — no Devise. `User has_secure_password`. Auth uses encrypted cookies
(`cookies.encrypted[:user_id]` and `cookies.encrypted[:project_id]`).

## Project selection on login

The two cookies have independent lifetimes (`user_id` 6 months, `project_id` 1 year) and
`reset_session` clears neither, so signing in *without* logging out first would otherwise leave the
previous user's project selected — `auto_select_project` no-ops when `current_project` is already
present, and every later request then fails `authorize_*` and bounces to `/plants`.
`login` calls `discard_foreign_project_selection`, which drops the cookie unless the incoming user
owns or collaborates on that project. Membership, not blanket clearing: an advanced-mode guest merge
reassigns the guest's project to the target user, who should stay where they were. Every caller of
`login` re-selects afterwards via `auto_select_project` or `set_current_project`.

## Account types

- **Guest accounts:** real `User` records with `guest: true`, convertible to full accounts via
  `/guest_conversion`. Created at `/guest`.
- **Google Sign-In:** via Google Identity Services (JWT verification, `google_uid` on User).
  Callback at `/auth/google/callback`.

## Guest lifecycle

- **Cleanup:** `rake guests:cleanup` destroys guest accounts older than 30 days.
- **Merge on auth:** when a guest authenticates with an existing account, `merge_guest!` transfers
  all data (plants, zones, sensors, etc.) from the guest record to the target account.

## Account deletion

Async via `DeleteUserDataJob` — sets `login_enabled: false` immediately (locks the account out),
then destroys the data in the background. See `docs/background-jobs.md`.

## Google Sign-In + Turbo gotchas

- **Re-init on navigation:** with Turbo, you must manually call `google.accounts.id.initialize()`
  + `renderButton()` on `turbo:load` events (in `application.js`), or the button disappears after
  client-side navigation.
- **`ux_mode`:** include `ux_mode: "redirect"` in the manual `initialize()` calls to match the
  HTML config, or the flow breaks.

## Testing auth

Controller tests authenticate via the `sign_in(user)` helper (POSTs to `session_url`). The session
route is singular (`resource :session`). Full details in `test/CLAUDE.md`.
