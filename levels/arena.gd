extends Node2D
## One room. Owns who is in the fight and wires the player's health to the HUD.

@onready var _player: Player = %Player as Player
@onready var _hud: Hud = %Hud as Hud


func _ready() -> void:
	var health := _player.health
	if health == null:
		push_error("Arena player is missing HealthComponent.")
		return
	health.health_changed.connect(_hud.set_health)
	health.died.connect(_hud.show_defeated)
	_hud.set_health(health.current_health, health.max_health)
