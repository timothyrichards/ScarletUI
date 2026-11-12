# ScarletUI agent guide

ScarletUI is a Lua World of Warcraft addon built on Ace3. This guide describes
this checkout; the TOCs and source are authoritative when client versions change.

## Clients and loading

All manifests load the same addon files in the same order, except that Vanilla,
TBC, and Mists append `Modules\Bag.lua` and `Modules\Nameplates.lua`:

| Manifest | Client | Interface |
| --- | --- | --- |
| `ScarletUI-Mainline.toc` | Retail | 120100 |
| `ScarletUI-Camelot.toc` | Classic Forever beta | 16001 |
| `ScarletUI-Vanilla.toc` | Classic Era | 11509 |
| `ScarletUI-TBC.toc` | TBC Anniversary | 20506 |
| `ScarletUI-Mists.toc` | Mists Classic | 50504 |

Update every manifest when adding or removing a loaded module.
Keep `LoadSavedVariablesFirst: 1` in each manifest so saved settings are restored
before addon scripts initialize AceDB. Fully restart WoW after changing TOC metadata.
`GetWoWVersion()` in `Modules/Helpers.lua` returns a client identifier and interface
number. Identifiers for these targets are `RETAIL`, `FOREVER`, `VANILLA`, `TBC`, and `MOP`.
Era, Anniversary, and Mists keep the Classic UI (`retail` and `lightWeightMode` stay false)
while still using Edit Mode when `IsEditModeSupported()` passes. Use `MOP` for
Mists, not `MISTS`. Detection for other legacy clients (WOTLK, CATA) remains in
the code without manifests. Forever uses Mainline UI frames despite its Classic version
number, so `OnEnable()` sets both `retail` and `lightWeightMode` for it and Retail.
ElvUI also enables lightweight mode. See `docs/classic-beta.md` for beta details.

## Source map

- `ScarletUI.lua`: addon initialization, setup dispatcher, events, popups, commands.
- `Modules/Database.lua`: AceDB defaults and reset behavior.
- `Modules/Options.lua`: AceConfig settings pages. There is no central module
  list: each feature's enable toggle sits on its own page (Bags, Chat, Fishing, Stat Display,
  Nameplates, CVars, Action Bars, and the Minimap Tracking group on General)
  and is the first setting on that page; Bags leads with Custom Bag Frames,
  then Share Sorting Across Characters, and Action Bars with Hide Micro Menu
  Background, then Share Across Characters. AceConfig sorts negative `order` values last.
- `Modules/Helpers.lua`: client detection and shared helpers.
- `Modules/SettingsFrame.lua`: the settings window (`ScarletUISettings`) that
  `/sui`, the minimap icon, and the Esc menu button open. `/sui ace` and the
  Blizzard AddOns settings entry still open the AceConfig panel. Settings come
  from `ScarletUI:Options()`, so each is defined once (in AceConfig's table
  format), but navigation and layout are its own. `NAV` lists the left-hand
  pages under section headers, each page naming the option groups it shows by
  path; top-level pages missing from `NAV` are appended. `CollectSettings`
  flattens a group into rows: its own settings form one card and each child
  group another. Every setting is one row, name and the description's first
  sentence at the left (tooltip has the rest) and the control at the right.
  Every Features page has a master switch and a status light in the list:
  the group's own `enabled` toggle where that turns the whole page off, and
  otherwise (`master = true` in `NAV`: Interface, Item Level, Bags, Action Bars,
  Minimap Tracking, Auction Prices) an "Enable <page>" row. That one is not a module flag:
  `SetSettingsPageEnabled` turns off every toggle and OFF-able select on the
  page through its own setter and remembers what was on in
  `db.global.settingsMasters[page id]`, restoring it when switched back on.
  The CVar list's numbered label/input/Default/Remove options are drawn as one
  row per CVar. The search box filters settings across all pages. It is built
  from Blizzard templates (`PortraitFrameTemplate`, `InsetFrameTemplate`, the
  Settings slider and dropdown) so it takes each client's skin; atlas names
  are checked with `C_Texture.GetAtlasInfo` before use. Changes refresh it
  through `RefreshSettings`, which also listens to AceConfigRegistry
  `NotifyChange`. AceConfig rejects unknown option keys, so layout hints
  belong in `NAV`, not in the options table.
- `Modules/EditModeLayouts.lua`: shared frame definitions and display presets.
- `Modules/EditMode.lua`: Edit Mode detection, profile installation, activation,
  update prompts, and settings page through LibEditModeOverride.
