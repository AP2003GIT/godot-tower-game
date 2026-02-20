extends Control

const GAME_SCENE_PATH: String = "res://scenes/Main.tscn"
const SHOP_SCENE_PATH: String = "res://scenes/Shop.tscn"
const MENU_TITLE: String = "Fortress Climber"
const MENU_SUBTITLE: String = "Jump forever on stone slabs"

@onready var panel: Panel = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBox/Title
@onready var subtitle_label: Label = $CenterContainer/Panel/MarginContainer/VBox/Subtitle
@onready var play_button: Button = $CenterContainer/Panel/MarginContainer/VBox/PlayButton
@onready var shop_button: Button = $CenterContainer/Panel/MarginContainer/VBox/ShopButton
@onready var exit_button: Button = $CenterContainer/Panel/MarginContainer/VBox/ExitButton


func _ready() -> void:
	_apply_startup_window_mode()
	_show_project_identity()
	_style_labels()
	_style_panel()
	_style_buttons()
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	if OS.has_feature("web"):
		exit_button.disabled = true
		exit_button.text = "Exit (desktop only)"


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file(SHOP_SCENE_PATH)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _show_project_identity() -> void:
	var project_root: String = ProjectSettings.globalize_path("res://")
	var normalized_root: String = project_root.replace("\\", "/")

	print("[BlueSmileyTower] Project root: ", project_root)
	title_label.text = MENU_TITLE
	subtitle_label.text = MENU_SUBTITLE

	if not normalized_root.contains("/godot_tower_game/"):
		push_warning("You are not running the main copy. Current root: " + project_root)


func _apply_startup_window_mode() -> void:
	if OS.has_feature("web"):
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _style_buttons() -> void:
	_apply_button_style(play_button, Color(0.22, 0.24, 0.28, 0.98))
	_apply_button_style(shop_button, Color(0.20, 0.22, 0.26, 0.98))
	_apply_button_style(exit_button, Color(0.18, 0.20, 0.24, 0.98))


func _style_labels() -> void:
	title_label.add_theme_color_override("font_color", Color(0.82, 0.84, 0.88, 1.0))
	subtitle_label.add_theme_color_override("font_color", Color(0.63, 0.66, 0.72, 1.0))


func _style_panel() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.11, 0.14, 0.9)
	style.border_color = Color(0.35, 0.37, 0.42, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	panel.add_theme_stylebox_override("panel", style)


func _apply_button_style(button: Button, base_color: Color) -> void:
	button.add_theme_stylebox_override("normal", _make_stylebox(base_color))
	button.add_theme_stylebox_override("hover", _make_stylebox(base_color.lightened(0.09)))
	button.add_theme_stylebox_override("pressed", _make_stylebox(base_color.darkened(0.08)))
	button.add_theme_stylebox_override("focus", _make_stylebox(base_color.lightened(0.12)))


func _make_stylebox(fill_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.content_margin_left = 12.0
	style.content_margin_top = 8.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 8.0
	return style
