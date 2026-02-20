extends Control

const MENU_SCENE_PATH: String = "res://scenes/Menu.tscn"
@onready var panel: Panel = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBox/Title
@onready var coins_label: Label = $CenterContainer/Panel/MarginContainer/VBox/CoinsLabel
@onready var character_select: OptionButton = $CenterContainer/Panel/MarginContainer/VBox/CharacterSelect
@onready var preview_panel: Panel = $CenterContainer/Panel/MarginContainer/VBox/PreviewPanel
@onready var preview_sprite: AnimatedSprite2D = $CenterContainer/Panel/MarginContainer/VBox/PreviewPanel/PreviewRoot/PreviewSprite
@onready var preview_label: Label = $CenterContainer/Panel/MarginContainer/VBox/PreviewPanel/PreviewLabel
@onready var details_label: Label = $CenterContainer/Panel/MarginContainer/VBox/DetailsLabel
@onready var action_button: Button = $CenterContainer/Panel/MarginContainer/VBox/ActionButton
@onready var back_button: Button = $CenterContainer/Panel/MarginContainer/VBox/BackButton

var character_entries: Array[Dictionary] = []


func _ready() -> void:
	_style_ui()
	_load_character_entries()
	_refresh_coins()
	character_select.item_selected.connect(_on_character_selected)
	action_button.pressed.connect(_on_action_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_refresh_selected_state()


func _load_character_entries() -> void:
	character_entries.clear()
	character_select.clear()

	for entry: Dictionary in GameState.get_shop_characters():
		character_entries.append(entry)
		character_select.add_item(String(entry.get("name", "Unknown")))

	var equipped_path: String = GameState.get_equipped_character_path()
	var selected_index: int = _index_for_path(equipped_path)
	if selected_index >= 0:
		character_select.select(selected_index)
	elif character_entries.size() > 0:
		character_select.select(0)


func _refresh_coins() -> void:
	coins_label.text = "Coins: %d" % GameState.coins


func _refresh_selected_state() -> void:
	if character_entries.is_empty():
		details_label.text = "No characters found in spriteframes."
		action_button.disabled = true
		return

	var index: int = character_select.selected
	if index < 0 or index >= character_entries.size():
		details_label.text = "No character selected."
		action_button.disabled = true
		return

	var entry: Dictionary = character_entries[index]
	var character_path: String = String(entry["path"])
	var cost: int = int(entry["cost"])
	var owned: bool = GameState.is_character_owned(character_path)
	var equipped: bool = GameState.get_equipped_character_path() == character_path
	var ability_text: String = _ability_text_for_cost(cost)

	if equipped:
		details_label.text = "Owned\nCost: %d\nStatus: Equipped\nAbility: %s" % [cost, ability_text]
		action_button.text = "Equipped"
		action_button.disabled = true
	elif owned:
		details_label.text = "Owned\nCost: %d\nStatus: Ready to equip\nAbility: %s" % [cost, ability_text]
		action_button.text = "Equip"
		action_button.disabled = false
	else:
		details_label.text = "Not owned\nCost: %d\nAbility: %s\nReward from slabs builds your coins." % [cost, ability_text]
		action_button.text = "Buy (%d)" % cost
		action_button.disabled = GameState.coins < cost

	_update_preview(character_path, String(entry.get("name", "Unknown")))


func _on_character_selected(_index: int) -> void:
	_refresh_selected_state()


func _on_action_pressed() -> void:
	if character_entries.is_empty():
		return

	var index: int = character_select.selected
	if index < 0 or index >= character_entries.size():
		return

	var entry: Dictionary = character_entries[index]
	var character_path: String = String(entry["path"])
	var cost: int = int(entry["cost"])

	if GameState.is_character_owned(character_path):
		GameState.equip_character(character_path)
	else:
		if not GameState.spend_coins(cost):
			return
		GameState.own_character(character_path)
		GameState.equip_character(character_path)

	_refresh_coins()
	_refresh_selected_state()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)


func _index_for_path(path: String) -> int:
	for i: int in range(character_entries.size()):
		if String(character_entries[i]["path"]) == path:
			return i
	return -1


func _style_ui() -> void:
	title_label.text = "Character Shop"
	var title_color: Color = Color(0.82, 0.84, 0.88, 1.0)
	var body_color: Color = Color(0.66, 0.69, 0.75, 1.0)
	var preview_color: Color = Color(0.76, 0.79, 0.85, 1.0)
	title_label.add_theme_color_override("font_color", title_color)
	coins_label.add_theme_color_override("font_color", body_color)
	preview_label.add_theme_color_override("font_color", preview_color)
	details_label.add_theme_color_override("font_color", body_color)

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
	preview_panel.add_theme_stylebox_override("panel", _make_stylebox(Color(0.12, 0.13, 0.18, 0.85)))

	_apply_button_style(action_button, Color(0.22, 0.24, 0.28, 0.98))
	_apply_button_style(back_button, Color(0.18, 0.20, 0.24, 0.98))


func _apply_button_style(button: Button, base_color: Color) -> void:
	var normal_style: StyleBoxFlat = _make_stylebox(base_color)
	var hover_style: StyleBoxFlat = _make_stylebox(base_color.lightened(0.09))
	var pressed_style: StyleBoxFlat = _make_stylebox(base_color.darkened(0.08))
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
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


func _update_preview(character_path: String, display_name: String) -> void:
	preview_sprite.sprite_frames = null
	preview_label.text = "Preview: %s" % display_name
	if not ResourceLoader.exists(character_path):
		return

	var frames: SpriteFrames = load(character_path) as SpriteFrames
	if frames == null:
		return

	preview_sprite.sprite_frames = frames
	var anim_name: StringName = _pick_preview_anim(frames)
	if not anim_name.is_empty():
		preview_sprite.play(anim_name)


func _pick_preview_anim(frames: SpriteFrames) -> StringName:
	if frames.has_animation(&"run"):
		return &"run"
	if frames.has_animation(&"idle"):
		return &"idle"
	var names: PackedStringArray = frames.get_animation_names()
	if names.is_empty():
		return &""
	return StringName(names[0])


func _ability_text_for_cost(cost: int) -> String:
	if cost == 1000:
		return "Flight 5s / Cooldown 30s (Q)"
	if cost == 500:
		return "Double Jump / Cooldown 15s (Q)"
	return "None"
