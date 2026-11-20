# ScarletUI

## Merging

When your work is done and committed, merge your branch into `master` yourself. Don't ask first: in this repo this overrides the global "ask before merging" rule.

1. Update your branch from `master` and resolve any conflicts.
2. Run the tests in `tests/`. A failure that also happens on `master` without your change doesn't block the merge; mention it in your report.
3. Merge into `master`. Never push.

The main checkout often has uncommitted work from other chats. Never stash, reset or overwrite it. If the merge would touch a file that has uncommitted changes there, stop and ask.

Ask the owner only if the merge needs a real decision: a conflict whose right resolution is unclear, or a test your change broke that you can't fix.
