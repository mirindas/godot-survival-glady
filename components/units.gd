class_name Units
extends Object
## Tuning map. 1 unit is the player body's width.
## Godot still keeps positions and collision shapes in pixels.
## Edit a value here, then read it back with measure() or px().

const PLAYER_WIDTH := 36.0

# Stored as units (player widths). The comment is the current pixel result.
const PLAYER_MOVE_SPEED := 260.0 / PLAYER_WIDTH # 260 px/s
const GRUNT_MOVE_SPEED := 120.0 / PLAYER_WIDTH # 120 px/s
const GRUNT_LUNGE_SPEED := 90.0 / PLAYER_WIDTH # 90 px/s
const GRUNT_ATTACK_RANGE := 74.0 / PLAYER_WIDTH # 74 px
const SWING_REACH := 46.0 / PLAYER_WIDTH # 46 px in front of the body
const SWING_WIDTH := 40.0 / PLAYER_WIDTH # hitbox width, 40 px
const SWING_HEIGHT := 28.0 / PLAYER_WIDTH # hitbox height, 28 px
const PLAYER_KNOCKBACK_SPEED := 340.0 / PLAYER_WIDTH # 340 px/s
const GRUNT_KNOCKBACK_SPEED := 280.0 / PLAYER_WIDTH # 280 px/s
const DAMAGE_NUMBER_LIFT := 50.0 / PLAYER_WIDTH # 50 px above the body
const DAMAGE_NUMBER_RISE_SPEED := 52.0 / PLAYER_WIDTH # 52 px/s
const DAMAGE_NUMBER_SPREAD := 8.0 / PLAYER_WIDTH # 8 px of sideways scatter
const SHAKE_AMOUNT := 5.0 / PLAYER_WIDTH # 5 px

const MEASURES: Dictionary[StringName, float] = {
	&"player_move_speed": PLAYER_MOVE_SPEED,
	&"grunt_move_speed": GRUNT_MOVE_SPEED,
	&"grunt_lunge_speed": GRUNT_LUNGE_SPEED,
	&"grunt_attack_range": GRUNT_ATTACK_RANGE,
	&"swing_reach": SWING_REACH,
	&"swing_width": SWING_WIDTH,
	&"swing_height": SWING_HEIGHT,
	&"player_knockback_speed": PLAYER_KNOCKBACK_SPEED,
	&"grunt_knockback_speed": GRUNT_KNOCKBACK_SPEED,
	&"damage_number_lift": DAMAGE_NUMBER_LIFT,
	&"damage_number_rise_speed": DAMAGE_NUMBER_RISE_SPEED,
	&"damage_number_spread": DAMAGE_NUMBER_SPREAD,
	&"shake_amount": SHAKE_AMOUNT,
}


static func px(units: float) -> float:
	return units * PLAYER_WIDTH


static func measure(id: StringName) -> float:
	if not MEASURES.has(id):
		push_error("Unknown unit '%s'." % id)
		return 0.0
	return px(MEASURES[id])
