# Survival Glady

Top-down 2D hack and slash. Checkboxes mark the work itself: `[X]` done, `[ ]` not done. The heading is the decision: pending, completed, or denied.

## Pending

- [ ] **Replace placeholder drawings**
  State: pending
  Swap the `_draw()` rectangles on the player and dummy for sprites and an attack animation. Keep the collision shapes in `BodyShape`, `Hitbox`, and `Hurtbox` as the gameplay size.

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
  `res://levels/arena.tscn` builds the room, instances the player, and connects player health to `res://ui/hud.tscn`. The HUD does not search the tree for the player. Waves replaced the placed dummy.

- [X] **Enemy that fights back**
  State: completed
  `res://enemies/grunt/grunt.tscn` chases the player it is given and swings on its own hitbox (mask `player_hurt`, 12 damage). The arena calls `setup(player)`. It does not search the tree. 70 health. A landed hit reduces the HUD.

- [X] **Hit feel**
  State: completed
  `Knockback` shoves the body that was hit. The arena briefly slows `Engine.time_scale` and asks the player to shake its camera whenever a swing connects. Getting hit cancels the current swing. `Hitbox.play()` owns the active-frame timing so the player and the grunt share it.

- [X] **Survival loop**
  State: completed
  `res://levels/arena.gd` spawns grunts in waves, shortens the gap between waves, and stops at 8 alive. The run ends through the existing defeat and restart. The dummy scene remains, but the arena no longer places one in the room.

- [X] **Attack chain**
  State: completed
  Three swings. Pressing attack during a swing continues the chain. The chain returns to idle after the third swing, or sooner if attack was not pressed again. A hit cancels it.

- [X] **Size units**
  State: completed
  `res://components/units.gd` maps gameplay distances and speeds. 1 unit is the player body width, 36 px. `MEASURES` holds the unit values. `measure()` turns a name into pixels. Collision shapes in the editor stay in pixels; the swing rectangle is applied from `swing_width` and `swing_height` when the hitbox is ready.

- [X] **Floating combat text**
  State: completed
  A landed swing spawns `DamageNumber` above the body that was hit. Player hits are yellow at font size 28. Enemy hits on the player are red at font size 20. Both sizes are exports on that swing's `Hitbox`.

- [X] **Pickups**
  State: completed
  `res://pickups/health/health_pickup.tscn` restores 30 health through `HealthComponent.heal` when the player overlaps it. A grunt has a 40% chance to leave one behind on death. No inventory.

- [X] **Player defeat and restart**
  State: completed
  When the player reaches 0 health, `res://levels/arena.gd` shows "Defeated" on the HUD and reloads the arena when `attack` is pressed. Nothing is kept across the reload, so no autoload is involved.

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
