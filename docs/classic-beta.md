# Classic beta

`G:\World of Warcraft\_classic_beta_` currently contains Forever 1.60.1,
build 69893. `ScarletUI-Camelot.toc` targets its interface version, 16001.

The beta uses Mainline UI frames with Classic equipment rules. ScarletUI
identifies it as `FOREVER` and reuses the existing modern UI mode, including
Blizzard bags, bank, and Edit Mode.

This matches the [UI source for build 1.60.1.69893](https://github.com/Gethe/wow-ui-source/tree/forever),
particularly the ActionBar, UnitFrame, EditMode, and UIPanels_Game manifests.

Install the addon files, `Modules`, and bundled `Libs` in
`G:\World of Warcraft\_classic_beta_\Interface\AddOns\ScarletUI`.
Restart the client after installing, then open `/sui` or `/sui move`.

The local Ace3 libraries were updated to
[r1414-alpha](https://www.wowace.com/projects/ace3/files/8908276), including
AceDB-3.0 revision 36 for Forever realm/ruleset compatibility. `Libs` is ignored
by Git; packaged releases fetch the libraries from upstream through `.pkgmeta`.
For a manual checkout, copy the matching library folders from that archive into
`Libs`, keeping the other dependencies. This update does not fix the beta client's
separately reported failure to restore SavedVariables.

Run `lua tests/client-compatibility.lua` from the repository root to check
client detection, UI mode selection, and the beta manifest. These checks do
not replace an in-game check of login, settings, bags, bank, and Edit Mode.