- `Modules/ActionBars.lua`: shares the Settings > Action Bars 2-8 toggles
  across characters via `db.global.actionBarToggles`. These are per-character
  game settings (`GetActionBarToggles`), not CVars. Saved on logout only after
  the shared set was applied; applied on login, deferred until combat ends.
  Uses a new key; the removed module's `actionbarsModule` stays unused.
  Its Action Bars settings page picks which bars are shared; unchecked bars are
  stored in `ignored` and keep each character's own state.
- `Modules/BagSort.lua`: shares the `C_Container` Sort Bags Right to Left and
  Insert Items Left to Right settings via `db.global.bagSortModule`, saved by a
  post-hook on the `C_Container` setters, so a change from `/sui`, the bag menu,
  or another addon is shared (never read back from the client at logout, which
  could save a stale "off"), and applied on login. These are per-character game settings, not CVars.
  Era, TBC, and Mists only have the insert setting. Its toggles go on the Bags
  page: a standalone page on Retail and Forever, and a Sorting group on the
  `Bag.lua` page elsewhere.
- `Modules/Tracking.lua`: shares minimap tracking menu checkboxes across
  characters via `db.global.trackingModule.states`, keyed by entry name and
  merged on logout so entries a character lacks keep their shared state.
  `alwaysOn` (keyed by spell ID, Minimap Tracking group on the General page) turns Find
  Minerals and Find Herbs back on at login and on `PLAYER_ALIVE`/`PLAYER_UNGHOST`,
  since Classic rules drop tracking on death; it runs even with sharing off.
  Both default on. Each apply turns on one inactive entry, so on clients that
  track one spell at a time a 1s ticker (`SwitchTracking`) alternates the two
  every `switchInterval` seconds when a character knows both. The ticker skips
  combat, instances, resting, taxis, casts, loot, and minimap hover, and checks
  the spell cooldown, because a Classic tracking change is a cast on the GCD.
  The action bar and tracking sync modules save from AceDB `OnDatabaseShutdown` (before defaults are
  stripped), each with its own callback target so none replaces another.
- `Modules/GameMenu.lua`: optional Scarlet UI and Cooldown Manager buttons
  below the escape menu (`db.global.gameMenuButtons`, both off by default).
  They are `UIParent` frames shown through `GameMenuFrame:HookScript`; never call `AddButton` or
  parent frames into the menu's layout, which taints its Edit Mode, Log Out,
  and Exit Game buttons. Cooldown settings open with `ShowUIPanel`, which goes
  through Blizzard's secure panel code; buttons are disabled in combat.
- `Modules/FrameTweaks.lua`: hides `MicroMenu.BackgroundArt` and `BorderArt`
  (`db.global.hideMicroMenuArt`, on by default, Forever only, toggle on the
  Action Bars page), plus a temporary
  Forever hotfix that hides `GamepadBagBar` on the combined backpack while
  Gamepad UI is off. Blizzard's `GamepadBagBarMixin:OnLoad` skips hiding the bag
  buttons then; no event fires on toggle, so it rechecks on bag `OnShow`.
  Remove the hotfix once Blizzard fixes it.
  It also collapses inactive tracked buffs in the Cooldown Manager
  (`db.global.collapseInactiveBuffs`: `OFF`, `START`, or `END`; off by default,
  select in the Interface group). Blizzard hides an inactive buff item but keeps
  its slot; a post-hook on each buff viewer's `Layout` records the slot anchors,
  then shown items are re-anchored into the slots at one end, again on every
  item `OnShow`/`OnHide`. Keep its state in locals, never on Blizzard's frames.
- `Modules/Chat.lua`: chat tabs and font size. It reruns on every
  `UPDATE_FLOATING_CHAT_WINDOWS`, so don't call dock, tab, or edit-box functions
  (`FCFDock_SelectWindow`, voice transcription updates) there unless something
  changed: the taint spreads to the chat edit box, which `ChatFrameUtil.InsertLink`
  reads before Shift-clicking a map pin calls the protected `CopyToClipboard`.
- `Modules/CVars.lua`: native console variable discovery and overrides.
- `Modules/ItemLevel.lua`: character, inspect, and Blizzard bag/bank item levels.
  On Forever it also shows the average under the stats pane level text, since
  that client has none. Do not add rows to `PAPERDOLL_STATCATEGORIES`: it taints
  `CharacterFrame:OnShow`, which then fails on secret player health values.
