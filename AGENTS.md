# ScarletUI agent guide

ScarletUI is a Lua World of Warcraft addon built on Ace3. This guide describes
this checkout; the TOCs and source are authoritative when client versions change.

## Clients and loading

All manifests load the same addon files in the same order, except that Vanilla,
TBC, and Mists append `Modules\Bag.lua` and `Modules\Nameplates.lua`, and Forever
appends only `Modules\Nameplates.lua`:

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
  It also records playtime: `RequestTimePlayed()` at `PLAYER_LOGIN` (which
  prints Blizzard's two /played chat lines) and each `TIME_PLAYED_MSG` total
  saved in `db.global.playtime[db.keys.char]`, topped up at logout. AceDB's
  character key is used because Forever characters share first names. The first
  version's `db.global.played` ("Name-Realm" keys) is moved over on the next
  login, or dropped on Forever. The class token (`PALADIN`) goes in
  `db.global.playtimeClasses` under the same key, so the totals stay plain
  numbers. No toggle and no AceDB default. `python tools/playtime.py` sums it
  across every client's SavedVariables, per character and per class; `tools`
  is not packaged.
- `Modules/Database.lua`: AceDB defaults and reset behavior.
- `Modules/Options.lua`: AceConfig settings pages. There is no central module
  list: each feature's enable toggle sits on its own page (Bags, Chat, Fishing, Reminders, Stat Display,
  Nameplates, CVars, Action Bars, and the Minimap Tracking group on General)
  and is the first setting on that page; Bags leads with Custom Bag Frames,
  then Share Sorting Across Characters, and Action Bars with Hide Micro Menu
  Background, then Share Across Characters. AceConfig sorts negative `order` values last.
  The Transmog page (`GetTransmogSettingsPage`, Retail and Forever) has no
  switch or saved settings: a toggle per outfit from
  `C_TransmogOutfitInfo.GetOutfitsInfo`, read on every `Options()` call.
  Switching is protected (`ClearOutfit` is `ADDON_ACTION_FORBIDDEN`), so each
  option's `arg.secure` holds attributes for Blizzard's `outfit` secure action
  (`type`, `outfit-index`; the default action toggles), and the settings window
  covers that toggle's row with a `SecureActionButtonTemplate` overlay. Overlays
  attach only out of combat and come off in `PLAYER_REGEN_DISABLED`, so the
  window holds no protected frame in combat; the rows are disabled then. The old
  AceConfig panel cannot switch. The window refreshes on
  `TRANSMOG_DISPLAYED_OUTFIT_CHANGED` and `TRANSMOG_OUTFITS_CHANGED`.
