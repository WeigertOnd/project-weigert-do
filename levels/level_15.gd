extends Node2D

const ArticleData = preload("res://data/ArticleData.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1

var article_label: Label
var instruction_label: Label
var result_label: Label
var control_label: Label
var agree_button: Button
var agree_button_parent: Node = null

var completed = false
var failed = false

var reveal_time = 0.0

# Čím větší číslo, tím pomaleji se tlačítko zviditelňuje.
var reveal_duration = 50.0

# Pokud tlačítko dosáhne této viditelnosti a hráč neklikne, fail.
# 0.15 = 15 %
# 0.30 = 30 %
var fail_alpha_limit = 0.30

var hidden_position = Vector2.ZERO
var fail_freeze_time = 3


func _ready():
	randomize()
	start_level()


func set_article_number(new_article_number: int):
	article_number = new_article_number

	if is_inside_tree():
		start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	completed = false
	failed = false
	reveal_time = 0.0

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)

	instruction_label.visible = true
	instruction_label.modulate = Color(0.15, 0.15, 0.15)

	result_label.visible = false

	agree_button.visible = true
	agree_button.disabled = false
	agree_button.text = "Souhlasím"

	place_hidden_button()
	update_button_visibility()
	update_system_control_label()
	layout_ui()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if completed or failed:
		return

	reveal_time = min(reveal_duration, reveal_time + delta)
	update_button_visibility()

	var alpha = clamp(reveal_time / reveal_duration, 0.0, 1.0)

	if alpha >= fail_alpha_limit:
		fail_level()


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = -10

	if article_label == null or not is_instance_valid(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 5
		add_child(article_label)

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 16)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 20
		add_child(instruction_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.add_theme_font_size_override("font_size", 20)
		result_label.z_index = 30
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 40
		add_child(control_label)

	if agree_button == null or not is_instance_valid(agree_button):
		agree_button = Button.new()
		agree_button.name = "InvisibleAgreeButton"
		agree_button.text = "Souhlasím"
		agree_button.size = Vector2(95, 28)
		agree_button.z_index = 999
		agree_button.focus_mode = Control.FOCUS_NONE
		agree_button.pressed.connect(_on_agree_pressed)

		agree_button_parent = get_tree().current_scene
		agree_button_parent.add_child(agree_button)

	style_green_button(agree_button)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	if article_label:
		article_label.position = Vector2(70, 30)
		article_label.size = Vector2(window_size.x - 140, 315)
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)

	if instruction_label:
		instruction_label.position = Vector2(70, 350)
		instruction_label.size = Vector2(window_size.x - 140, 50)

	if result_label:
		result_label.position = Vector2(70, window_size.y - 108)
		result_label.size = Vector2(window_size.x - 140, 50)

	update_system_control_label_position()


func get_random_position_outside_game_window() -> Vector2:
	var screen_rect = get_viewport_rect()
	var btn_size = agree_button.size

	# Herní okno / obsah levelu. Grow dává bezpečný odstup.
	var forbidden_rect = background.get_global_rect().grow(18)

	var possible_rects = []

	# Nad oknem
	possible_rects.append(Rect2(
		Vector2(10, 10),
		Vector2(
			screen_rect.size.x - btn_size.x - 20,
			forbidden_rect.position.y - btn_size.y - 20
		)
	))

	# Pod oknem
	possible_rects.append(Rect2(
		Vector2(10, forbidden_rect.position.y + forbidden_rect.size.y + 10),
		Vector2(
			screen_rect.size.x - btn_size.x - 20,
			screen_rect.size.y - forbidden_rect.position.y - forbidden_rect.size.y - btn_size.y - 20
		)
	))

	# Vlevo od okna
	possible_rects.append(Rect2(
		Vector2(10, 10),
		Vector2(
			forbidden_rect.position.x - btn_size.x - 20,
			screen_rect.size.y - btn_size.y - 20
		)
	))

	# Vpravo od okna
	possible_rects.append(Rect2(
		Vector2(forbidden_rect.position.x + forbidden_rect.size.x + 10, 10),
		Vector2(
			screen_rect.size.x - forbidden_rect.position.x - forbidden_rect.size.x - btn_size.x - 20,
			screen_rect.size.y - btn_size.y - 20
		)
	))

	var valid_rects = []

	for rect in possible_rects:
		if rect.size.x > 20 and rect.size.y > 20:
			valid_rects.append(rect)

	# Kdyby okno zabíralo skoro celou obrazovku,
	# dáme tlačítko aspoň do rohu viewportu.
	if valid_rects.is_empty():
		return Vector2(20, screen_rect.size.y - btn_size.y - 20)

	var chosen_rect = valid_rects.pick_random()

	return Vector2(
		randf_range(chosen_rect.position.x, chosen_rect.position.x + chosen_rect.size.x),
		randf_range(chosen_rect.position.y, chosen_rect.position.y + chosen_rect.size.y)
	)


func place_hidden_button():
	hidden_position = get_random_position_outside_game_window()
	agree_button.position = hidden_position


func update_button_visibility():
	var alpha = clamp(reveal_time / reveal_duration, 0.0, 1.0)
	agree_button.modulate = Color(1, 1, 1, alpha)


func _on_agree_pressed():
	if completed or failed:
		return

	complete_level()


func complete_level():
	if completed:
		return

	completed = true

	if agree_button != null and is_instance_valid(agree_button):
		agree_button.disabled = true
		agree_button.modulate = Color(1, 1, 1, 1)

	background.color = Color(0.84, 0.94, 0.84)

	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.visible = true

	GameState.reduce_system_control(5)
	update_system_control_label()

	await get_tree().create_timer(0.9).timeout
	cleanup_outside_button()
	level_finished.emit()


func fail_level():
	if failed:
		return

	failed = true

	if agree_button != null and is_instance_valid(agree_button):
		agree_button.disabled = true
		agree_button.modulate = Color(1, 1, 1, fail_alpha_limit)

	background.color = Color(0.95, 0.82, 0.82)

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = "Uživateli trvá souhlas příliš dlouho."
	result_label.visible = true

	GameState.add_system_control(8)
	update_system_control_label()

	await get_tree().create_timer(fail_freeze_time).timeout
	cleanup_outside_button()
	level_failed.emit()


func cleanup_outside_button():
	if agree_button != null and is_instance_valid(agree_button):
		agree_button.queue_free()
		agree_button = null


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return

	control_label.position = Vector2(window_size.x - 340, 8)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_green_button(button: Button):
	var normal = make_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12))
	var hover = make_button_style(Color(0.25, 0.75, 0.30), Color(0.10, 0.42, 0.15))
	var pressed = make_button_style(Color(0.10, 0.45, 0.16), Color(0.05, 0.26, 0.08))
	var disabled = make_button_style(Color(0.52, 0.62, 0.52), Color(0.32, 0.42, 0.32))

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	button.add_theme_font_size_override("font_size", 8)


func make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	return sb
