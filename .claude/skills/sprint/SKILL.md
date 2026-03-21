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
- Launch a tmux session with 5 panes (1 manager + 4 workers)
- Start `claude` in each pane with role-specific prompts

### How the Sprint Works

**Manager agent** (main branch, pane 0):
- Reads all milestone issues
- Posts implementation guidance as issue comments
- Monitors worker progress via `git log`
- Creates PRs when workers finish
- Coordinates if workers need shared files

**Worker agents** (feature branches, panes 1-4):
- Implement assigned issues on their branch
- Commit with issue references (`Fix #123: ...`)
- Run tests after changes
- Comment on issues when done

### After the Sprint

When the sprint finishes:
- Manager creates PRs for each worker branch
- User reviews and merges PRs
- Clean up worktrees: `git worktree list` then `git worktree remove <path>`
- Close the milestone: `gh issue list --milestone "<milestone>" --state open` to verify all done