- `Modules/Helpers.lua`: client detection and shared helpers.
- `Modules/SettingsFrame.lua`: the settings window (`ScarletUISettings`) that
  `/sui`, the minimap icon, and the Esc menu button open. The Blizzard AddOns
  settings entry still shows the AceConfig panel. Settings come
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
  Minimap Tracking, Reminders, Auction Prices) an "Enable <page>" row. That one is not a module flag:
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
  Frame candidates may be dotted paths to child frames without a global name,
  such as Forever's gryphon end caps (`MainActionBar.EndCaps.LeftEndCap`),
  which the presets hide.
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
- `Modules/BankCache.lua`: cached bank and character viewer (`db.global.bankCacheModule`:
  `enabled` and `tooltip`, both on by default, its own Characters settings page). The client only
  shows bank contents while the bank is open, so a snapshot (items in bank order
  as link, count, and icon; `counts` per item ID; `size`; `time`; AceDB `realm`
  key; class) is saved in `db.global.bankCache[db.keys.char]` on
  `BANKFRAME_OPENED` and on `BAG_UPDATE`, `PLAYERBANKSLOTS_CHANGED`, and
  `BANK_TABS_CHANGED` while it is open, debounced 0.2s. A read with no slots
  (tabs still loading, or a Warband-only banker: `C_Bank.CanViewBank`) saves
  nothing. Retail and Forever read the purchased character bank tabs
  (`C_Bank.FetchPurchasedBankTabIDs`; Forever's tabs are bank bags, and it has
  no -1 bank container: -1 is its keyring); Era, TBC, and Mists the -1 bank
  container and bags `NUM_BAG_SLOTS + 1` to `NUM_BAG_SLOTS + NUM_BANKBAGSLOTS`,
  plus the reagent bank where `IsReagentBankUnlocked` exists (no current
  client). The Warband/account bank is not saved.
  A character summary goes in `db.global.characterCache[db.keys.char]` (no AceDB
  default, so the logout strip leaves it alone): `class`, `className`, `faction`, `level`,
  `money`, `zone` (`GetRealZoneText`), `xp`, `xpMax`, `rested` (`GetXPExhaustion() or 0`),
  `resting`, `maxLevel` (`ScarletUI.XPDisabled`, shared with `XPPerHour.lua`), `realm`, `time` (last seen), and
  `bags` (`{ items, counts, size }`, as the bank). It is saved on `PLAYER_ENTERING_WORLD`,
  `BAG_UPDATE` (bank open or not), `PLAYER_MONEY`, `PLAYER_XP_UPDATE`, `UPDATE_EXHAUSTION`,
  `PLAYER_UPDATE_RESTING`, `PLAYER_LEVEL_UP`, and `ZONE_CHANGED_NEW_AREA`, debounced 0.2s on
  its own timer, and at once on `PLAYER_LOGOUT` (no timer runs then). A secret value
  (`issecretvalue`, Forever) or an empty zone keeps the saved one; bags that read as no
  slots keep the saved bags. `BankCache.BagContainers` is bags 0 to `NUM_BAG_SLOTS`, plus
  `Enum.BagIndex.ReagentBag` only on bank-tab clients and only when it is not a tab: on
  Era, TBC, and Mists bag `NUM_BAG_SLOTS + 1` is a bank bag. The keyring is not read.
  Rested XP (`BankCache.Rested`) shows as a percent of the saved level, projected from
  logout at 5% of the level per 8 hours resting, a quarter of that outside, capped at
  150% without lowering a saved value above it; none online or at max level. Forever's
  rate is assumed to be Classic's.
  `/sui bank`, `/sui chars`, and the page's button open `ScarletUIBank` ("Scarlet UI
  Characters"; the bags' `PortraitFrameTemplate` and plain `CreateIconButton` slots, since
  Forever lacks `ItemButtonTemplate`). Its bottom right is anchored to the open backpack's
  bottom left, and a drag holds until the backpack opens again. The dropdown lists the
  characters of every realm on the client (on Forever, the ruleset), this realm first and
  then by realm name, each name with its level. With several realms, each realm gets a menu
  title with its gold. "Account: X" on the dropdown row sums every listed character's
  gold. Under the dropdown, two lines show the chosen character's level, class (class
  coloured), zone, and "Online" or "Last seen 3h ago", then its gold and rested XP
  ("Rested 45% (+12% since logout, resting)"). The grid shows a "Bags" group, then a "Bank"
  group headed with its age; each says so when nothing is saved. Characters saved before the
  summary existed show their bank only. Its slots look like bag slots (`BankCache.Decorate`):
  item level per the bags' `itemLevelBag` setting (`ScarletUI.ItemLevelText`, from
  `ItemLevel.lua`), a quality border from Common up, and junk greyed with a coin. Item tooltips get "Bank: N" and
  "Bank (Name): N" lines from a `TooltipDataProcessor` post-call, or
  `OnTooltipSetItem` on older clients; those stay on this realm's banks. The dropdown starts
  with "All characters": every character under a name header with level, gold, and last
  seen, then its non-empty Bags and Bank groups. With several realms, each realm's characters
  go under a realm header with its gold. In that mode the slot tooltip shows the viewer's own
  "Bags: Name xN" and "Bank: Name xN (age)" lines per character instead of the hook's, naming
  the realm for other realms. The search dims non-matches in every shown group. The choice is
  kept in `bankCacheModule.viewerChoice`. Ages show as "Updated 3h ago" (`BankCache.Age`),
  not dates. Snapshots record `faction` (`UnitFactionGroup`), shown as a `PlusManz-Horde`/
  `-Alliance` icon before the name (none for older saves). The viewer closes when the
  backpack frames hide (checked a tick later, so a swap of frames keeps it). Reset Defaults
  (`db:ResetDB()`) wipes both caches. The rules (`ScarletUI.BankCache`) are
  tested in `tests/bank-cache.lua`, run by the module-loading check.
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
  On Forever, for hunters, it shades the end of Blizzard's ranged swing timer
  (`SwingTimerRangedFrame.StatusBar`, our own texture) with Auto Shot's 0.5s
  windup, when moving cancels the shot (`db.global.autoShotClip`, on by
  default, toggle on the Edit Mode Profile page). Its width is
  `ScarletUI.AutoShotClip(swing, haste)` of the bar: the windup shortened by
  `GetRangedHaste` (assumed, unchecked in game) over the ranged swing from
  `PLAYER_SWING` or `UnitAttackSpeed`. Tested in `tests/auto-shot-clip.lua`. The saved
  setting was first `autoShotDeadzone`; `OnInitialize` moves it over.
  For hunters it also tints that bar red with a "Dead zone" label (our own frame
  on `SwingTimerRangedFrame`, so the bar's out-of-range dimming doesn't fade it)
  while the hostile target is out of melee but inside Auto Shot's 8 yd minimum
  (`db.global.hunterDeadZone`, on by default, toggle on the Edit Mode Profile
  page). `ScarletUI.TargetInDeadZone()` needs melee out of range
  (`C_SwingTimer.IsTargetWithinSwingRange(0)`, or Raptor Strike's range with no
  melee weapon), Auto Shot (75) out of range, and `CheckInteractDistance(target, 2)`
  (trade, 8-11 yd) true, since Auto Shot also reads out of range past 35 yd. Nil
  or secret readings never count. Retail re-allowed that check on enemies in
  combat (2023-12-11 hotfix); if Forever blocks it, the first `ADDON_ACTION_BLOCKED`
  naming it stops in-combat calls. A 0.1s `OnUpdate` runs only while the target is
  attackable (`PLAYER_TARGET_CHANGED`, `UNIT_FACTION`). Tested in
  `tests/hunter-dead-zone.lua`.
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
  when `C_EquipmentSet` exists. Players exclude items by ID in
  `db.global.cheapestItemExclusions` (`ExcludeCheapestItem` takes a link, ID, or
  cached name): the Exclude Item input under the toggle (`arg.items`) and an Excluded
  Items group of Remove buttons (`arg.button` labels an execute row's button).
  Alt+left-click (no Ctrl or Shift, whose default item clicks still fire) on a bag item (`ToggleCheapestItem`) excludes it, or brings it
  back if it already is, while the highlight is on: an `OnClick` `HookScript` added
  to each button the first time `UpdateCheapestItem` outlines or clears it (Blizzard
  frames and `Bag.lua` slots), so the button's own click runs first and untainted.
  The chord was picked because Blizzard binds Shift, Ctrl, and Alt alone, and add-ons
  favour Alt and right-click. Every exclude or undo prints a chat line and calls
  `NotifyChange`. The highlighted item's `GameTooltip` (owner has a shown
  `cheapestGlow`) gets a grey "Alt+Click" hint, from a `TooltipDataProcessor`
  post-call or `OnTooltipSetItem`. In the settings window an `arg.items` input adds
  an item dropped on it, or one Shift-clicked while it has focus: post-hooks on
  `HandleModifiedItemClick` (with `IsModifiedClick("CHATLINK")`),
  `ChatFrameUtil.InsertLink`, and `ChatEdit_InsertLink`, which on current clients is a
  copy of the other taken before any hook, so add-ons calling it bypass that hook. The
  first hook to take a click clears focus, so the others skip it.
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
  Craftsman's Writ tooltips (Forever) get the reputation the writ gives (+10%,
  rounded down, for Humans' Diplomacy; assumed, unchecked in game), what its
  requested items cost by the same name lookup (reputation line in the
  `COMBAT_FACTION_CHANGE` chat color, light blue fallback; item name in its
  quality color, white until cached) (`db.global.writInfo`, on by default, toggle on the Auction Prices
  page). The writs come from `Modules/Writs.lua`.
