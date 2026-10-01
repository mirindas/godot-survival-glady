class_name Units
extends Object
## Tuning map. 1 unit is the player body's width.
## Godot still keeps positions and collision shapes in pixels.
## Edit a value here, then read it back with measure() or px().

const PLAYER_WIDTH := 36.0
const PLAYER_HEIGHT := 48.0 # px, player body height

# Stored as units (player widths). The comment is the current pixel result.
const PLAYER_MOVE_SPEED := 260.0 / PLAYER_WIDTH # 260 px/s
const GRUNT_MOVE_SPEED := 120.0 / PLAYER_WIDTH # 120 px/s
const GRUNT_LUNGE_SPEED := 90.0 / PLAYER_WIDTH # 90 px/s
const GRUNT_ATTACK_RANGE := 1.5 # 54 px
const SWING_WIDTH := 40.0 / PLAYER_WIDTH # 40 px forward from the body edge
const SWING_HEIGHT := 28.0 / PLAYER_WIDTH # hitbox height, 28 px
const SIMPLE_ARC_RADIUS := 2.2 # 79.2 px forward from the body edge
const HEAVY_SWING_WIDTH := 72.0 / PLAYER_WIDTH # 72 px forward from the body edge
const HEAVY_SWING_HEIGHT := 36.0 / PLAYER_WIDTH # 36 px
const PLAYER_KNOCKBACK_SPEED := 340.0 / PLAYER_WIDTH # 340 px/s
const GRUNT_KNOCKBACK_SPEED := 280.0 / PLAYER_WIDTH # 280 px/s
const DAMAGE_NUMBER_LIFT := 50.0 / PLAYER_WIDTH # 50 px above the body
const DAMAGE_NUMBER_RISE_SPEED := 52.0 / PLAYER_WIDTH # 52 px/s
const DAMAGE_NUMBER_SPREAD := 8.0 / PLAYER_WIDTH # 8 px of sideways scatter
const SHAKE_AMOUNT := 5.0 / PLAYER_WIDTH # 5 px

# Boss body is BOSS_SCALE times the player. The swing scales with that body
# so the hitbox stays in front of it. Speed is 60% of the grunt.
# Attack range matches the grunt and is measured from the body edge.
const BOSS_SCALE := 5.0
const BOSS_MOVE_SPEED := GRUNT_MOVE_SPEED * 0.6 # 72 px/s
const BOSS_LUNGE_SPEED := GRUNT_LUNGE_SPEED * 0.6 # 54 px/s
const BOSS_ATTACK_RANGE := GRUNT_ATTACK_RANGE # 54 px past the body
const BOSS_SWING_WIDTH := SWING_WIDTH * BOSS_SCALE # 200 px forward from the body edge
const BOSS_SWING_HEIGHT := SWING_HEIGHT * BOSS_SCALE # 140 px

const MEASURES: Dictionary[StringName, float] = {
	&"player_move_speed": PLAYER_MOVE_SPEED,
	&"grunt_move_speed": GRUNT_MOVE_SPEED,
	&"grunt_lunge_speed": GRUNT_LUNGE_SPEED,
	&"grunt_attack_range": GRUNT_ATTACK_RANGE,
	&"swing_width": SWING_WIDTH,
	&"swing_height": SWING_HEIGHT,
	&"simple_arc_radius": SIMPLE_ARC_RADIUS,
	&"heavy_swing_width": HEAVY_SWING_WIDTH,
	&"heavy_swing_height": HEAVY_SWING_HEIGHT,
	&"player_knockback_speed": PLAYER_KNOCKBACK_SPEED,
	&"grunt_knockback_speed": GRUNT_KNOCKBACK_SPEED,
	&"damage_number_lift": DAMAGE_NUMBER_LIFT,
	&"damage_number_rise_speed": DAMAGE_NUMBER_RISE_SPEED,
	&"damage_number_spread": DAMAGE_NUMBER_SPREAD,
	&"shake_amount": SHAKE_AMOUNT,
	&"boss_move_speed": BOSS_MOVE_SPEED,
	&"boss_lunge_speed": BOSS_LUNGE_SPEED,
	&"boss_attack_range": BOSS_ATTACK_RANGE,
	&"boss_swing_width": BOSS_SWING_WIDTH,
	&"boss_swing_height": BOSS_SWING_HEIGHT,
}


static func px(units: float) -> float:
	return units * PLAYER_WIDTH


static func measure(id: StringName) -> float:
	if not MEASURES.has(id):
		push_error("Unknown unit '%s'." % id)
		return 0.0
	return px(MEASURES[id])


## Distance from a centered rectangle to its edge along direction.
static func body_edge(shape: RectangleShape2D, direction: Vector2) -> float:
	if shape == null or direction.length_squared() < 0.0001:
		return 0.0
	var half := shape.size * 0.5
	var dir := direction.normalized()
	var dx := absf(dir.x)
	var dy := absf(dir.y)
	var along_x := half.x / dx if dx > 0.0001 else INF
	var along_y := half.y / dy if dy > 0.0001 else INF
	return minf(along_x, along_y)
