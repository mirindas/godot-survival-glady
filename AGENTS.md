# Agents

Read this file before changing Survival Glady. Read `TODO.md` for what is pending, completed, or denied. Godot 4.7, GDScript, top-down 2D hack and slash. Main scene: `res://levels/arena.tscn`.

## 1. Assets

Do not import, download, generate, or add any asset until the user explicitly authorizes that exact asset. This includes sprites, textures, tilesets, fonts, audio, models, shaders packs, UI kits, and asset-pack zips.

Placeholder art stays code-drawn (`_draw()` on the player and dummy). `icon.svg` is an original project file, not a third-party import. Do not replace either with outside art on your own.

When the user authorizes an asset, it must be free to use with no retained rights. Royalty-free is required. Allowed licenses are CC0 and public domain only. The asset must be usable in this game with no royalties, no attribution, no non-commercial clause, and no other restriction.

Stop and ask again if the license is anything else, including:

- "royalty-free" with extra terms (attribution, no commercial use, no edits, editorial only)
- Creative Commons other than CC0 (CC-BY, CC-BY-SA, CC-BY-NC, and the rest)
- "free" on itch.io, OpenGameArt, or a marketplace when the license is missing or mixed
- paid packs, ripped game assets, or files with an unknown source

Before the file enters the repo, tell the user the source URL and the license, and wait for a yes that names that asset. After it is added, keep the source and license in the message that introduced it. Do not drop a credits file unless the user asks.

Put an authorized asset next to the feature that uses it (`player/`, `enemies/<name>/`). Use `res://shared/` only when more than one feature uses the same file.

## 2. Paths

Feature folders only. Snake_case files and folders. PascalCase node names and `class_name` types.

```
res://
  player/                  player.tscn, player.gd
  enemies/<enemy_name>/    one folder per enemy
  components/              shared nodes only: health, hitbox, hurtbox
  levels/                  rooms; arena.tscn is the current main scene
  ui/                      hud and other interface scenes
  shared/                  authorized assets used by more than one feature
  addons/                  third-party code, still needs authorization
```

- New enemy: `res://enemies/<snake_case_name>/`, instanced by the level that owns the fight.
- New level: `res://levels/<name>.tscn`.
- Do not add a root `scripts/`, `assets/`, `art/`, or `audio/` dump.
- Do not hardcode scene paths in several scripts. One owner exports the `PackedScene` or holds the single `res://` constant.
- Paths in scenes and scripts use `res://`. Do not rename or move a `.gd`, `.tscn`, or `.uid` from outside the Godot editor unless every reference is updated in the same change.

## 3. Ownership

Call down, signal up. The arena wires the player's `health_changed` and `died` to the HUD. The HUD does not search the tree for the player.

| Concern | Owner |
|---|---|
| Movement and both swings | `res://player/player.gd` |
| Hit points | `HealthComponent` on that actor |
| Active frames of a swing | `Hitbox` |
| Receiving a hit | `Hurtbox` |
| Who is in the room | `res://levels/arena.gd` |
| Health text and attack slots | `res://ui/hud.gd` |

Physics layers stay: `world`, `player`, `enemy`, `player_hit`, `enemy_hurt`, `player_hurt`. Gameplay input uses the InputMap actions `move_left`, `move_right`, `move_up`, `move_down`, `attack` (simple swing), and `heavy_attack`.

No autoload, manager, generic state-machine framework, pixel-snap import setup, or object pool unless `TODO.md` moves that item out of Denied and the user asks for it. A global is justified only when the data must outlive the current scene.

When a pending item is finished, mark it `[X]` and set its state to completed in `TODO.md`. Leave denied items denied.
