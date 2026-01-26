# Agent Log: Conceal Multi-Project Feature

**Date:** 2026-01-26
**Task:** Hide multi-project functionality from regular users

## Summary

Implemented changes to conceal the multi-project feature from regular users. New users now automatically get a single project created and are directed straight to their plants. The project structure is invisible to them. An `advanced_mode` flag on users supports future opt-in to reveal full project functionality.

## Changes Made

### Database

- **New migration:** `db/migrate/20260126204657_add_advanced_mode_to_users.rb`
  - Adds `advanced_mode` boolean column to users table
  - Defaults to `false`

### Models

- **`app/models/user.rb`**
  - Added `after_create :create_default_project` callback
  - New users automatically get a project named "My Plants"

### Controllers

- **`app/controllers/registrations_controller.rb`**
  - Modified `create` action to set current project after registration
  - Redirects to `plants_path` instead of `root_path`

- **`app/controllers/sessions_controller.rb`**
  - Added `auto_select_project_for(user)` private method
  - Non-advanced users with one project are auto-selected into it on login

- **`app/controllers/application_controller.rb`**
  - Added `show_project_ui?` helper method (returns true only for advanced_mode users)
  - Modified `login` method to create default project for existing users who have none

- **`app/controllers/projects_controller.rb`**
  - Modified `index` action to redirect non-advanced users to plants
  - Added `before_action :require_advanced_mode` for show, edit, new actions
  - Added `require_advanced_mode` private method

### Views

- **`app/views/layouts/application.html.erb`**
  - Wrapped current project display with `show_project_ui?` conditional
  - Wrapped "Project Settings" nav link with `show_project_ui?` conditional

## Behavior Changes

| Scenario | Before | After |
|----------|--------|-------|
| New user registers | Lands on projects page to create/select project | Auto-creates "My Plants" project, lands on plants index |
| User logs in | May need to select project | Auto-selects single project for non-advanced users |
| Visit `/projects` | Shows project list | Redirects non-advanced users to plants |
| Visit `/projects/:id` | Shows project settings | Redirects non-advanced users to plants |
| Sidebar | Shows current project name and settings link | Hidden for non-advanced users |

## Required Action

Run database migration:
```bash
bin/rails db:migrate
```

## Future Work

- Add settings UI for users to enable `advanced_mode`
- Once enabled, users can create multiple projects and access sharing features
- Admin users and `advanced_mode` users retain full project functionality
