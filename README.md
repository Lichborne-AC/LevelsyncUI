# LevelSync

A World of Warcraft addon (WotLK 3.3.5a) that provides a graphical UI for [mod-levelsync](https://github.com/azerothcore/mod-levelsync) on AzerothCore private servers.

## Overview

LevelSync provides a graphical interface that lets you view your levelsync group directly from an in-game panel. It displays all accounts and characters in your sync group in a clean 3×2 grid, with levels, class (in colors), and IP tier progression.

## Features

- **3×2 account grid** — up to 6 accounts, 10 characters each
- **Class-colored character names** — each class displays in its official color
- **IP tier progression** — color-coded by tier (Molten Core through Ruby Sanctum)
- **Slash command reference** — all `.levelsync` commands listed directly in the panel
- **Minimap icon** — draggable, position saved between sessions

## Requirements

- AzerothCore private server with [mod-levelsync](https://github.com/azerothcore/mod-levelsync) installed
- WoW client version 3.3.5a (patch 12340)

## Installation

1. Download or clone this repository
2. Copy the `LevelSync` folder into:
   ```
   World of Warcraft/Interface/AddOns/LevelSync/
   ```
3. Launch WoW and enable **LevelSync** on the addon selection screen

## IP Tier Reference

| Tier | Content |
|------|---------|
| 0 | None |
| 1 | Molten Core |
| 2 | Onyxia |
| 3 | Blackwing Lair |
| 4 | Pre-AQ |
| 5 | AQ War Effort |
| 6 | Ahn'Qiraj |
| 7 | Naxxramas (40) |
| 8 | Pre-TBC |
| 9 | Karazhan / Gruul / Magtheridon |
| 10 | Serpentshrine Cavern / Tempest Keep |
| 11 | Hyjal Summit / Black Temple |
| 12 | Zul'Aman |
| 13 | Sunwell Plateau |
| 14 | Naxxramas / Eye of Eternity / Obsidian Sanctum |
| 15 | Ulduar |
| 16 | Trial of the Crusader |
| 17 | Icecrown Citadel |
| 18 | Ruby Sanctum |

## File Structure

```
LevelSync/
├── LevelSync.toc         — Addon manifest
├── LevelSync.lua         — Core logic: commands, event listener, state machine, minimap
├── LevelSync_UI.lua      — All UI frames and widgets
└── libs/
    ├── LibStub/
    ├── LibDataBroker-1.1/
    └── LibDBIcon-1.0/
```

## Compatibility

- WoW 3.3.5a (Interface 30300) only
- Requires mod-levelsync on the server side
- No external dependencies beyond the bundled libraries
