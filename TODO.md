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
  `move_left`, `move_right`, `move_up`, `move_down`, `attack`, `heavy_attack`, and `rend` cover keyboard, mouse, and a basic gamepad. `attack` is the simple swing: left click or 1. `heavy_attack` is right click or 2. `rend` is key 3. Gameplay reads actions, not raw key codes.

- [X] **Physics layers**
  State: completed
  Named layers: `world`, `player`, `enemy`, `player_hit`, `enemy_hurt`, `player_hurt`. Bodies block each other and the walls. The swing only overlaps `enemy_hurt`.

- [X] **Shared combat nodes**
  State: completed
  `res://components/health_component.gd` holds hit points and emits `health_changed` and `died`. `Hitbox` enables for the active frames of a swing and hits each hurtbox once. Each hit rolls that swing's damage from 5% under to 5% over, then rounds to a whole number. `Hurtbox` forwards the hit to health.

- [X] **Player movement and swing**
  State: completed
  `res://player/player.gd` uses floating `CharacterBody2D` motion and the states idle, move, simple attack, heavy attack, and dead. The camera sits on the player, zoomed in and limited to the room. Simple attack keeps movement. Heavy attack stops it until the swing ends.

- [X] **Training dummy**
  State: completed
  `res://enemies/dummy/dummy.tscn` blocks the player, flashes when hit, and frees itself at 0 health. 80 health, 25 damage per swing.

- [X] **Arena and HUD**
  State: completed
  `res://levels/arena.tscn` builds the room, instances the player, and connects player health to `res://ui/hud.tscn`. The HUD does not search the tree for the player. Waves replaced the placed dummy. Bottom-left squares show the simple and heavy swings. Each sword is drawn in code. A clockwise fade restores the square from 50% opacity over the swing, or over the heavy cooldown. Health is a silver-bordered bar: green until it drops below 30%, orange below that, red below 10%. The label reads current / maximum | percent.

- [X] **Enemy that fights back**
  State: completed
  `res://enemies/grunt/grunt.tscn` chases the player it is given and swings on its own hitbox (mask `player_hurt`, 12 damage). The arena calls `setup(player)`. It does not search the tree. 70 health. A landed hit reduces the HUD.

- [X] **Hit feel**
  State: completed
  `Knockback` shoves the body that was hit. The arena briefly slows `Engine.time_scale` and asks the player to shake its camera whenever a swing connects. Getting hit cancels the current swing. `Hitbox.play()` owns the active-frame timing so the player and the grunt share it.

- [X] **Survival loop**
  State: completed
  A wave starts only after every enemy from the previous one is dead. Wave 1 is 5 grunts. Each later grunt wave is 22% larger than the last, rounded. After a grunt wave, spawning waits 5 seconds. Enemies then appear in groups of up to 5, each at its own spot between 5 and 15 player-widths away, with 0.15–0.4 seconds between groups. At most 50 enemies are alive; the rest wait in a queue. The HUD shows "Wave N incoming" above center when a wave begins. The run still ends through defeat and restart.

- [X] **Attack chain**
  State: completed
  The simple attack is three swings in a wedge 45° to either side of the cursor. Movement stays on during the chain. Pressing attack during a swing continues it. The chain returns to idle after the third swing, or sooner if attack was not pressed again. A hit cancels it.

- [X] **Heavy attack**
  State: completed
  Right click or 2, and also K, gamepad Y, or the left trigger. One frontal swing, 45 damage, 108 px long starting at the body edge. The player is stopped until it finishes. It does not continue the simple chain.

- [X] **Size units**
  State: completed
  `res://components/units.gd` maps gameplay distances and speeds. 1 unit is the player body width, 36 px. `MEASURES` holds the unit values. `measure()` turns a name into pixels. Collision shapes in the editor stay in pixels; the swing rectangle is applied from `swing_width` and `swing_height` when the hitbox is ready.

- [X] **Floating combat text**
  State: completed
  A landed swing spawns `DamageNumber` above the body that was hit. Player hits are yellow at font size 28. Enemy hits on the player are red at font size 20. Both sizes are exports on that swing's `Hitbox`.

- [X] **Pickups**
  State: completed
  `res://pickups/health/health_pickup.tscn` restores 30 health through `HealthComponent.heal` when the player overlaps it. A grunt has a 5% chance to leave one behind on death. No inventory. Armor drops the same way: a blue shield restores 15 armor, at 10%. Both icons float above a small shadow. The pickup volume stays on the ground. A health drop disappears after 25 seconds, an armor drop after 35. A small clock above the icon shows the time left.

- [X] **Armor**
  State: completed
  Player armor starts at 0 and caps at 50. A hit is reduced with `raw * 100 / (100 + armor)`, so each point adds 1% effective health and 50 armor blocks about a third of the hit. A grunt hit also strips 5 armor before that reduction. The HUD shows a blue bar under health. The floating number is the damage after armor.

- [X] **Player defeat and restart**
  State: completed
  When the player reaches 0 health, the HUD shows a large red "DEFEATED" in the center and reloads the arena when `attack` is pressed. Nothing is kept across the reload, so no autoload is involved.

- [X] **Boss waves**
  State: completed
  `res://enemies/boss/boss.tscn` is a grunt scaled to 5 times the player body (180×240). The first boss has 350 health and 36 damage. Each later boss has 13% more health and 2% more damage than the one before, rounded. It moves at 60% of the grunt's speed. Its swing starts at the grunt's attack range, measured from the boss body. Waves 5, 10, 15, and so on spawn that boss alone. Killing it waits 10 seconds, then the next grunt wave starts. Grunt counts keep growing from the last grunt wave, so a boss wave does not reset them. The wave line shows defeated enemies as N / X.

- [X] **Enemy health bars**
  State: completed
  Each enemy, including the dummy, draws a 50×10 bar above its body. Corners are rounded. The fill uses the player bar colors: green, orange below 30%, red below 10%. Debuff icons sit above that bar.

- [X] **Rend**
  State: completed
  Key 3, then a 6 second cooldown on the Rend icon. Same arc as the simple attack, starting at the body edge. Direct damage is half the simple swing, rounded to a whole number (25 becomes 13), then the usual damage roll. The swing is red. Each target hit gets a bleed of 45 damage over 12 seconds, one whole-number tick per second (nine ticks of 4, then three of 3), and the Rend icon in that actor's debuffs, at half the previous size, restoring clockwise like an ability cooldown. A new Rend on the same target restarts that bleed. The sword icons tilt 30° to the right, and Rend's icon has a blood drop under the tip.

- [X] **Player stats**
  State: completed
  `StatsComponent` on the player. Crit and dodge start at 5% and cannot go below zero. A crit doubles that hit after the damage roll, and its number is larger, italic, and orange. A dodge drops an enemy hit before damage, armor loss, or knockback, and the player shows "dodge" where the damage number would have been. Speed starts at 0%. Above zero moves faster, below zero moves slower, and the result never reverses movement. The HUD shows the three values. The arena wires the signal.

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
