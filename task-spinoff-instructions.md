# Task Spinoff Instructions

This document describes how to spin out implementation tasks from this planning directory.

## Branch Naming Convention

All task branches for this iOS supervision feature use the prefix:

```
superios-task-{NN}-<short-description>
```

Examples:
- `superios-task-01-pending-supervision`
- `superios-task-02-device-supervision-fields`
- `superios-task-11-supervision-state-machine`

## Workflow

1. User requests a task be created (e.g., "spin this out", "create a task for this")
2. Propose a branch slug following the naming convention above
3. Wait for user approval or rename request
4. Once approved, run: `gtask <slug>`
5. Create `claude.task.md` in the new task directory (see below)

## Finding the New Task Directory

The `gtask` script creates directories at:

```
~/gertie/tasks/<slug>--<MM-DD-YYYY>
```

Use the current date to locate the newly created directory.

## Creating claude.task.md

After running `gtask`, create `claude.task.md` in the new task directory with four sections:

### 1. Context (~10 lines)

Describe the larger iOS supervision onboarding feature this task belongs to. Include:
- The two main goals (account connection + supervision tool for 18+ users)
- That this is part of a 21-task implementation plan
- Brief mention of the systems involved (iOS app, API, dashboard, supervision tool)

### 2. Links

Provide paths to relevant planning documents from this directory. Format as:

```
For additional context, read these files as needed:
- /Users/jared/gertie/tasks/iosapp-supervision-feature-planning--01-01-2026/subtasks/README.md
- /Users/jared/gertie/tasks/iosapp-supervision-feature-planning--01-01-2026/subtasks/<task-file>.md
- (other relevant docs)
```

Do NOT use @ imports. Just list the absolute paths with guidance to read as needed.

### 3. Summary (5 lines or less)

A concise summary of what this specific task accomplishes. Pull from the corresponding
subtask markdown file in `subtasks/`.

### 4. Full Task Document

Append the complete contents of the subtask markdown file from `subtasks/`. This ensures
the implementing agent has all the detailed specifications, implementation notes, and
decisions directly in the task file without needing to read external documents.

## Example claude.task.md

```markdown
# Task Context

This task is part of the iOS supervision onboarding feature for Gertrude parental controls.
The feature enables two main goals: (1) connecting iOS app users to Gertrude accounts for
free basic blocking, and (2) providing a new supervision flow for adults (18+) that doesn't
require Apple Configurator or device erasure. The implementation spans 21 tasks across the
iOS app, Swift API, parent dashboard, and supervision tool. This is a multi-phase rollout
with database and API work landing first, followed by consumer app changes.

For additional context, read these files as needed:
- /Users/jared/gertie/tasks/iosapp-supervision-feature-planning--01-01-2026/subtasks/README.md
- /Users/jared/gertie/tasks/iosapp-supervision-feature-planning--01-01-2026/subtasks/01_ios-pending-supervision-model.md
- /Users/jared/gertie/tasks/iosapp-supervision-feature-planning--01-01-2026/supervision-onboarding-recommendations.md

# Task Summary

Create the PendingSupervision database model and CreatePendingSupervision API endpoint to
track supervision requests initiated from the iOS app. This table links a parent's account
to a pending device via a 6-digit code.

---

# Task Details

(Full contents of the subtask markdown file go here...)
```
