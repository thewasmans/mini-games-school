# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.6 project (`config/name="2026-godot-gdscript-template"`) using Forward Plus rendering and Jolt Physics for 3D. It is structured as a reusable manager-based template/scaffold rather than a single finished game — expect scenes and managers to be added/removed as new mini-games or systems are built on top of it.

## Development

- Open the project folder in Godot 4.6 and press F5, or open directly to the main scene (`scenes/main.tscn`, set via `run/main_scene` in `project.godot`).
- There is no CLI build/lint/test setup in this repo (no `.gd` unit tests, no CI config) — verification is done by running the project in the Godot editor.
- Input actions (`action_forward`, `action_backward`, `action_turn_left`, `action_turn_right`) are defined in `project.godot` under `[input]`, not hardcoded — check there before adding new input handling.

## Architecture

The project uses a **manager pattern**: a central `GameManager` owns a list of `Manager` subclasses, initializes them in order, and exposes shared `GameState`/`GameData` to all of them.

- **GameManager** (`scripts/managers/game_managers.gd`): lives under `Global/GameManager` in `scenes/main.tscn`. On `initialize()` (called from `Main._ready()`), it builds a fresh `GameState` from its exported `GameData` resource, then calls `initialize(self)` on every manager in its `managers` getter, in order, and finally emits `initialized`. **New managers must be added to both the `@export_category("Managers")` block and the `managers` getter array**, or they will never be initialized despite being wired in the scene tree.
- **Manager** (`scripts/managers/manager.gd`): `@abstract` base class. Exposes `game_state` and `game_data` as computed properties that proxy to the owning `GameManager`. Subclasses override `initialize(game_manager)` and must call `super.initialize(game_manager)` first.
- **GameUIManager** (`scripts/managers/game_ui_manager.gd`): instantiates the `game_ui_prefab` PackedScene, calls `initialize()` on it, and reparents it under `root_scene` (wired to the scene root via NodePath, not hardcoded).
- **GameState** (`scripts/state/game_state.gd`): `extends Object`, constructed fresh each run in `GameManager.initialize()` from a `GameData` argument. Add mutable runtime state here (see the `CharacterState`-style pattern below for signals).
- **GameData** (`scripts/data/game_data.gd`): `extends Resource`, stored as `data/game_data.tres` and exported on `GameManager`. Holds static/tunable config (e.g. `linear_speed`, `rotation_speed`) editable in the Inspector without touching code.
- **Main** (`scripts/main.gd`): root node of `scenes/main.tscn`; its only job is calling `game_manager.initialize()` in `_ready()`.

### Scene structure (`scenes/main.tscn`)

- `Global`: singleton-style nodes — `GameManager` (and its child managers, e.g. `GameUIManager`) plus `Camera3D`.
- `Level`: container for gameplay entities (currently empty at the scene root level; per-level content is expected to live here).
- `Environment`: `WorldEnvironment` with sky/tonemap/glow config.
- `Lighting`: `DirectionalLight3D` with shadows enabled.

### Resource layout

- `content/prefabs/`: instantiable scenes (e.g. `box.tscn`, `ui/game_ui.tscn`, `ui/button_level_ui.tscn`), referenced by managers via `@export`ed `PackedScene`.
- `content/theme/`: shared `Theme` resource and `StyleBoxFlat` variants used by UI prefabs.
- `content/materials/`, `content/models_3d/`: 3D assets (materials, `.glb` models + textures).
- `data/`: `GameData` `.tres` instances.
- `scripts/`: mirrors the conceptual layers — `managers/`, `state/`, `data/`, `ui/`.
- `scripts/mini_games/`: one folder per mini-game (`crossword/`, `memo/`, `crypto/`) holding that game's runtime logic and `Resource` data classes; `mini_game_data.gd` (the shared `MiniGameData` base) sits at the folder root. The matching `*_ui.gd` scripts live in `scripts/ui/` with the rest of the UI scripts.

## Key conventions

- All managers extend `Manager` and implement `initialize(game_manager)`, calling `super.initialize(game_manager)` first.
- UI scenes live in `content/prefabs/ui/`; their scripts extend `Control` and expose an `initialize(game_manager)` entry point, called by the manager that instantiates them (see `GameUI.initialize` in `scripts/ui/game_ui.gd`).
- Scene organization follows the fixed top-level grouping: `Global` (singletons/managers), `Level` (gameplay), `Environment` (rendering), `Lighting` (lights).
- GDScript uses PascalCase for `class_name` declarations.
- **No comments in code** — never write comments in GDScript files. Names should be self-explanatory; if a comment feels necessary, rename the function/variable instead.
- **Exports are always assigned** — `@export` variables are wired in the Godot Inspector and guaranteed to be set at runtime. Never add `if x == null` guards or null checks on exported variables.
- When adding a manager, wiring it only into the scene tree is not enough — it must also be added to `GameManager`'s exported vars and its `managers` getter array (see Architecture above), or `initialize()` will silently skip it.
