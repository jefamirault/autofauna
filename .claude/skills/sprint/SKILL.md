---
name: sprint
description: Launch a multi-agent sprint on a GitHub milestone. Fetches issues, groups by label, creates worktrees, and starts claude instances in tmux panes.
user_invocable: true
arguments:
  - name: milestone
    description: GitHub milestone title to sprint on
    required: true
---

# Sprint Skill

Launch a coordinated multi-agent sprint on a GitHub milestone.

## What This Does

When the user invokes `/sprint <milestone>`:

1. **Validate** the milestone exists and has open issues
2. **Preview** the sprint plan (issue groupings and branch assignments)
3. **Launch** the `claude-sprint` script to set up tmux + worktrees + claude agents

## Instructions

### Step 1: Validate the milestone

Run this to check the milestone exists and show the issues:

```bash
gh issue list --repo jefamirault/autofauna --milestone "<milestone>" --state open --json number,title,labels,body
```

If no issues are found, tell the user and stop.

### Step 2: Show the dry-run plan

Run the sprint script in dry-run mode so the user can review the plan before launching:

```bash
cd /home/jef/autofauna && ./claude-sprint "<milestone>" --dry-run
```

This shows which issues will be assigned to which worker agents and on which branches.

### Step 3: Ask for confirmation

Ask the user:
- Does the grouping look right? (They can adjust labels on GitHub to change groupings)
- Do they want a different number of workers? (default is 4, use `--agents N`)
- Ready to launch?

### Step 4: Launch the sprint

Once confirmed, tell the user to run the command themselves since it needs an interactive terminal:

```
! ./claude-sprint "<milestone>"
```

Or with custom agent count:

```
! ./claude-sprint "<milestone>" --agents 3
```

The script will:
- Create `sprint/<milestone>/<label>` branches for each worker
- Set up git worktrees for each branch
- Copy `.env` to each worktree with a unique database name (`autofauna_sprint_worker_N`) and port (`3001`, `3002`, etc.)
- Create per-worker PostgreSQL databases (full copy of dev DB — data + schema)
- Launch a tmux session with manager (top, full width) + N workers (bottom, split)
- Start `claude` in each pane with role-specific prompts

### Dynamic Pane Count

The number of tmux panes adapts to the actual number of worker groups with issues assigned, not a fixed count. For example, 2 issues with 2 labels = 3 panes total (1 manager + 2 workers), not 5.

### Tmux Layout

```
+---------------------------+
|        Manager            |
+-------------+-------------+
|  Worker 1   |  Worker 2   |
+-------------+-------------+
```

- **Manager** (pane 0): top row, full width, on main branch
- **Workers** (panes 1-N): bottom row, split evenly, each in its own worktree

### How the Sprint Works

**Manager agent** (main branch, top pane):
- Reads all milestone issues
- Posts implementation guidance as issue comments
- Monitors worker progress via `git log`
- Creates PRs when workers finish
- Coordinates if workers need shared files

**Worker agents** (feature branches, bottom panes):
- Implement assigned issues on their branch
- Commit with issue references (`Fix #123: ...`)
- Run tests after changes
- Comment on issues when done

### Cleanup

When the sprint finishes, run cleanup to tear down everything:

```
! ./claude-sprint --cleanup
```

Or for a specific milestone only:

```
! ./claude-sprint --cleanup "<milestone>"
```

This removes:
- Git worktrees
- Sprint branches (`sprint/*`)
- Worker databases (`autofauna_sprint_worker_*`)
- The tmux session
- Temp prompt files

### After the Sprint

When the sprint finishes:
1. Manager creates PRs for each worker branch
2. User reviews and merges PRs
3. Run `./claude-sprint --cleanup` to tear down worktrees, branches, and databases
4. Close the milestone: `gh issue list --milestone "<milestone>" --state open` to verify all done

### Merging Worker Branches

When the user asks to merge completed branches:

1. Check each branch for commits: `git log --oneline <branch> ^main`
2. Show diff stats: `git diff --stat main...<branch>`
3. Merge one at a time so the user can test between merges
4. Order by risk (smallest/safest changes first):
   - Locale/translation fixes (YAML only)
   - JS-only changes (Stimulus controller tweaks)
   - Multi-file feature work (CSS + JS + views)
5. Use `git merge <branch> --no-edit` for clean fast-forwards or simple merges

### Conflict Avoidance

When multiple workers touch shared files (e.g., locale YAML files), define clear scope boundaries in the implementation guidance comments:
- Worker A: only **fixes existing** keys
- Worker B: only **adds new** keys
- This prevents merge conflicts even when both touch the same file

### Sprint Manager Best Practices

- Post implementation guidance as issue comments BEFORE workers start (gives them a roadmap)
- Include a "Files to Modify" table and "Scope Boundaries" section in each guidance comment
- Identify shared-file conflicts proactively and coordinate scope boundaries
- Keep `agent_log.md` updated with sprint progress

### Known Gotcha: .env Carriage Returns

The `.env` file may have Windows-style `\r\n` line endings. The `claude-sprint` script strips `\r` when reading credentials to prevent silent failures in `psql`/`createdb`/`dropdb` commands.
