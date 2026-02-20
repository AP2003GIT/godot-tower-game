extends CharacterBody2D

const RUN_SPEED: float = 255.0
const JUMP_VELOCITY: float = -575.0
const DOUBLE_JUMP_VELOCITY: float = -550.0
const DOUBLE_JUMP_COOLDOWN: float = 15.0
const FLIGHT_DURATION: float = 5.0
const FLIGHT_COOLDOWN: float = 30.0
const FLIGHT_ASCEND_SPEED: float = -220.0
const GRAVITY: float = 1450.0
const SMILEY_DARK_BLUE: Color = Color(0.0431373, 0.215686, 0.505882, 1.0)
const FACE_MARK_COLOR: Color = Color(0.898039, 0.94902, 1.0, 1.0)
const DEFAULT_DUELYST_SPRITEFRAMES_PATH: String = "res://addons/duelyst_animated_sprites/assets/spriteframes/units/f3_general.tres"
const ANIM_IDLE: StringName = &"idle"
const ANIM_RUN: StringName = &"run"
const ANIM_JUMP: StringName = &"jump"
const ANIM_JUMP_FALLBACK: StringName = &"cast"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var use_draw_fallback: bool = true
var base_sprite_scale: Vector2 = Vector2.ONE
var air_time: float = 0.0
var air_jumps_left: int = 0
var double_jump_cooldown_left: float = 0.0
var flight_time_left: float = 0.0
var flight_cooldown_left: float = 0.0


func _ready() -> void:
	base_sprite_scale = animated_sprite.scale
	use_draw_fallback = not _try_setup_duelyst_sprite()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if double_jump_cooldown_left > 0.0:
		double_jump_cooldown_left = maxf(0.0, double_jump_cooldown_left - delta)
	if flight_cooldown_left > 0.0:
		flight_cooldown_left = maxf(0.0, flight_cooldown_left - delta)
	if flight_time_left > 0.0:
		flight_time_left = maxf(0.0, flight_time_left - delta)

	var on_floor_before_move: bool = is_on_floor()
	var has_flight: bool = GameState.equipped_character_has_flight()
	if on_floor_before_move:
		air_jumps_left = _extra_air_jumps_for_equipped_character()

	if has_flight and _is_q_pressed() and flight_time_left <= 0.0 and flight_cooldown_left <= 0.0:
		flight_time_left = FLIGHT_DURATION
		flight_cooldown_left = FLIGHT_COOLDOWN

	if flight_time_left > 0.0:
		velocity.y = FLIGHT_ASCEND_SPEED
	elif not on_floor_before_move:
		velocity.y += GRAVITY * delta

	var input_dir: float = Input.get_axis("move_left", "move_right")
	if is_zero_approx(input_dir):
		input_dir = _fallback_direction_from_keys()

	var target_speed: float = input_dir * RUN_SPEED
	var acceleration: float = 18.0 if is_on_floor() else 10.0
	velocity.x = move_toward(velocity.x, target_speed, RUN_SPEED * acceleration * delta)

	if flight_time_left > 0.0:
		pass
	elif on_floor_before_move and _is_jump_pressed():
		velocity.y = JUMP_VELOCITY
	elif not on_floor_before_move and air_jumps_left > 0 and _is_double_jump_pressed():
		velocity.y = DOUBLE_JUMP_VELOCITY
		air_jumps_left -= 1
		double_jump_cooldown_left = DOUBLE_JUMP_COOLDOWN
		air_time = 0.0

	move_and_slide()
	_update_visual_state(input_dir)
	_update_air_pose(delta)


func _is_jump_pressed() -> bool:
	return Input.is_action_just_pressed("jump") \
		or Input.is_physical_key_pressed(KEY_SPACE) \
		or Input.is_physical_key_pressed(KEY_UP) \
		or Input.is_physical_key_pressed(KEY_W)


func _is_double_jump_pressed() -> bool:
	if GameState.equipped_character_has_flight():
		return false
	if not GameState.equipped_character_has_double_jump():
		return false
	if double_jump_cooldown_left > 0.0:
		return false
	return _is_q_pressed()


func _is_q_pressed() -> bool:
	return Input.is_action_just_pressed("double_jump")


