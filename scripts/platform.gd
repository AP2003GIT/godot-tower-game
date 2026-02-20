extends StaticBody2D

@export var size: Vector2 = Vector2(165.0, 30.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var polygon: Polygon2D = $Polygon2D

static var shared_stone_texture: Texture2D


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
	rect_shape.size = size
	collision_shape.shape = rect_shape
	collision_shape.one_way_collision = false

	if shared_stone_texture == null:
		shared_stone_texture = _create_stone_texture(256, 64)

	# Keep Polygon2D hidden and draw explicitly to avoid renderer/version differences.
	polygon.visible = false
	queue_redraw()


func _draw() -> void:
	var platform_rect: Rect2 = Rect2(-size * 0.5, size)
	if shared_stone_texture:
		# Stretch instead of tiling to avoid repeated edge seams/stripe artifacts.
		draw_texture_rect(shared_stone_texture, platform_rect, false, Color(1, 1, 1, 1))
	else:
		draw_rect(platform_rect, Color(0.63, 0.66, 0.72, 1.0), true)

	draw_rect(platform_rect, Color(0.27, 0.30, 0.34, 0.92), false, 2.0)
	draw_line(
		Vector2(platform_rect.position.x + 2.0, platform_rect.position.y + 2.0),
		Vector2(platform_rect.position.x + platform_rect.size.x - 2.0, platform_rect.position.y + 2.0),
		Color(0.92, 0.95, 1.0, 0.45),
		1.0
	)


func _create_stone_texture(width: int, height: int) -> Texture2D:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 29031

	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 11807
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.11

	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)

	for y: int in range(height):
		var row_mix: float = float(y) / float(height - 1)
		var vertical_tint: float = lerpf(0.08, -0.07, row_mix)
		for x: int in range(width):
			var n: float = noise.get_noise_2d(float(x), float(y))
			var grain: float = rng.randf_range(-0.03, 0.03)
			var shade: float = clampf(0.56 + (n * 0.14) + grain + vertical_tint, 0.0, 1.0)
			image.set_pixel(
				x,
				y,
				Color(
					shade,
					clampf(shade + 0.03, 0.0, 1.0),
					clampf(shade + 0.06, 0.0, 1.0),
					1.0
				)
			)

	for _i: int in range(12):
		var crack_y: int = rng.randi_range(4, height - 5)
		var crack_start: int = rng.randi_range(0, width - 24)
		var crack_len: int = rng.randi_range(18, 64)
		var crack_end: int = mini(width - 1, crack_start + crack_len)
		for x: int in range(crack_start, crack_end):
			if rng.randf() < 0.86:
				var y_offset: int = rng.randi_range(-1, 1)
				var pixel_y: int = int(clampf(float(crack_y + y_offset), 1.0, float(height - 2)))
				image.set_pixel(x, pixel_y, Color(0.33, 0.34, 0.36, 1.0))

	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
