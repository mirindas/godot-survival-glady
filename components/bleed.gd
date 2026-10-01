class_name Bleed
extends Node2D
## Damage over time on the actor that was hit. One bleed per body.
## A new application restarts the timer and the remaining damage.
## The Rend icon sits in the actor's debuffs and restores clockwise, like an ability slot.

const TOTAL_DAMAGE := 45
const TICKS := 12
const TICK_WAIT := 1.0
const DURATION := float(TICKS) * TICK_WAIT
const TICK_COLOR := Color("ff4d4d")
const TICK_FONT_SIZE := 22
const ICON_SIZE := Vector2(64, 64)

var _health: HealthComponent
var _tick_index := 0
var _wait := 0.0
var _clock: ShaderMaterial


static func apply_to(body: Node, health: HealthComponent) -> void:
	if body == null or health == null or health.current_health <= 0:
		return
	var debuffs := Debuffs.of(body)
	var bleed := debuffs.get_node_or_null("Bleed") as Bleed
	if bleed == null:
		bleed = Bleed.new()
		bleed.name = "Bleed"
		debuffs.add_child(bleed)
	bleed.start(health)


func _ready() -> void:
	var shader := Shader.new()
	shader.code = AttackSlot.CLOCK_SHADER
	_clock = ShaderMaterial.new()
	_clock.shader = shader
	material = _clock
	scale = Vector2(Debuffs.ICON_SCALE, Debuffs.ICON_SCALE)
	var shown := ICON_SIZE * Debuffs.ICON_SCALE
	position = Vector2(-shown.x * 0.5, -shown.y)


func start(health: HealthComponent) -> void:
	_health = health
	_tick_index = 0
	_wait = 0.0
	z_index = 6
	_sync_clock()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if _health == null or not is_instance_valid(_health) or _health.current_health <= 0:
		queue_free()
		return
	_wait += delta
	_sync_clock()
	queue_redraw()
	if _wait < TICK_WAIT:
		return
	_wait -= TICK_WAIT
	var amount := _tick_damage(_tick_index)
	_tick_index += 1
	_health.take_damage(amount)
	_show_tick(amount)
	if _tick_index >= TICKS or _health.current_health <= 0:
		queue_free()


func _seconds_left() -> float:
	var elapsed := float(_tick_index) * TICK_WAIT + _wait
	return maxf(DURATION - elapsed, 0.0)


func _sync_clock() -> void:
	if _clock == null:
		return
	var progress := 1.0 - _seconds_left() / DURATION
	_clock.set_shader_parameter("progress", clampf(progress, 0.0, 1.0))
	_clock.set_shader_parameter("slot_size", ICON_SIZE)


func _draw() -> void:
	AttackSlot.draw_icon(self, AttackSlot.Kind.REND, ICON_SIZE)


## 45 across 12 whole-number ticks: the first nine deal 4, the last three deal 3.
static func _tick_damage(index: int) -> int:
	var remainder := TOTAL_DAMAGE % TICKS
	var each := TOTAL_DAMAGE / TICKS
	return each + (1 if index < remainder else 0)


func _show_tick(amount: int) -> void:
	var debuffs := get_parent() as Node2D
	var body := debuffs.get_parent() as Node2D if debuffs != null else null
	if body == null:
		return
	var host := body.get_parent()
	if host == null:
		return
	var number := DamageNumber.new()
	var spread := Units.measure(&"damage_number_spread")
	var lift := Units.measure(&"damage_number_lift")
	var at := body.global_position + Vector2(randf_range(-spread, spread), -lift)
	number.show_text(str(amount), TICK_COLOR, TICK_FONT_SIZE, at)
	host.add_child.call_deferred(number)
