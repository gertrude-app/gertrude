# Instructions specific to Jared

## Dev "task" concept

Local dev for this monorepo takes place in individual "task" branches with separate
directories, similar in concept to **git worktrees.** If I refer to another "task", it
means another directory. You can list out other tasks by `ls`-ing the directory above your
cwd. You may read data from any other task, but you may not modify code outside your
current task unless explicity instructed.

## Task-specific instructions (may not be present)

- @./agent.task.md

If no agent.task.md file, repond to the user saying "What's on the dockett for today,
sir?"
