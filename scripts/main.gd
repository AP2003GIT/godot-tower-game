extends Node2D

@export var platform_scene: PackedScene

const START_PLATFORM_Y: float = 560.0
const START_PLATFORM_COUNT: int = 18
const PLATFORM_SPACING_Y: float = 108.0
const TOWER_HALF_WIDTH: float = 300.0
const MIN_PLATFORM_WIDTH: float = 120.0
const MAX_PLATFORM_WIDTH: float = 210.0
const ROWS_AHEAD: int = 18
const CAMERA_OFFSET_Y: float = -140.0
const FALL_DISTANCE: float = 720.0
const START_PLATFORM_WIDTH: float = 230.0
const MIN_CENTER_DELTA: float = 56.0
const MAX_CENTER_DELTA: float = 240.0
const MAX_EXTRA_ROWS_AHEAD: int = 16
const MIN_PLATFORMS_AROUND_CAMERA: int = 22
const LAVA_START_OFFSET_Y: float = 880.0
const LAVA_RISE_SPEED: float = 38.0
const LAVA_CHASE_SPEED: float = 84.0
const LAVA_FOLLOW_OFFSET_Y: float = 460.0
const LAVA_CATCH_MARGIN: float = 18.0

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var lava: Node2D = $World/Lava
@onready var level_label: Label = $CanvasLayerHUD/HUD/LevelLabel
@onready var restart_button: Button = $CanvasLayerHUD/HUD/RestartButton
@onready var coins_label: Label = $CanvasLayerHUD/HUD/CoinsLabel
@onready var double_jump_label: Label = $CanvasLayerHUD/HUD/DoubleJumpLabel

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var top_generated_y: float = START_PLATFORM_Y
var top_platform_x: float = 0.0
var top_platform_width: float = START_PLATFORM_WIDTH
var best_level: int = 1
var awarded_slabs: int = 0
var lava_surface_y: float = START_PLATFORM_Y + LAVA_START_OFFSET_Y
var current_level: int = 1


func _ready() -> void:
	rng.randomize()
	_ensure_input_actions()
	best_level = maxi(1, GameState.highest_score)
	restart_button.pressed.connect(_on_restart_pressed)
	_style_restart_button()
	_start_new_run()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause_menu"):
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")
		return

	_update_lava(delta)
	_spawn_platforms_if_needed()
	_ensure_platform_density()
	_cleanup_old_platforms()
	_update_camera()
	_update_level_text()
	_update_double_jump_label()
	_check_for_fall()


func _start_new_run() -> void:
	for platform_node: Node in get_tree().get_nodes_in_group("platform"):
		platform_node.free()
	_purge_world_collision_objects()

	top_generated_y = START_PLATFORM_Y
	top_platform_x = 0.0
	top_platform_width = START_PLATFORM_WIDTH
	awarded_slabs = 0
	current_level = 1
	lava_surface_y = START_PLATFORM_Y + LAVA_START_OFFSET_Y
	_set_lava_surface(lava_surface_y)
	_spawn_platform(Vector2(top_platform_x, START_PLATFORM_Y), top_platform_width)

	for i: int in range(1, START_PLATFORM_COUNT):
		_spawn_next_row()

	player.global_position = Vector2(0.0, START_PLATFORM_Y - 96.0)
	player.velocity = Vector2.ZERO
	camera.global_position = Vector2(0.0, player.global_position.y + CAMERA_OFFSET_Y)


func _spawn_platforms_if_needed() -> void:
	var speed_rows: int = int(clampf(absf(player.velocity.y) / 180.0, 0.0, float(MAX_EXTRA_ROWS_AHEAD)))
	var rows_ahead: int = ROWS_AHEAD + speed_rows
	var camera_target_top: float = camera.global_position.y - (float(rows_ahead) * PLATFORM_SPACING_Y)
	var player_target_top: float = player.global_position.y - (float(ROWS_AHEAD + 18) * PLATFORM_SPACING_Y)
	var target_top: float = minf(camera_target_top, player_target_top)
	while top_generated_y > target_top:
		_spawn_next_row()


func _ensure_platform_density() -> void:
	var count_nearby: int = 0
	var min_y: float = camera.global_position.y - 1350.0
	var max_y: float = camera.global_position.y + 520.0
	for platform_node: Node in get_tree().get_nodes_in_group("platform"):
		if not (platform_node is Node2D):
			continue
		var platform_2d: Node2D = platform_node as Node2D
		if platform_2d.global_position.y >= min_y and platform_2d.global_position.y <= max_y:
			count_nearby += 1

	var guard: int = 0
	while count_nearby < MIN_PLATFORMS_AROUND_CAMERA and guard < 40:
		_spawn_next_row()
		count_nearby += 1
		guard += 1


func _cleanup_old_platforms() -> void:
	var cutoff: float = camera.global_position.y + FALL_DISTANCE + 1200.0
	for platform_node: Node in get_tree().get_nodes_in_group("platform"):
		if platform_node is Node2D:
			var platform_2d: Node2D = platform_node as Node2D
			if platform_2d.global_position.y > cutoff:
				platform_2d.free()


func _purge_world_collision_objects() -> void:
	_purge_collision_recursive(world)


func _purge_collision_recursive(node: Node) -> void:
	for child: Node in node.get_children():
		# Remove any stray physics bodies left in World except player and lava.
		if child == player or child == lava:
			continue
		if child is CollisionObject2D:
			if child is PhysicsBody2D and child.is_in_group("platform"):
				continue
			child.free()
			continue
		_purge_collision_recursive(child)


