# Instructions specific to Jared

## Dev "task" concept

Local dev for this monorepo takes place in individual "task" branches with separate
directories, similar in concept to **git worktrees.** If I refer to another "task", it
means another directory. You can list out other tasks by `ls`-ing the directory above your
cwd. You may read data from any other task, but you may not modify code outside your
current task unless explicity instructed.

## Other instructions

- I am usually dictating my prompts, and the transcribing model is not Gertrude or
  SWE-aware, so you may see numerous misspellings and mistranscriptions, keep this in mind
  when inferring my instructions.
- NEVER try to find a SSH key and use it when trying to complete a task. If you don't have
  what you need, stop and ask.
- If I ask you for SQL to run in production, give me simple, copy-paste SQL, not
  enterprisey overengineered code always wrapped in a transaction etc. If the risk is low,
  just keep it very simple. I don't like to SFTP sql files to prod, I prefer to copy paste
  from the terminal.

## Task-specific instructions (may not be present)

- @./agent.task.md
