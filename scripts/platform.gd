extends StaticBody2D

@export var size: Vector2 = Vector2(165.0, 30.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var polygon: Polygon2D = $Polygon2D


func _ready() -> void:
	add_to_group("platform")
	_rebuild()


func set_width(new_width: float) -> void:
	size.x = new_width
	_rebuild()


func get_width() -> float:
	return size.x


func get_height() -> float:
	return size.y


func _rebuild() -> void:
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	# Use a slightly slimmer collider than the visual slab to avoid side-edge
	# snag impulses that can launch the player.
	rect_shape.size = Vector2(size.x, maxf(10.0, size.y - 8.0))
	collision_shape.shape = rect_shape
	collision_shape.one_way_collision = false

	# Keep Polygon2D hidden and draw explicitly.
	polygon.visible = false
	queue_redraw()


func _draw() -> void:
	var platform_rect: Rect2 = Rect2(-size * 0.5, size)
	draw_rect(platform_rect, Color(0.63, 0.66, 0.72, 1.0), true)
	_draw_brick_pattern(platform_rect)

	draw_rect(platform_rect, Color(0.27, 0.30, 0.34, 0.92), false, 2.0)
	draw_line(
		Vector2(platform_rect.position.x + 2.0, platform_rect.position.y + 2.0),
		Vector2(platform_rect.position.x + platform_rect.size.x - 2.0, platform_rect.position.y + 2.0),
		Color(0.92, 0.95, 1.0, 0.45),
		1.0
	)


func _draw_brick_pattern(rect: Rect2) -> void:
	var brick_h: float = 9.0
	var brick_w: float = 24.0
	var row: int = 0
	var y: float = rect.position.y + 2.0
	while y < rect.end.y - 2.0:
		var offset: float = 0.0 if row % 2 == 0 else brick_w * 0.5
		var x: float = rect.position.x + 2.0 - offset
		while x < rect.end.x - 2.0:
			var bw: float = minf(brick_w - 1.0, rect.end.x - x - 2.0)
			var bh: float = minf(brick_h - 1.0, rect.end.y - y - 2.0)
			if bw > 4.0 and bh > 3.0:
				var shade: float = 0.03 if (row + int(floor(x / brick_w))) % 2 == 0 else -0.02
				var fill: Color = Color(0.63 + shade, 0.66 + shade, 0.72 + shade, 0.20)
				draw_rect(Rect2(x, y, bw, bh), fill, true)
				draw_rect(Rect2(x, y, bw, 1.0), Color(0.90, 0.92, 0.96, 0.16), true)
				draw_rect(Rect2(x, y + bh - 1.0, bw, 1.0), Color(0.15, 0.17, 0.21, 0.20), true)
			x += brick_w
		y += brick_h
		row += 1
