# Task Spinoff Instructions

This document describes how to spin out implementation tasks from this planning directory.

## Workflow

1. User requests a task be created (e.g., "spin this out", "create a task for this")
2. Propose a branch slug for approval (e.g., `ios-pending-supervision-model`)
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

After running `gtask`, create `claude.task.md` in the new task directory with three sections:

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

Create the IosPendingSupervisedDevice database model to track supervision requests initiated
from the iOS app. This table links a parent's account to a pending device via a short code,
enabling the supervision tool to claim and supervise the device.
```
