# Survival Glady

Top-down 2D hack and slash. Checkboxes mark the work itself: `[X]` done, `[ ]` not done. The heading is the decision: pending, completed, or denied.

## Pending

- [ ] **Enemy that fights back**
  State: pending
  A moving enemy that chases the player and swings on its own hitbox. The player hurtbox on `res://player/player.tscn` is already on layer `player_hurt` and is wired to `HealthComponent`, so a landed hit can reduce the HUD.

- [ ] **Player defeat and restart**
  State: pending
  When the player reaches 0 health, `res://levels/arena.gd` already tells the HUD to show "Defeated" and the body stops. Add a way to restart the arena from that state.

- [ ] **Hit feel**
  State: pending
  Knockback, a short hit pause, and a small camera shake when a swing connects. The dummy only flashes red today (`res://enemies/dummy/dummy.gd`).

- [ ] **Replace placeholder drawings**
  State: pending
  Swap the `_draw()` rectangles on the player and dummy for sprites and an attack animation. Keep the collision shapes in `BodyShape`, `Hitbox`, and `Hurtbox` as the gameplay size.

- [ ] **Survival loop**
  State: pending
  Spawn waves of enemies in the arena, raise the pressure over time, and end the run when the player dies. The arena in `res://levels/arena.tscn` is the owner of who is in the fight.

- [ ] **Attack chain**
  State: pending
  A short combo that continues if attack is pressed again during the swing. `Player` currently stores one buffered attack and returns to idle when `attack_duration` ends.

- [ ] **Pickups**
  State: pending
  Drops that restore health, collected by an `Area2D` and applied through `HealthComponent`. No inventory yet.

- [ ] **Sound**
  State: pending
  Swing, hit, and death sounds owned by the scene that causes them. Music that should keep playing across a future scene change is the point where a small audio autoload would earn a place.

## Completed

- [X] **Godot 4.7 project shell**
  State: completed
  `project.godot` targets Godot 4.7 with the GL Compatibility renderer, a 1280×720 view, top-down gravity of 0, `.gitignore`, `.gitattributes`, and `icon.svg`. Main scene is `res://levels/arena.tscn`.

- [X] **Input actions**
  State: completed
  `move_left`, `move_right`, `move_up`, `move_down`, and `attack` cover keyboard, mouse, and a basic gamepad. Gameplay reads actions, not raw key codes.

- [X] **Physics layers**
  State: completed
  Named layers: `world`, `player`, `enemy`, `player_hit`, `enemy_hurt`, `player_hurt`. Bodies block each other and the walls. The swing only overlaps `enemy_hurt`.

- [X] **Shared combat nodes**
  State: completed
  `res://components/health_component.gd` holds hit points and emits `health_changed` and `died`. `Hitbox` enables for the active frames of a swing and hits each hurtbox once. `Hurtbox` forwards the hit to health.

- [X] **Player movement and swing**
  State: completed
  `res://player/player.gd` uses floating `CharacterBody2D` motion and the states idle, move, attack, and dead. The camera sits on the player, zoomed in and limited to the room.

- [X] **Training dummy**
  State: completed
  `res://enemies/dummy/dummy.tscn` blocks the player, flashes when hit, and frees itself at 0 health. 80 health, 25 damage per swing.

- [X] **Arena and HUD**
  State: completed
  `res://levels/arena.tscn` builds the room, instances the player and dummy, and connects player health to `res://ui/hud.tscn`. The HUD does not search the tree for the player.

- [X] **Headless smoke run**
  State: completed
  Imported and ran the arena in Godot 4.7.2 headless. The project loaded with no script errors.

## Denied

- [ ] **Autoload managers**
  State: denied
  No `GameManager`, `PlayerManager`, or `EnemyManager`. The player owns movement, the dummy owns its death, and the arena owns the fight. A global waits until something must outlive the current scene, such as save data.

- [ ] **Generic state-machine framework**
  State: denied
  The player uses an enum and `match`. A state-node framework waits until one actor has enough states that the enum is hard to follow.

- [ ] **Pixel-art import setup**
  State: denied
  Nearest-filter and pixel snap stay off until an art style is chosen. The current bodies are drawn in code.

- [ ] **Object pooling**
  State: denied
  Enemies are created and freed directly. Pooling waits for a measured spawn cost, not for the first wave.