- `Modules/CheapestItem.lua`: outlines the bag stack with the lowest total
  vendor value (sell price x count) on the Blizzard
  combined/individual bag frames and the `Bag.lua` frame
  (`db.global.highlightCheapestItem`, toggle on the Bags page). It reruns from
  the end of `BagItemLevel`, which already fires on every bag change and open.
  Unsellable items, consumables, and quest items (by class or quest info) are
  skipped, as are spell reagents (Reagent class), crafting reagents (Trade Goods
  class or the `GetItemInfo` `isCraftingReagent` flag), and profession tools: Retail's Profession class, fishing poles,
  and a hand-kept item ID list for Classic tools that have no class to match.
  Items saved in an Equipment Manager set are skipped by item ID; Era and TBC
  have no Equipment Manager, so `EQUIPMENT_SETS_CHANGED` is registered only
  when `C_EquipmentSet` exists.
- `Modules/TidyIcons.lua`: icon adjustments.
- `Modules/Tooltips.lua`: appends percent of max mana to GameTooltip spell cost
  lines via post-hooks only (`TooltipDataProcessor` or `OnTooltipSetSpell`).
  Item tooltips that list bundles as "- 20 Vision Dust" rows (Waylaid Crate)
  get each row's total cost from `Auctionator.API.v1` (vendor price, else
  auction) and the cheapest row in green (`db.global.crateFillCosts`, toggle on
  the Auction Prices page; without Auctionator the hook is not registered).
  Auctionator has no
  price-by-name API and the client only resolves names of items the character
  has handled, so names are indexed from the item IDs in
  `Auctionator.Database.db` (internal, guarded); names not loaded yet are
  picked up on a later hover.
- `Modules/CraftProfit.lua`: Craft Profit (`db.global.craftProfit`), Forever
  only and only with Auctionator. Lists the recipes that make a profit, or break
  even while still giving a skill-up, as a side tab on `ProfessionsFrame` (a
  page covering the native one plus a copy of the selected native tab to switch
  back, as WhatsTraining does) and in a pop-up window (`/cp`, `/craftprofit`).
  Recipe data only exists while a profession window is open, so scans are cached
  per character in `db.char.craftProfit.professions`. The pricing rules
  (`ScarletUI.CraftProfit.Evaluate`, `Keep`, `Money`) call no WoW API so the
  tests can run them; nothing else runs before `SetupCraftProfit`. It was a
  standalone addon; setup yields when that addon's `CraftProfit_Toggle` exists.
  Its toggle and the crate fill cost toggle share the Auction Prices settings
  page (`auctionSettings`, `master = true` in `NAV`). Without Auctionator the
  page's group is `disabled`, so every row and the master switch gray out, and
  each description is replaced by a note to install Auctionator and scan the
  auction house.
- `Modules/ZoneLevels.lua`: appends difficulty-colored level ranges to the world
  map zone hover label on Era, TBC, and Forever, whose `C_Map.GetMapLevels` has
  no data. Uses a table of Classic UIMapIDs and post-hooks the area label's
  `SetLabel`; labels that already contain a color code (native or Leatrix Maps)
  are left alone. Retail and Mists show levels natively and skip setup.
- `Modules/FiveSecondRule.lua`: after the player casts a spell that costs mana, a
  line crosses the player frame mana bar for 5 seconds until spirit regeneration
  resumes (`db.global.fiveSecondRule`, Interface group on the General page).
  Classic Era and Forever only. Forever returns `UnitPower` mana as a secret value,
  so casts come from the player's `UNIT_SPELLCAST_SUCCEEDED` (not secret for the
  player) and `GetSpellPowerCost`, never from mana changes. Hidden while the bar
  shows rage or energy.
- `Modules/Fishing.lua`: fishing mode (`db.global.fishingModule`, its own
  Fishing settings page), every client but Retail. While a fishing pole is in the
  main hand, a priority override binding puts the fishing key (Space by default)
  on a secure macro button that casts Fishing; for the length of the Fishing
  channel the key is `INTERACTTARGET` instead and the soft-target interact CVars
  are widened, then restored, so it hooks the bobber. The button's `PreClick`
  picks the macro text: with `autoLure` and no main-hand enchant it uses a lure
  from a hand-kept item ID list on the pole first. Bindings and CVars only
  change out of combat; the key is released in `PLAYER_REGEN_DISABLED`, which
  fires before the lockdown, and while moving. `ScarletUIFishingBar` shows while
  the mode is on and a pole is equipped: the Fishing icon (drag handle, position
  in `position`, Ctrl-click resets it) and the lure the key applies, which opens a list of the lures
  in the bags stacked upward, topped by a no-lure entry drawn as an empty slot.
  The open list closes itself after a second with the mouse off the lures.
  Clicking a list entry stores `lure` (an item ID, or 0 for no lure); the key
  applies a picked lure while the bags hold it and the best lure otherwise. The bar
  is plain frames with no secure children, so it can change in combat. It is a
  panel sized to its contents and drawn with Blizzard art so it matches each
  client (`DialogBorderDarkTemplate`, item slot borders, the title font's gold;
  no custom colors or backdrops): "Scarlet UI" above the icons and, beside
  them, the Fishing skill and its cap, from
  `C_SkillInfo.GetSkillLineInfoByID(356)` on Forever, `GetProfessions` on Mists,
  and the `GetSkillLineInfo` rows on Era and TBC (blank while that header is
  collapsed), refreshed on `SKILL_LINES_CHANGED`. When the rank rises, the gain
  ("+1") drifts up from above the rank number and fades.
