extends ColorRect

const BG_TOP: Color = Color(0.13, 0.12, 0.22, 1.0)
const BG_BOTTOM: Color = Color(0.10, 0.09, 0.17, 1.0)
const WALL_BASE: Color = Color(0.21, 0.24, 0.41, 1.0)
const WALL_SHADOW: Color = Color(0.14, 0.16, 0.30, 1.0)
const WALL_HIGHLIGHT: Color = Color(0.30, 0.34, 0.56, 1.0)
const FLOOR_BASE: Color = Color(0.19, 0.21, 0.33, 1.0)
const FLOOR_EDGE: Color = Color(0.33, 0.39, 0.62, 1.0)
const GATE_DARK: Color = Color(0.03, 0.03, 0.06, 1.0)
const GATE_FRAME: Color = Color(0.34, 0.31, 0.44, 1.0)
const TORCH_GLOW: Color = Color(1.0, 0.56, 0.18, 0.20)
const TORCH_CORE: Color = Color(1.0, 0.78, 0.38, 0.95)
const MOTE_COLOR: Color = Color(0.40, 0.24, 0.34, 0.45)


func _ready() -> void:
	color = BG_BOTTOM
	resized.connect(_on_resized)
	queue_redraw()


func _on_resized() -> void:
	queue_redraw()


func _draw() -> void:
	var view_size: Vector2 = size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return

	_draw_gradient(view_size)
	_draw_back_wall_motes(view_size)
	_draw_side_walls(view_size)
	_draw_floor_strip(view_size)
	_draw_gate(view_size)
	_draw_torches(view_size)


func _draw_gradient(view_size: Vector2) -> void:
	var bands: int = 24
	for i: int in range(bands):
		var t0: float = float(i) / float(bands)
		var y0: float = view_size.y * t0
		var h: float = (view_size.y / float(bands)) + 1.0
		var row_color: Color = BG_TOP.lerp(BG_BOTTOM, t0)
		draw_rect(Rect2(0.0, y0, view_size.x, h), row_color, true)


func _draw_back_wall_motes(view_size: Vector2) -> void:
	var step: float = 26.0
	var y: float = 32.0
	while y < view_size.y * 0.74:
		var x: float = 14.0
		while x < view_size.x - 14.0:
			var v: int = int(floor((x * 0.17) + (y * 0.23)))
			if v % 11 == 0:
				draw_rect(Rect2(x, y, 4.0, 2.0), MOTE_COLOR, true)
			x += step
		y += step


func _draw_side_walls(view_size: Vector2) -> void:
	var wall_w: float = clampf(view_size.x * 0.15, 82.0, 140.0)
	_draw_brick_column(Rect2(0.0, 0.0, wall_w, view_size.y), 22.0, 14.0)
	_draw_brick_column(Rect2(view_size.x - wall_w, 0.0, wall_w, view_size.y), 22.0, 14.0)

	draw_rect(Rect2(wall_w - 2.0, 0.0, 2.0, view_size.y), WALL_SHADOW, true)
	draw_rect(Rect2(view_size.x - wall_w, 0.0, 2.0, view_size.y), WALL_SHADOW, true)


func _draw_brick_column(rect: Rect2, brick_w: float, brick_h: float) -> void:
	draw_rect(rect, WALL_BASE, true)
	var row: int = 0
	var y: float = rect.position.y
	while y < rect.end.y:
		var offset_x: float = 0.0 if row % 2 == 0 else brick_w * 0.5
		var x: float = rect.position.x - offset_x
		while x < rect.end.x:
			var brick_rect: Rect2 = Rect2(x + 1.0, y + 1.0, brick_w - 2.0, brick_h - 2.0)
			var tint: Color = WALL_BASE.lerp(WALL_HIGHLIGHT, 0.18 if row % 3 == 0 else 0.08)
			draw_rect(brick_rect, tint, true)
			draw_rect(Rect2(brick_rect.position, Vector2(brick_rect.size.x, 1.0)), WALL_HIGHLIGHT, true)
			draw_rect(Rect2(brick_rect.position + Vector2(0.0, brick_rect.size.y - 1.0), Vector2(brick_rect.size.x, 1.0)), WALL_SHADOW, true)
			x += brick_w
		y += brick_h
		row += 1


func _draw_floor_strip(view_size: Vector2) -> void:
	var floor_y: float = view_size.y * 0.73
	var floor_h: float = view_size.y * 0.27
	draw_rect(Rect2(0.0, floor_y, view_size.x, floor_h), FLOOR_BASE, true)
	draw_rect(Rect2(0.0, floor_y, view_size.x, 6.0), FLOOR_EDGE, true)

	var tile_w: float = 28.0
	var x: float = 0.0
	while x < view_size.x:
		var notch: float = 2.0 if int(x / tile_w) % 2 == 0 else 0.0
		draw_rect(Rect2(x + 1.0, floor_y + 7.0 + notch, tile_w - 2.0, 10.0), WALL_BASE, true)
		x += tile_w


func _draw_gate(view_size: Vector2) -> void:
	var center_x: float = view_size.x * 0.5
	var gate_w: float = clampf(view_size.x * 0.23, 130.0, 210.0)
	var gate_h: float = clampf(view_size.y * 0.25, 170.0, 280.0)
	var floor_y: float = view_size.y * 0.73
	var gate_x: float = center_x - (gate_w * 0.5)
	var gate_y: float = floor_y - gate_h

	draw_rect(Rect2(gate_x, gate_y + 34.0, gate_w, gate_h - 34.0), GATE_DARK, true)
	draw_arc(Vector2(center_x, gate_y + 34.0), gate_w * 0.5, PI, TAU, 24, GATE_DARK, 34.0)

	var frame_step: float = 15.0
	var i: int = 0
	while i < 7:
		var t: float = float(i) * frame_step
		var band_color: Color = GATE_FRAME.darkened(float(i) * 0.03)
		draw_rect(Rect2(gate_x - t - 2.0, gate_y + 34.0 - t - 1.0, gate_w + (t * 2.0) + 4.0, 4.0), band_color, true)
		draw_rect(Rect2(gate_x - t - 2.0, gate_y + 34.0 - t - 1.0, 4.0, gate_h + t), band_color, true)
		draw_rect(Rect2(gate_x + gate_w + t - 2.0, gate_y + 34.0 - t - 1.0, 4.0, gate_h + t), band_color, true)
		i += 1

	var bar_y: float = gate_y + 44.0
	while bar_y < floor_y - 8.0:
		draw_rect(Rect2(gate_x + 12.0, bar_y, gate_w - 24.0, 2.0), Color(0.22, 0.24, 0.30, 0.82), true)
		bar_y += 18.0


func _draw_torches(view_size: Vector2) -> void:
	var floor_y: float = view_size.y * 0.73
	var y: float = floor_y - 70.0
	var left_x: float = view_size.x * 0.37
	var right_x: float = view_size.x * 0.63

	_draw_torch(Vector2(left_x, y))
	_draw_torch(Vector2(right_x, y))


func _draw_torch(pos: Vector2) -> void:
	draw_circle(pos, 34.0, TORCH_GLOW)
	draw_circle(pos, 20.0, Color(TORCH_GLOW.r, TORCH_GLOW.g, TORCH_GLOW.b, 0.22))
	draw_circle(pos, 7.0, TORCH_CORE)
	draw_rect(Rect2(pos.x - 2.0, pos.y + 7.0, 4.0, 16.0), Color(0.33, 0.29, 0.24, 1.0), true)
