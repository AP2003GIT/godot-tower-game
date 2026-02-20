# Fortress Climber (Godot 4)

Endless tower-climber with unlockable characters, coin economy, and Q abilities.

## Requirements

- Godot `4.x` (standard build; Mono not required)

## Run

1. Open Godot.
2. Import `project.godot`.
3. Press `F5` to run.

## Gameplay

- Endless procedural slab generation while climbing upward.
- Rising lava loss condition: if lava catches the player, run restarts.
- Run tracker with `Level`, `Best`, `Coins`, and context `Q` ability status.
- Persistent progress via `user://save_data.json`.

## Controls

- `Left` / `A`: Move left
- `Right` / `D`: Move right
- `Space` / `W` / `Up`: Jump
- `Q`: Character ability (only if equipped character has one)
- `Esc`: Return to menu

## Coins

Coins are awarded per new slab reached in a run:

- Slabs `1-20`: `+1` coin each
- Slabs `21-40`: `+2` coins each
- Slabs `41-60`: `+3` coins each
- Slabs `61-80`: `+4` coins each
- Slabs `81+`: `+5` coins each

## Shop And Characters

- Shop menu lists available characters from spriteframe assets.
- Buy/equip flow:
1. Select a character.
2. Preview animation is shown before buying.
3. Buy if enough coins, then equip.
- Character prices are `100`, `200`, `300`, `400`, `500`, with selected special characters at `1000`.

## Abilities (Q)

- `500`-coin characters: `Double Jump` on `Q` with `15s` cooldown.
- `1000`-coin characters: `Flight` on `Q` for `5s` duration with `30s` cooldown.
- Characters without ability do not show Q cooldown/status UI.

## Saved Data

The game saves:

- Highest score
- Current coins
- Total coins earned
- Owned characters
- Equipped character
