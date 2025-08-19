# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ScarletUI is a World of Warcraft addon that provides UI modifications and enhancements. It's built using the Ace3 addon framework and supports multiple WoW versions (Vanilla, Cataclysm, Mists of Pandaria, and Mainline/Retail).

## Multi-Version Support

The addon supports four WoW versions through separate .toc files:
- `ScarletUI-Vanilla.toc` - Interface 11507 (Classic Era)
- `ScarletUI-Cata.toc` - Interface 40402 (Cataclysm Classic) 
- `ScarletUI-Mists.toc` - Interface 50500 (Mists of Pandaria Classic)
- `ScarletUI-Mainline.toc` - Interface 110107 (Current Retail)

All .toc files load the same Lua files but target different game versions.

## Architecture

### Core Structure
- `ScarletUI.lua` - Main addon file, handles initialization, database setup, and chat commands
- `embeds.xml` - Loads all Ace3 library dependencies
- `Modules/` - Contains all feature modules loaded by the .toc files

### Key Libraries (Ace3 Framework)
- AceAddon-3.0: Core addon framework
- AceDB-3.0: Database and settings persistence  
- AceConfig-3.0: Configuration interface system
- AceGUI-3.0: GUI widget system
- AceConsole-3.0: Chat command handling
- LibStub: Library management
- LibSerialize: Data serialization utilities

### Module System
Each module in `Modules/` provides specific functionality:
- `Database.lua` - Default settings and configuration structure
- `Options.lua` - Configuration UI generation
- `Helpers.lua` - Utility functions and version detection
- `Actionbars.lua` - Action bar positioning and modifications
- `UnitFrames.lua` - Player/target/focus frame positioning
- `RaidFrames.lua` - Raid frame enhancements
- `Nameplates.lua` - Nameplate customizations
- `Chat.lua` - Chat window modifications
- `Bag.lua` - Bag/inventory enhancements
- `ItemLevel.lua` - Item level display features
- `CVars.lua` - Game console variable management
- `Movers.lua` - Frame movement system
- `TidyIcons.lua` - Icon size improvements

### Database Structure
Settings are stored in `ScarletUIDB` saved variable with the following pattern:
- Global settings in `db.global`
- Each module has its own settings section (e.g., `unitFramesModule`, `actionbarsModule`)
- Frame positioning stored with anchor points, coordinates, and scale
- Module enable/disable flags for each feature

## Development Commands

This addon uses CurseForge packaging via `.pkgmeta` file. No build scripts, tests, or linting tools are configured.

### Packaging
The `.pkgmeta` file defines:
- External library dependencies from CurseForge and GitHub
- Files to ignore during packaging
- Package name as "ScarletUI"

### Chat Commands
- `/sui` - Opens the configuration interface
- In-game configuration available through Interface Options

## Code Patterns

### Version Detection
Use `ScarletUI:GetWoWVersion()` from Helpers.lua to detect WoW version:
- Returns "VANILLA", "CATA", "MISTS", or "RETAIL"
- Used to show/hide version-specific features

### Frame Movement
Frames use a standardized positioning system with:
- `frameAnchor` and `screenAnchor` (numeric anchor point IDs)
- `x`, `y` coordinates relative to anchors  
- `scale` for frame scaling
- `move` boolean to enable positioning
- `hide` boolean to hide frames

### Module Structure
Each module typically implements:
- Settings in Database.lua defaults
- Configuration UI in Options.lua
- Setup functions called from main addon
- Version-specific feature toggling

### Static Popups
Uses WoW's StaticPopup system for confirmations (reload UI, reset settings, etc.)