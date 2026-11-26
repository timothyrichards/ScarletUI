# ScarletUI

## Merging

When your work is done and committed, merge your branch into `master` yourself. Don't ask first: in this repo this overrides the global "ask before merging" rule.

1. Update your branch from `master` and resolve any conflicts.
2. Run the tests in `tests/`. A failure that also happens on `master` without your change doesn't block the merge; mention it in your report.
3. Merge into `master`. Never push.

The main checkout often has uncommitted work from other chats. Never stash, reset or overwrite it. If the merge would touch a file that has uncommitted changes there, stop and ask.

Ask the owner only if the merge needs a real decision: a conflict whose right resolution is unclear, or a test your change broke that you can't fix.

## Versioning

ScarletUI uses semantic versioning (`## Version: MAJOR.MINOR.PATCH`, kept identical in all five TOCs; `tests/toc-version.lua` checks this). The settings window shows it in the title bar.

Every change merged to `master` bumps the version in all TOCs, in the same merge:

- PATCH for fixes.
- MINOR for new features or options.
- MAJOR for breaking changes, such as a saved-variable reset.

After merging, tag the merge commit `vX.Y.Z` (`git tag vX.Y.Z`). Never push tags.
