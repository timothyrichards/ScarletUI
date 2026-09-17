# Classic beta

`G:\World of Warcraft\_classic_beta_` currently contains Forever 1.60.1,
build 69893. `ScarletUI-Camelot.toc` targets its interface version, 16001.

The beta uses Mainline UI frames with Classic equipment rules. ScarletUI
identifies it as `FOREVER` and reuses the existing modern UI mode, including
Blizzard bags, bank, and Edit Mode. Legacy custom bags, nameplates, and frame
movers are disabled as on Retail.

This matches the [UI source for build 1.60.1.69893](https://github.com/Gethe/wow-ui-source/tree/forever),
particularly the ActionBar, UnitFrame, EditMode, and UIPanels_Game manifests.

Install the addon files, `Modules`, and bundled `Libs` in
`G:\World of Warcraft\_classic_beta_\Interface\AddOns\ScarletUI`.
Restart the client after installing, then open `/sui` or `/sui move`.

Run `lua tests/client-compatibility.lua` from the repository root to check
client detection, UI mode selection, and the beta manifest. These checks do
not replace an in-game check of login, settings, bags, bank, and Edit Mode.
