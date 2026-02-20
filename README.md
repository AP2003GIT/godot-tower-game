# Blue Smiley Tower (Godot)

Small Godot 4 game where a dark-blue `:3` smiley jumps up an endless tower.

## Install

- Install Godot 4.2+ (standard build is enough, Mono is not required).

## Run In One Click (Editor)

1. Open Godot.
2. Import project from `godot_tower_game/project.godot`.
3. Press the Run Project button (or `F5`).
4. The game now opens in a menu scene with `Play` and `Exit`.

## Run In One Click (Standalone App)

1. In Godot, open `Editor > Manage Export Templates` and install templates.
2. Open `Project > Export...`.
3. Add your target preset (`Windows Desktop`, `Linux/X11`, or `macOS`).
4. Click `Export Project` to generate an executable.
5. Launch the exported executable directly (double-click).

## Controls

- `Left` / `Right`: Move
- `Space`: Jump
- `Esc`: Back to menu

## Menu

- `Play`: Starts the tower run.
- `Exit`: Quits the game (desktop builds).

## Notes

- Background is light blue.
- Player smiley is dark blue.
- Platforms use a procedural stone-style texture generated in `scripts/platform.gd`.
- Tower generation is endless upward while you climb.
