# ScarletUI agent guide

ScarletUI is a Lua World of Warcraft addon built on Ace3. This guide describes
this checkout; the TOCs and source are authoritative when client versions change.

## Clients and loading

All six manifests load the same addon files in the same order:

| Manifest | Client | Interface |
| --- | --- | --- |
| `ScarletUI-Vanilla.toc` | Classic Era | 11509 |
| `ScarletUI-TBC.toc` | Burning Crusade Classic | 20505 |
| `ScarletUI-Cata.toc` | Cataclysm Classic | 40402 |
| `ScarletUI-Mists.toc` | Mists of Pandaria Classic | 50503 |
| `ScarletUI-Mainline.toc` | Retail | 120005 |
| `ScarletUI-Camelot.toc` | Classic Forever beta | 16001 |

Update all six manifests when adding or removing a loaded module.
`GetWoWVersion()` in `Modules/Helpers.lua` returns a client identifier and interface
number. Identifiers for these targets are `VANILLA`, `TBC`, `CATA`, `MOP`, `RETAIL`,
and `FOREVER`; older expansion identifiers also exist. Do not use `MISTS` as the
Mists identifier. Forever uses Mainline UI frames despite its Classic version
number, so `OnEnable()` sets both `retail` and `lightWeightMode` for it and Retail.
ElvUI also enables lightweight mode. See `docs/classic-beta.md` for beta details.

## Source map

- `ScarletUI.lua`: addon initialization, setup dispatcher, events, popups, commands.
- `Modules/Database.lua`: AceDB defaults and reset behavior.
- `Modules/Options.lua`: AceConfig settings pages.
- `Modules/Helpers.lua`: client detection and shared helpers.
- `Modules/EditModeLayouts.lua`: shared frame definitions and display presets.
- `Modules/EditMode.lua`: Edit Mode detection, profile installation, activation,
  update prompts, and settings page through LibEditModeOverride.
- `Modules/Chat.lua`: chat tabs and font size.
- `Modules/CVars.lua`: native console variable discovery and overrides.
- `Modules/ItemLevel.lua`: character, inspect, and Blizzard bag/bank item levels.
- `Modules/RaidFrames.lua`: legacy party/raid profile settings and position sync;
  setup is skipped when Edit Mode or lightweight mode is enabled.
- `Modules/TidyIcons.lua`: icon adjustments.
- `embeds.xml`: bundled library loading; `.pkgmeta`: CurseForge packaging and
  external Ace3, LibStub, serialization, and LibEditModeOverride dependencies.

The actionbar, custom bag/bank, movers, unit-frame, and nameplate modules have
been removed. Blizzard handles those frames. Keep native bag/bank
item-level overlays and the independent CVar controls when changing related code.

## Edit Mode and saved settings

Frame positions and supported frame settings, including party and raid layout,
are managed through Blizzard Edit Mode. Check API availability with
`IsEditModeSupported()`; do not assume support from the client identifier alone.
Preserve combat guards around layout changes.

All clients use the same `STANDARD`, `COMPACT`, and `ULTRAWIDE` preset definitions.
There is no Era-specific imported layout or separate Retail preset. Variant
selection uses UIParent dimensions: aspect ratio at least 2.1 selects Ultrawide;
otherwise width at most 1500 selects Compact; other displays use Standard.

Layout schema version is currently 11. Existing saved layouts are not silently
replaced when definitions change. `/sui` > Edit Mode Profile > Update Profile
applies current defaults to the current display's ScarletUI profile and activates
it. A reload alone does not update that saved layout. Bump the schema version
when changing preset definitions so status and prompt metadata can track changes.
Choosing Keep Current sets `db.global.editMode.suppressPrompts`, disabling all
automatic Edit Mode install/switch prompts for the account on that client, across
characters, display variants, reloads, and schema updates. Manual profile actions
remain available in the Edit Mode Profile settings page.

`ScarletUIDB` stores addon settings through AceDB. `db.global` holds feature
settings, CVar overrides, and Edit Mode installation metadata keyed by client and
variant. `db.char.editMode` holds character prompt/display state. Blizzard stores
the actual Edit Mode layouts. Old removed-module keys may remain in saved data;
they must not be required or used by the current setup or options code.
Chat font size is applied per chat window with `FCF_SetChatWindowFontSize`.

## Development and checks

Run from the repository root with Lua 5.1:

```sh
lua tests/module-loading.lua
lua tests/bag-item-level.lua
```

The module-loading check also runs `tests/client-compatibility.lua`. These checks
cover client detection, remaining settings/setup, old saved settings, shared Edit
Mode presets, profile installation, chat, and native bag/bank item-level paths.
They use WoW API mocks; they do not prove in-game rendering or protected API
behavior. After changes, verify every TOC entry exists and run `git diff --check`.
Check login, `/sui`, `/sui move`, affected frames, and Lua errors in-game when possible.
No separate build or lint tool is configured.

Commands: `/sui` opens settings, `/sui move` opens Blizzard Edit Mode,
`/sui debug` toggles diagnostics, and `/sui help` lists commands.

## Local installations

The development checkout is `G:\World of Warcraft Addons\ScarletUI`.
Under `G:\World of Warcraft`, the `_classic_`, `_classic_era_`, `_retail_`, and
`_classic_beta_` clients have `Interface\AddOns\ScarletUI` junctions to it.
Edits reach those linked installs immediately; `/reload` loads changed Lua and
clears previously registered hooks. Restart after a fresh addon installation.
The `_anniversary_` addon directory is a separate copy. Verify link targets before
changing installation paths; do not assume every installation shares this checkout.

Keep changes scoped to the task, preserve unrelated work, and commit completed
changes. This Windows checkout can report unrelated executable-bit differences;
use `git -c core.fileMode=false` for task status/staging instead of changing the
repository configuration or staging unrelated files.
