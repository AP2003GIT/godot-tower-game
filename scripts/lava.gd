extends Node2D

@export var fill_width: float = 2200.0
@export var fill_height: float = 3600.0
@export var lava_fill: Color = Color(0.74, 0.15, 0.08, 0.95)
@export var lava_top: Color = Color(1.0, 0.44, 0.14, 0.95)
@export var lava_glow: Color = Color(1.0, 0.58, 0.22, 0.18)


func _ready() -> void:
	queue_redraw()


func set_surface_y(surface_y: float) -> void:
	global_position.y = surface_y
	queue_redraw()


func get_surface_y() -> float:
	return global_position.y


func _draw() -> void:
	var left: float = -fill_width * 0.5
	draw_rect(Rect2(left, 0.0, fill_width, fill_height), lava_fill, true)
	draw_rect(Rect2(left, -16.0, fill_width, 18.0), lava_top, true)
	draw_rect(Rect2(left, -28.0, fill_width, 12.0), lava_glow, true)
