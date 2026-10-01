class_name Debuffs
extends Node2D
## The debuff row above an actor. Each effect adds its icon here.

const ICON_SCALE := 0.25
const GAP := 6.0


static func of(body: Node) -> Debuffs:
	var debuffs := body.get_node_or_null("Debuffs") as Debuffs
	if debuffs == null:
		debuffs = Debuffs.new()
		debuffs.name = "Debuffs"
		body.add_child(debuffs)
	debuffs.place_above_body()
	return debuffs


func _ready() -> void:
	z_index = 6
	child_exiting_tree.connect(_on_child_exiting)
	place_above_body()


func place_above_body() -> void:
	var body := get_parent() as Node2D
	if body == null:
		return
	var shape_node := body.get_node_or_null(^"BodyShape") as CollisionShape2D
	var rect := shape_node.shape as RectangleShape2D if shape_node != null else null
	var half_height := 24.0
	if rect != null:
		half_height = rect.size.y * 0.5
	position = Vector2(0.0, -half_height - GAP)


func _on_child_exiting(_child: Node) -> void:
	if get_child_count() <= 1:
		queue_free()
