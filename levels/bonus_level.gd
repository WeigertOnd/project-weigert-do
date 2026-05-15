extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var text_label = $Label
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var success_clicks = 0
var needed_clicks = 5
var wrong_clicks = 0

var move_timer = 0.0
var hide_timer = 0.0
var hidden = false

var buttons_locked = false


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()


func start_level():
	success_clicks = 0
	needed_clicks = 5
	wrong_clicks = 0
	move_timer = 1.8
	hide_timer = 0.0
	hidden = false
	buttons_locked = false

	setup_ui()
	update_text()

	agree_button.text = "Souhlasím s korekcí"
	no_button.text = "nesouhlasím"

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	style_button_soft_xp(agree_button)
	style_button_soft_xp(no_button)

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	move_disagree_button()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if hidden:
		hide_timer -= delta

		if hide_timer <= 0:
			hidden = false
			no_button.visible = true
			move_disagree_button()

	move_timer -= delta

	var move_delay = 2.0 - float(success_clicks) * 0.10 - float(wrong_clicks) * 0.04
	move_delay = max(0.9, move_delay)

	if move_timer <= 0 and not hidden:
		move_timer = move_delay
		move_disagree_button()


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.color = Color(0.96, 0.90, 0.90)
	background.z_index = 0

	text_label.z_index = 5
	agree_button.z_index = 5
	no_button.z_index = 6

	layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	text_label.position = Vector2(55, 70)
	text_label.size = Vector2(window_size.x - 110, 210)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 22)
	text_label.modulate = Color(0.50, 0.0, 0.0)

	agree_button.size = Vector2(230, 38)
	agree_button.position = Vector2(window_size.x / 2 - 115, 330)

	no_button.size = Vector2(125, 32)
	no_button.add_theme_font_size_override("font_size", 11)


func update_text():
	text_label.text = (
		"KONTROLA SYSTÉMU 100 %\n\n"
		+ "KOREKČNÍ TEST SPUŠTĚN\n\n"
		+ "Najděte malé tlačítko NESOUHLASÍM S KOREKCÍ.\n\n"
		+ "Úspěch: " + str(success_clicks) + "/" + str(needed_clicks)
		+ "\nChybné kliky: " + str(wrong_clicks)
	)


func _on_agree_pressed():
	if buttons_locked:
		return

	wrong_clicks += 1
	needed_clicks += 1

	text_label.modulate = Color(0.60, 0.0, 0.0)
	text_label.text = (
		"ŠPATNĚ.\n\n"
		+ "Souhlas s korekcí posílil systém.\n"
		+ "Test byl prodloužen.\n\n"
		+ "Úspěch: " + str(success_clicks) + "/" + str(needed_clicks)
		+ "\nChybné kliky: " + str(wrong_clicks)
	)

	agree_button.text = "Souhlasím ještě více"

	move_disagree_button()

	if wrong_clicks % 2 == 0:
		hide_disagree_button_temporarily()


func _on_no_pressed():
	if buttons_locked or hidden:
		return

	success_clicks += 1

	if success_clicks >= needed_clicks:
		finish_bonus()
		return

	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = (
		"NESOUHLAS S KOREKCÍ ZAZNAMENÁN\n\n"
		+ "Systém to považuje za neochotu spolupracovat.\n\n"
		+ "Úspěch: " + str(success_clicks) + "/" + str(needed_clicks)
		+ "\nChybné kliky: " + str(wrong_clicks)
	)

	move_disagree_button()

	if success_clicks % 2 == 0:
		hide_disagree_button_temporarily()


func hide_disagree_button_temporarily():
	hidden = true
	no_button.visible = false
	hide_timer = 0.7
	text_label.text += "\n\nTlačítko NESOUHLASÍM bylo dočasně skryto."


func move_disagree_button():
	var random_x = randf_range(35, window_size.x - no_button.size.x - 35)
	var random_y = randf_range(95, window_size.y - no_button.size.y - 55)

	no_button.position = Vector2(random_x, random_y)

	var alpha = randf_range(0.42, 0.70)
	no_button.modulate = Color(1, 1, 1, alpha)

	if success_clicks >= 3:
		no_button.size = Vector2(105, 28)
		no_button.add_theme_font_size_override("font_size", 10)

	if wrong_clicks >= 3:
		no_button.text = "ne"


func finish_bonus():
	buttons_locked = true

	agree_button.visible = false
	no_button.visible = false

	background.color = Color(0.96, 0.96, 0.92)
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = (
		"KOREKČNÍ TEST DOKONČEN\n\n"
		+ "Systém uznal dočasné snížení kontroly.\n\n"
		+ "Celý postup začíná znovu."
	)

	await get_tree().create_timer(3.0).timeout
	level_finished.emit()


func style_button_soft_xp(button):
	var normal = make_button_style(Color(0.94, 0.94, 0.91), Color(0.43, 0.48, 0.58), 5)
	var hover = make_button_style(Color(0.98, 0.99, 1.0), Color(0.22, 0.47, 0.88), 5)
	var pressed = make_button_style(Color(0.76, 0.86, 0.98), Color(0.16, 0.33, 0.70), 5)
	var disabled = make_button_style(Color(0.84, 0.84, 0.82), Color(0.64, 0.64, 0.64), 5)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(0.04, 0.04, 0.04))
	button.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.43, 0.43))
	button.add_theme_font_size_override("font_size", 14)


func make_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.shadow_color = Color(1, 1, 1, 0.20)
	sb.shadow_size = 1
	return sb
