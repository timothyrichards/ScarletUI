# Required workflow for Codex

These rules apply to all Codex models working in this repository.

1. Before starting new work, always fetch and pull from the current branch's upstream so the project is up to date. Inspect the working tree first and preserve existing local changes. If synchronization is blocked, report the blocker before proceeding with new work.
2. If pulling causes merge conflicts that Unity Smart Merge can resolve, use Unity Smart Merge (`UnityYAMLMerge`) for those files. Review the result and resolve any remaining conflicts before continuing. If the tool is unavailable, report that limitation.
3. When work is complete, review and commit all changes belonging to the task before reporting completion. Leave unrelated changes out of the commit.
4. After committing, always offer to push. Push only when the user authorizes it.