- `Modules/Writs.lua`: `ScarletUI.WRITS`, the 150 Craftsman's Writs by item ID
  (tier, requested item, count) and `WRIT_REPUTATION` per tier (75/125/200),
  with its sources and their dates in the header. Requested items are only
  readable in game once the writ's quest is accepted, so the table is the only
  source. Regenerate it from Wowhead's Forever tooltip data
  (`nether.wowhead.com/forever/tooltip/item/<id>` and `.../quest/<id>`).
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
- `Modules/QuestXPBar.lua`: draws in gold the part of the experience bar that
  turning in every completed quest in the log would fill, clamped to the end of
  the bar (`db.global.questXPBar`, Interface group on the General page). The
  texture sits on the `StatusBar` of each `isExpBar` frame in
  `StatusTrackingBarManager.barContainers`, anchored to the fill texture. Set up
  wherever `GetQuestLogRewardXP` exists; Blizzard's Era and TBC quest log shows
  no XP reward, and whether the function returns any there is unverified.
- `Modules/XPPerHour.lua`: a readout above `StatusTrackingBarManager` ("12.4k
  xp/hr  TTL 1h 12m", `db.global.xpPerHour`, default on, Interface group on the
  General page and `/sui xp`). Session average (XP since login or reset over
  elapsed time, divisor floored at 60 s), chosen over a rolling window because
  kill-sized XP lumps make a window jump. `PLAYER_XP_UPDATE` deltas; a drop in XP
  is a level-up and adds back the previous level's max. Hidden at max level, with
  XP disabled, and before the first XP. Hover shows session details, right-click
  resets. Skips updates when `UnitXP` is a secret value.
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
- `Modules/Reminders.lua`: reminder icons, each with its toggle on the
  Reminders settings page (`remindersSettings`, `master = true` in `NAV`). A
  reminder shows an item from the bags while its buff is missing.
  `CreateReminder(spec)` builds one, styled like the fishing lure (stack count)
  and placed on the shared `ScarletUIReminders` bar: shown icons sit side by
  side in setup order, dragging any icon moves the bar (position in
  `db.global.remindersPosition`, taken over once from the food icon's old
  `xpFoodModule.position`), and Ctrl-click resets it.
  right-click uses the item; left-click opens a list of the usable items
  stacked upward, which closes after a second with the mouse off it. The spec's
  `Find` returns the usable items, the one to show, and the macro that uses it;
  `FindItems` scans the bags and puts a picked item first while the bags hold
  it, the highest required level otherwise. The icon is a
  `SecureActionButtonTemplate` button from `ScarletUI:CreateIconButton`
  (Helpers, shared with the fishing bar) whose `type2` is that macro. Its
  `OnClick` belongs to the template, so our clicks are read in `PostClick`. It
  hides in `PLAYER_REGEN_DISABLED`, before the lockdown, and nothing on it is
  shown, hidden, moved, or given attributes until combat ends. It is also
  hidden while dead or a ghost. Add a reminder as another spec with its own
  settings table, frame name, and toggle.
  - Food buff (`db.global.xpFoodModule`, `ScarletUIXPFood`, `SetupXPFood`: the
    names are from when it was Forever's XP food reminder, kept for saved
    settings), every client. Shown while the player is not Well Fed and the bags
    hold a buff food whose required level they meet; the macro is
    `/use item:ID` and the pick is stored in `food`. A buff food is a
    consumable whose use spell's text (`GetSpellDescription`) contains the name
    of Well Fed (spell 19705), lowercased, which fits English wording; the
    answer is cached per item once the text has loaded. The buff is any aura
    with that name. Forever is also covered by two lists hand-kept from
    forever.wowhead.com, since its cooked food applies Well Fed XP Boost (spell
    1243969, 5% more experience from kills) through a hidden aura: `FOODS`
    (item ID = required level) and the 14 visible Well Fed spells the foods
    trigger (`WELL_FED`). Eating a food from the bags (the player's
    `UNIT_SPELLCAST_SUCCEEDED` matching its `GetItemSpell`) covers the icon
    with a plain child frame: the Well Fed icon counting down the 10 seconds to
    the buff. The use spell's aura is hidden, so a meal cut short is read from
    the ordinary Food or Drink aura, looked up by name, having been seen and
    gone.
  - Weapon enhancements (`db.global.weaponReminderModule`,
    `ScarletUIWeaponReminder`), Era, TBC, and Forever. Shown for the main hand,
    then the off hand, when it holds a weapon `GetWeaponEnchantInfo` reports no
    temporary enchant on and the bags hold an item from `ENHANCEMENTS` that
    fits: sharpening stones on axes, swords, polearms, and daggers, weightstones
    on maces, staves, and fist weapons, oils on any weapon but a fishing pole,
    poisons likewise but only for rogues. The macro is `/use item:ID` then
    `/use 16` or `/use 17`; the pick is stored per hand in `items[slot]`. The
    required level comes from `GetItemInfo`. A `C_Timer` rechecks when the
    soonest enchant runs out, since no event is known to fire then. The item
    IDs and the fist weapon rule are hand-kept from memory, not checked against
    a database; fishing lures are left to `Fishing.lua`.
  - Camp items (`db.global.campReminderModule`, `SetupCampReminders`), Forever
    only. A second page of the bar: one icon per profession in `CAMP`
    (`ScarletUICampCooking` and so on), shown while the bags hold one of its
    campfire kits (Cooking) or camp items, highest tier first, picked per
    profession in `items[label]`; no buff is checked. A plain button,
    `ScarletUIRemindersPage`, leads the bar while any icon on either page has
    something to show and flips `db.global.remindersPage` (nil or `camp`);
    with the toggle off the bar stays on the buffs. Icons record
    `active` in `Update` and `LayOutBar` shows the ones on the current page.
    The item IDs come from fan sites and cover the kits, each profession's
    skill 20 item, the Alchemy Laboratory, and the Tanning Rack only.