func _extra_air_jumps_for_equipped_character() -> int:
	if GameState.equipped_character_has_flight():
		return 0
	if not GameState.equipped_character_has_double_jump():
		return 0
	if double_jump_cooldown_left > 0.0:
		return 0
	return 1


func get_q_ability_status_text() -> String:
	if GameState.equipped_character_has_flight():
		if flight_time_left > 0.0:
			return "Q Flight: %.1fs" % flight_time_left
		if flight_cooldown_left > 0.0:
			return "Q Cooldown: %.1fs" % flight_cooldown_left
		return "Q Flight: Ready"

	if GameState.equipped_character_has_double_jump():
		if double_jump_cooldown_left > 0.0:
			return "Q Cooldown: %.1fs" % double_jump_cooldown_left
		return "Q: Ready"

	return ""


func _fallback_direction_from_keys() -> float:
	var left_pressed: bool = Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A)
	var right_pressed: bool = Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)
	return float(int(right_pressed) - int(left_pressed))


func _try_setup_duelyst_sprite() -> bool:
	var equipped_path: String = GameState.get_equipped_character_path()
	if equipped_path.is_empty():
		equipped_path = DEFAULT_DUELYST_SPRITEFRAMES_PATH
	if not ResourceLoader.exists(equipped_path):
		equipped_path = DEFAULT_DUELYST_SPRITEFRAMES_PATH

	if not ResourceLoader.exists(equipped_path):
		animated_sprite.visible = false
		return false

	var sprite_frames: SpriteFrames = load(equipped_path) as SpriteFrames
	if sprite_frames == null:
		animated_sprite.visible = false
		return false

	animated_sprite.visible = true
	animated_sprite.sprite_frames = sprite_frames
	_play_if_exists(ANIM_IDLE)
	return true


func _update_visual_state(input_dir: float) -> void:
	if use_draw_fallback:
		return

	if not is_zero_approx(input_dir):
		animated_sprite.flip_h = input_dir < 0.0

	if is_on_floor():
		if absf(velocity.x) > 10.0:
			_play_if_exists(ANIM_RUN)
		else:
			_play_if_exists(ANIM_IDLE)
	else:
		if not _play_if_exists(ANIM_JUMP):
			if not _play_if_exists(ANIM_JUMP_FALLBACK):
				if absf(velocity.x) > 10.0:
					_play_if_exists(ANIM_RUN)
				else:
					_play_if_exists(ANIM_IDLE)


func _play_if_exists(anim_name: StringName) -> bool:
	if animated_sprite.animation == anim_name:
		return true
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		return true
	return false


func _update_air_pose(delta: float) -> void:
	if use_draw_fallback:
		return

	if is_on_floor():
		air_time = 0.0
		animated_sprite.scale = base_sprite_scale
		animated_sprite.rotation = 0.0
		animated_sprite.offset = Vector2.ZERO
		return

	air_time += delta
	var rise: float = clampf((-velocity.y) / 700.0, 0.0, 1.0)
	var fall: float = clampf(velocity.y / 900.0, 0.0, 1.0)

	var sx: float = 1.0 - (0.12 * rise) + (0.14 * fall)
	var sy: float = 1.0 + (0.16 * rise) - (0.10 * fall)
	animated_sprite.scale = Vector2(base_sprite_scale.x * sx, base_sprite_scale.y * sy)

	var facing_sign: float = -1.0 if animated_sprite.flip_h else 1.0
	var tilt: float = ((-0.14 * rise) + (0.18 * fall)) * facing_sign
	animated_sprite.rotation = tilt

	var bob: float = sin(air_time * 10.0) * 1.5
	animated_sprite.offset = Vector2(0.0, (-2.0 - (3.0 * rise) + (2.0 * fall)) + bob)


func _draw() -> void:
	if not use_draw_fallback:
		return

	draw_circle(Vector2.ZERO, 26.0, SMILEY_DARK_BLUE)
	draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 44, SMILEY_DARK_BLUE.darkened(0.25), 2.0)
	draw_circle(Vector2(-8.0, -6.0), 2.6, FACE_MARK_COLOR)
	draw_circle(Vector2(8.0, -6.0), 2.6, FACE_MARK_COLOR)
	draw_arc(
		Vector2(0.0, 2.0),
		9.5,
		deg_to_rad(20.0),
		deg_to_rad(160.0),
		24,
		FACE_MARK_COLOR,
		2.6
	)