- `Modules/XPFood.lua`: XP food reminder (`db.global.xpFoodModule`, toggle in
  the Interface group on the General page), Forever only. Cooked food there
  also applies Well Fed XP Boost (spell 1243969, 5% more experience from kills).
  That aura is hidden from addons, so the buff is read from the 14 visible
  Well Fed spells the foods trigger (`WELL_FED`).
  While the player has none of them and the bags hold a listed food whose
  required level they meet, `ScarletUIXPFood` shows one, styled like the
  fishing lure (stack count, draggable, position in `position`, Ctrl-click
  resets it). Right-click eats it; left-click opens a list of the usable foods
  stacked upward, which closes after a second with the mouse off it. Clicking
  an entry stores `food` (an item ID); the icon shows a picked food while the
  bags hold it and the highest-level one otherwise. The item ID list is
  hand-kept from forever.wowhead.com. The icon is a `SecureActionButtonTemplate`
  button from `ScarletUI:CreateIconButton` (Helpers, shared with the fishing
  bar) whose `type2` macro is `/use item:ID`. Its `OnClick` belongs to the
  template, so our clicks are read in `PostClick`. It hides in
  `PLAYER_REGEN_DISABLED`, before the lockdown, and nothing on it is shown,
  hidden, moved, or given attributes until combat ends. It is also hidden at
  max level and while dead or a ghost. Eating a food from the bags (the
  player's `UNIT_SPELLCAST_SUCCEEDED` matching its `GetItemSpell`) covers the
  icon with a plain child frame: the Well Fed icon counting down the 10
  seconds to the buff. The
  use spell's aura is hidden, so a meal cut short is read from the ordinary
  Food or Drink aura, looked up by name, having been seen and gone.
- `Modules/StatDisplay.lua`: stat display (`db.global.statDisplay`, off by
  default, its own Stat Display settings page), every client but Retail. It
  lists the stats of up to three roles, melee, ranged, and caster (`SETS`),
  each drawn like the fishing bar. Roles are switched per character
  (`db.char.statDisplay.roles`; one never switched follows the class). `layout`
  is `COMBINED`, one `ScarletUIStatDisplay` panel holding the shown roles, or
  `SPLIT`, a bordered panel per role (`ScarletUIStatDisplayMelee` and so on).
  `orientation` arranges the roles in the one panel: `HORIZONTAL`, side by
  side, or `VERTICAL`, one above another and all as wide as the widest.
  Separate panels ignore it. A role's icon is the handle: drag moves the one panel
  (`position`) or that role's own (`positions[role]`), Ctrl-click resets it.
  `PlaceStatDisplay` applies layout and positions; the refresh must not, or it
  would pull a panel back mid-drag. Each stat function runs in `pcall` and
  returns its text or nil, so a function a client lacks drops that row instead
  of erroring. Forever makes these stats secret in combat. Single values (crit,
  attack speed) are formatted into secret strings and shown live; stats that
  need arithmetic or comparison (attack power, hit, spell stats) keep their
  last readable text. Secret text is never measured or put in the feed.
  Refreshed by a half-second `OnUpdate` poll while on, not by events. The same
  stats are published as the LibDataBroker feed "ScarletUI Stats", created the
  first time the display is on so broker displays do not list it otherwise.
- `Modules/Bag.lua`, `Modules/Nameplates.lua`: custom bag/bank frames and
  nameplate threat colors, auras, and text. Classic UI clients only: listed in
  just those three manifests so Retail and Forever never load them. Each file adds its
  own AceDB defaults (`bagModule`, `nameplatesModule`, `char.priorityDebuffs`)
  and settings page; the parent checks `self.SetupBags`, `self.SetupNameplates`,
  and the `Get*SettingsPage` methods before using them.
- `embeds.xml`: bundled library loading; `.pkgmeta`: CurseForge packaging and
  external Ace3, LibStub, serialization, and LibEditModeOverride dependencies.

The actionbar, movers, unit-frame, and raid-frame modules have been removed.
Blizzard handles those frames, and bags and nameplates on Retail and Forever. Keep native bag/bank
item-level overlays and the independent CVar controls when changing related code.

Raid display CVars are managed by `Modules/CVars.lua` with defaults in
`Modules/Database.lua`. Power bars, class colors, debuffs, dispellable-only
debuffs, percentage health text, and disabled main-tank/assist frames retain the
old shared preset values. Pet visibility keeps the current client setting because
the old Party and Raid presets disagreed. `knownCVars` lists only CVars that exist
on at least one active client. Removed ones include `useCompactPartyFrames`, the old
nameplate scale and motion CVars, and the unsuffixed floating combat text CVars
(now `_v2`).

## Edit Mode and saved settings

Frame positions and supported frame settings, including party and raid layout,
are managed through Blizzard Edit Mode. Check API availability with
`IsEditModeSupported()`; do not assume support from the client identifier alone.
Preserve combat guards around layout changes.

All clients use the same `STANDARD`, `COMPACT`, and `ULTRAWIDE` preset definitions.
There is no Era-specific imported layout or separate Retail preset. Variant
selection uses UIParent dimensions: aspect ratio at least 2.1 selects Ultrawide;
otherwise width at most 1500 selects Compact; other displays use Standard.

Layout schema version is currently 19. Existing saved layouts are not silently
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

Fresh installs start with CVars disabled and offer an Enable / Leave Disabled
dialog. Enabling applies overrides, then shows a Got It notice explaining how
to restore originals: `/sui` > CVars > turn off Enable CVar Overrides.
Acknowledging the notice keeps CVars enabled and retains the saved snapshot.
Choices persist across reloads; an unacknowledged notice returns after login.
Enabling from settings uses the same flow. Existing installations retain their
previous enabled state, including old AceDB saves that omitted the former `true`
default. `CVarModule.onboarding` tracks
`offer`, `review`, or `done`; initialize it before AceDB applies defaults.

Shared settings are synced, not enforced. A change the player or another addon
makes to a shared setting (CVars, bag sort, action bar toggles, tracking) becomes
the shared value and reaches the other characters at their next login; Scarlet UI
must not put its older value back. A character's values only count as changes
after it has received the shared ones that session, so a skipped apply (combat,
a failed write) cannot replace them.

CVar overrides are shared. `AdoptCVarChanges` compares each CVar with what this
session wrote; one that differs becomes the override. It runs on `CVAR_UPDATE`,
before each apply, and from `OnDatabaseShutdown`. Before applying an override or adding a custom CVar,
original values are saved in `db.char.cvarOriginalValues` for character CVars and
`db.global.CVarModule.originalValues` for shared CVars, using the storage flags
from `GetCVarInfo`. Clients without that API use character backups.
Disabling restores originals and retains overrides for re-enabling; other
characters restore on their next login. Clearing an input or removing a CVar
restores its original and saves a `false` override to prevent AceDB defaults or
auto-discovery from enabling it again. Default applies the Blizzard default as
an override, retaining the original backup. Successful restoration releases the
backup; a later override captures a fresh baseline. Failed or unavailable restores
keep the backup for retry. Resetting addon preferences preserves pending backups.
Existing installs can only snapshot their current values, not pre-addon values
that were never saved. CVar changes and restores are blocked during combat.

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

Commands: `/sui` opens settings, `/sui ace` opens the old AceConfig panel,
`/sui move` opens Blizzard Edit Mode,
`/sui debug` toggles diagnostics, and `/sui help` lists commands.

## Local installations

The development checkout is `G:\World of Warcraft Addons\ScarletUI`.
Under `G:\World of Warcraft`, the `_retail_`, `_classic_` (Mists), `_classic_era_`,
`_anniversary_` (TBC), `_forever_`, and `_classic_beta_` (Forever beta) clients have
`Interface\AddOns\ScarletUI` junctions to it.
Edits reach those linked installs immediately; `/reload` loads changed Lua and
clears previously registered hooks. Restart after a fresh addon installation.
Verify link targets before changing installation paths; a client added later
may not have a junction yet.

Keep changes scoped to the task, preserve unrelated work, and commit completed
changes. This Windows checkout can report unrelated executable-bit differences;
use `git -c core.fileMode=false` for task status/staging instead of changing the
repository configuration or staging unrelated files.