- `Modules/SpecGearSets.lua`: gear set per talent specialization, Forever only.
  `ScarletUISpecGearSet`, a dropdown at the left of the talent window's header
  row, lists the Equipment Manager sets; the set picked for the Primary or
  Secondary tab being viewed is equipped on `ACTIVE_TALENT_GROUP_CHANGED` when
  that spec group becomes active, after combat if need be. Stored by set name
  in `db.char.specGearSets[spec group]`, since set IDs are reused after a
  delete; a missing name counts as no set. `C_EquipmentSet.AssignSpecToEquipmentSet`
  is for Retail specializations, not spec groups, and is not used. The dropdown
  is a child of `PlayerSpellsFrame.TalentsFrame.ActiveSpec`, so Blizzard hides
  it without dual specialization and while inspecting, and it redraws from a
  post-hook on that frame's `Refresh`: the tab buttons call a closure over
  `SetTab`, so a hook on `SetTab` misses clicks. No settings toggle; "No Gear
  Set" is off. `Blizzard_PlayerSpells` loads on demand.
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
- `Modules/Gimmicks.lua`: just-for-fun shows (`db.global.gimmicks`), each off
  by default with its toggle on the Gimmicks page (`gimmicksSettings`,
  `master = true` in `NAV`), and one `sound` toggle for all. Nothing is built
  until a gimmick is turned on. Sounds are `Sounds\*.ogg`, made by
  `python tools/make-sounds.py` (numpy, ffmpeg); new files need a full restart.
  - Seal Slots (`sealSlots`, `ScarletUISealSlots`, `/sealslots`), Forever
    only: a three-reel slot machine for the Unsealed Wrath stacks a seal twist
    spends, shown only while it spins, at a fixed spot below the screen's
    centre. It was the standalone SealSlots addon; while that addon is loaded
    this one stays out and copies its best spins once, and its
    switch still shows: turning it on disables that addon for every character
    from the next reload. Forever
    closes the combat log and hides the Echo buffs in combat, so the stacks are
    counted from seal casts and `PLAYER_SWING`, the reels land on the target's
    `UNIT_COMBAT` holy hits and misses, and out of combat the buffs resync the
    count. The rules (`ScarletUI.Gimmicks.SealSlots`) call no WoW API so the
    tests run them. While on it logs what the client shows to `sealSlots.log`
    (last 3000 lines) for tuning detection.
  - Windfury (`windfury`, `ScarletUIWindfury`, `/windfury`), every client:
    "WINDFURY!" slams in with the extra attacks' damage, counting on for chained
    procs. Era, TBC, and Mists read the combat log
    (`ScarletUI.Gimmicks.WindfuryEvent`: `SPELL_EXTRA_ATTACKS` from a Windfury
    spell and the main-hand swings it owes, or Windfury Attack hits). Forever
    and Retail take a `UNIT_SPELLCAST_SUCCEEDED` of a Windfury spell the player
    does not know, unverified, and show no damage.
