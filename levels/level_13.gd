extends Node2D

const ArticleData = preload("res://data/ArticleData.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1

var article_label: Label
var result_label: Label
var control_label: Label

var buttons = []
var drag_button: Button = null
var drag_offset = Vector2.ZERO
var drag_start_position = Vector2.ZERO
var drag_moved = false

var completed = false
var failed = false
var highest_z = 10

var button_size = Vector2(190, 42)
var stack_gap = 0.0

var buttons_per_side = 40

var left_stack_x = 70.0
var right_stack_x = 596.0
var stack_start_y = 305.0

var correct_side = "left"
var correct_index = 59


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
	drag_button = null
	drag_offset = Vector2.ZERO
	drag_moved = false
	highest_z = 10

	clear_buttons()
	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)

	result_label.visible = true
	result_label.modulate = Color(0.12, 0.12, 0.12)
	result_label.text = ""

	choose_correct_button_position()
	create_button_stacks()
	layout_ui()
	update_system_control_label()


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
		article_label.z_index = 5
		add_child(article_label)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.add_theme_font_size_override("font_size", 17)
		result_label.z_index = 80
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 90
		add_child(control_label)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	if article_label:
		article_label.position = Vector2(70, 30)
		article_label.size = Vector2(window_size.x - 140, 230)

	if result_label:
		result_label.position = Vector2(70, 315)
		result_label.size = Vector2(window_size.x - 140, 34)

	left_stack_x = 160.0
	right_stack_x = window_size.x - 150.0 - button_size.x
	stack_start_y = 360.0

	update_system_control_label_position()


func choose_correct_button_position():
	correct_side = "left" if randi_range(0, 1) == 0 else "right"
	correct_index = randi_range(1, buttons_per_side - 1)


func create_button_stacks():
	# Vytváříme odspodu nahoru.
	# index 39 vznikne první = bude dole
	# index 0 vznikne poslední = bude nahoře

	for i in range(buttons_per_side - 1, -1, -1):
		var is_correct = correct_side == "left" and i == correct_index
		create_stack_button("left", i, is_correct)

	for i in range(buttons_per_side - 1, -1, -1):
		var is_correct = correct_side == "right" and i == correct_index
		create_stack_button("right", i, is_correct)


func create_stack_button(side: String, index: int, is_correct: bool):
	var button = Button.new()

	button.name = "AgreeButton" if is_correct else "DisagreeButton"
	button.text = "Souhlasím" if is_correct else "Nesouhlasím"
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.z_index = highest_z + (buttons_per_side - index)
	button.set_meta("correct", is_correct)
	button.set_meta("side", side)
	button.set_meta("index", index)

	# Všechna tlačítka jsou červená, i Souhlasím.
	style_red_button(button)

	var x = left_stack_x if side == "left" else right_stack_x
	var y = stack_start_y

	button.position = Vector2(x, y)

	button.gui_input.connect(_on_button_gui_input.bind(button))

	add_child(button)
	buttons.append(button)


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if drag_button != null and is_instance_valid(drag_button):
		var new_pos = to_local(get_global_mouse_position()) - drag_offset
		drag_button.position = new_pos

		if drag_button.position.distance_to(drag_start_position) > 8.0:
			drag_moved = true


func _input(event):
	if completed or failed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and drag_button != null:
			var released_button = drag_button
			drag_button = null

			if not drag_moved:
				handle_button_click(released_button)


func _on_button_gui_input(event: InputEvent, button: Button):
	if completed or failed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		drag_button = button
		drag_offset = to_local(get_global_mouse_position()) - button.position
		drag_start_position = button.position
		drag_moved = false
		bring_button_to_front(button)


func bring_button_to_front(button: Button):
	highest_z += 1
	button.z_index = highest_z


func handle_button_click(button: Button):
	if completed or failed:
		return

	var is_correct = bool(button.get_meta("correct"))

	if is_correct:
		complete_level()
	else:
		fail_level()


func complete_level():
	if completed:
		return

	completed = true
	drag_button = null

	background.color = Color(0.84, 0.94, 0.84)

	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = GameState.result_success_text
	result_label.visible = true

	for button in buttons:
		if button and is_instance_valid(button):
			button.disabled = true

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func fail_level():
	if failed:
		return

	failed = true
	drag_button = null

	background.color = Color(0.95, 0.82, 0.82)

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = GameState.result_fail_text
	result_label.visible = true

	for button in buttons:
		if button and is_instance_valid(button):
			button.disabled = true

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func clear_buttons():
	for button in buttons:
		if button and is_instance_valid(button):
			button.queue_free()

	buttons.clear()


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return

	control_label.position = Vector2(window_size.x - 340, window_size.y - 34)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_red_button(button: Button):
	var normal = make_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04), 7)
	var hover = make_button_style(Color(0.90, 0.18, 0.18), Color(0.50, 0.05, 0.05), 7)
	var pressed = make_button_style(Color(0.52, 0.07, 0.07), Color(0.28, 0.02, 0.02), 7)
	var disabled = make_button_style(Color(0.62, 0.48, 0.48), Color(0.42, 0.30, 0.30), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	button.add_theme_font_size_override("font_size", 15)


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