func _update_camera() -> void:
	var target_y: float = player.global_position.y + CAMERA_OFFSET_Y
	camera.global_position.y = minf(camera.global_position.y, target_y)
	camera.global_position.x = lerpf(camera.global_position.x, player.global_position.x * 0.35, 0.05)


func _update_level_text() -> void:
	var climbed: float = maxf(0.0, START_PLATFORM_Y - player.global_position.y)
	current_level = int(floor(climbed / PLATFORM_SPACING_Y)) + 1
	var slabs_climbed: int = maxi(0, current_level - 1)
	best_level = maxi(best_level, current_level)
	GameState.set_highest_score(best_level)
	level_label.text = "Level %d  Best %d" % [current_level, best_level]
	_award_coins_for_slabs(slabs_climbed)
	coins_label.text = "Coins: %d" % GameState.coins


func _check_for_fall() -> void:
	if player.global_position.y >= lava_surface_y - LAVA_CATCH_MARGIN:
		_start_new_run()
		return

	if player.global_position.y > camera.global_position.y + FALL_DISTANCE:
		_start_new_run()


func _on_restart_pressed() -> void:
	_start_new_run()


func _spawn_platform(pos: Vector2, width: float) -> void:
	var platform_node: Node = platform_scene.instantiate()
	world.add_child(platform_node)
	if platform_node is Node2D:
		var platform_2d: Node2D = platform_node as Node2D
		platform_2d.global_position = pos
	if platform_node.has_method("set_width"):
		platform_node.call("set_width", width)


func _spawn_next_row() -> void:
	var y: float = top_generated_y - PLATFORM_SPACING_Y
	var width: float = _random_width()
	var x: float = _pick_playable_x(top_platform_x, top_platform_width, width)
	_spawn_platform(Vector2(x, y), width)
	top_generated_y = y
	top_platform_x = x
	top_platform_width = width


func _pick_playable_x(previous_x: float, previous_width: float, new_width: float) -> float:
	var min_x: float = -TOWER_HALF_WIDTH + (new_width * 0.5)
	var max_x: float = TOWER_HALF_WIDTH - (new_width * 0.5)
	var lower: float = maxf(min_x, previous_x - MAX_CENTER_DELTA)
	var upper: float = minf(max_x, previous_x + MAX_CENTER_DELTA)

	if lower > upper:
		return clampf(previous_x, min_x, max_x)

	for _attempt: int in range(10):
		var candidate: float = rng.randf_range(lower, upper)
		var center_delta: float = absf(candidate - previous_x)
		if center_delta >= _min_center_delta(previous_width, new_width):
			return candidate

	var fallback_dir: float = -1.0 if previous_x >= 0.0 else 1.0
	var fallback_x: float = previous_x + (fallback_dir * _min_center_delta(previous_width, new_width))
	return clampf(fallback_x, min_x, max_x)


func _min_center_delta(previous_width: float, new_width: float) -> float:
	return maxf(MIN_CENTER_DELTA, (previous_width + new_width) * 0.18)


func _random_width() -> float:
	return rng.randf_range(MIN_PLATFORM_WIDTH, MAX_PLATFORM_WIDTH)


func _ensure_input_actions() -> void:
	_ensure_action("move_left", [KEY_LEFT, KEY_A])
	_ensure_action("move_right", [KEY_RIGHT, KEY_D])
	_ensure_action("jump", [KEY_SPACE, KEY_UP, KEY_W])
	_ensure_action("double_jump", [KEY_Q])
	_ensure_action("pause_menu", [KEY_ESCAPE])


func _ensure_action(action_name: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	if InputMap.action_get_events(action_name).is_empty():
		for keycode: int in keycodes:
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action_name, event)


func _style_restart_button() -> void:
	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.0431373, 0.215686, 0.505882, 1.0)
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.content_margin_left = 10.0
	normal_style.content_margin_top = 6.0
	normal_style.content_margin_right = 10.0
	normal_style.content_margin_bottom = 6.0

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.11, 0.29, 0.58, 1.0)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.12, 0.15, 0.20, 1.0)

	restart_button.add_theme_stylebox_override("normal", normal_style)
	restart_button.add_theme_stylebox_override("hover", hover_style)
	restart_button.add_theme_stylebox_override("pressed", pressed_style)


func _award_coins_for_slabs(slabs_climbed: int) -> void:
	if slabs_climbed <= awarded_slabs:
		return

	for slab_index: int in range(awarded_slabs + 1, slabs_climbed + 1):
		GameState.add_coins(_coin_reward_for_slab(slab_index))

	awarded_slabs = slabs_climbed


func _coin_reward_for_slab(slab_index: int) -> int:
	if slab_index <= 20:
		return 1
	if slab_index <= 40:
		return 2
	if slab_index <= 60:
		return 3
	if slab_index <= 80:
		return 4
	return 5


func _update_double_jump_label() -> void:
	if not GameState.equipped_character_has_q_ability():
		double_jump_label.visible = false
		return

	double_jump_label.visible = true
	if player != null and player.has_method("get_q_ability_status_text"):
		double_jump_label.text = String(player.call("get_q_ability_status_text"))


func _update_lava(delta: float) -> void:
	lava_surface_y -= LAVA_RISE_SPEED * delta
	var desired_surface_y: float = player.global_position.y + LAVA_FOLLOW_OFFSET_Y
	if lava_surface_y > desired_surface_y:
		lava_surface_y = maxf(lava_surface_y - (LAVA_CHASE_SPEED * delta), desired_surface_y)
	_set_lava_surface(lava_surface_y)


func _set_lava_surface(surface_y: float) -> void:
	if lava != null and lava.has_method("set_surface_y"):
		lava.call("set_surface_y", surface_y)