- `Modules/Bag.lua`, `Modules/Nameplates.lua`: custom bag/bank frames and
  nameplate threat colors, auras, and text. Retail never loads either. Bag.lua is
  in the Vanilla, TBC, and Mists manifests only; Nameplates.lua is also in the
  Forever manifest. Each file adds its
  own AceDB defaults (`bagModule`, `nameplatesModule`, `char.priorityDebuffs`)
  and settings page; the parent checks `self.SetupBags`, `self.SetupNameplates`,
  and the `Get*SettingsPage` methods before using them.
  On Forever (`ThreatOnly()` in Nameplates.lua) only the threat amount text and
  threat colors run: `NAME_PLATE_UNIT_ADDED`/`REMOVED` and `UNIT_THREAT_LIST_UPDATE`.
  No Classic health colors, auras, target arrows, or health/cast text. Blizzard's
  own `CompactUnitFrame_UpdateHealthColor` colors enemy plates by
  `UnitThreatSituation` (DPS/healer) or `UnitThreatLeadSituation` (tank,
  `PlayerUtil.IsPlayerEffectivelyTank`) when `frame.displayThreatHealthBarColor`
  (the `nameplateThreatDisplay` CVar's HealthBarColor bit) is set, from a local
  table of the global `NO/GAINING/HIGH_THREAT_COLOR` objects. Don't write those
  objects or call Blizzard's function from add-on code: it would run tainted and
  error on the secret threat state. Instead a `hooksecurefunc` post-hook
  (`ApplyForeverThreatColor`, also run on each threat refresh) repaints the bar
  with `nonTankThreatColors`/`tankThreatColors` (noThreat, lowThreat, threat
  only; states 1 and 2 share lowThreat as in Blizzard), and keeps Blizzard's color
  when the state is secret, nil, or solo. A tank's lead 0 also means no threat, so
  it only counts as a safe lead while `UnitThreatSituation` is 3. On
  `colorHealthWithExtendedColors` plates the `selectionHighlight` gets the color too.
  When the player's own `UnitThreatSituation` is readable and below 2, a group pet
  or another tank (role, Main Tank/Assist, or Tank Names) whose own readable
  situation is 2 or 3 gets the `pet`/`tank` color (`OtherAggroKey`); secrecy is
  per unit and mob (`C_Secrets.ShouldUnitThreatStateBeSecret(unit, mob)`), so a
  secret answer just counts as no. The settings page keeps the switch, the
  Threat Text group, and Threat Colors with all five pickers per role, Tank
  Names, and Reset Colors. The number takes the health bar color. Forever pools
  nameplate UnitFrames, so `AnchorThreatText` re-anchors to the current
  `healthBar`. Forever can return threat values as secrets
  (`C_Secrets.ShouldUnitThreatValuesBeSecret`). A secret value from another group
  member is left out of the lead, and a secret value for the player hides the number.
- `embeds.xml`: bundled library loading; `.pkgmeta`: CurseForge packaging and
  external Ace3, LibStub, serialization, and LibEditModeOverride dependencies.

The actionbar, movers, unit-frame, and raid-frame modules have been removed.
Blizzard handles those frames, bags on Retail and Forever, and nameplates on Retail
(and on Forever apart from the threat numbers and threat colors). Keep native bag/bank
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

Layout schema version is currently 22. Existing saved layouts are not silently
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

Commands: `/sui` opens settings,
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

## Versioning

Semver in every TOC (`## Version: MAJOR.MINOR.PATCH`, identical across all five; `tests/toc-version.lua` checks). Each change merged to `master` bumps it: PATCH for fixes, MINOR for new features or options, MAJOR for breaking changes (e.g. a saved-variable reset). Tag the merge commit `vX.Y.Z`. Never push.
