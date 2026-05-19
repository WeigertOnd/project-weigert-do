extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var screen_state = "article"

var article_label: Label
var article_agree_button: Button
var article_no_button: Button

var instruction_label: Label
var input_label: Label
var result_label: Label
var control_label: Label
var confirm_button: Button
var delete_button: Button

var digit_buttons = []
var balls = []
var answer = ""

var completed = false
var failed = false

var count_area = Rect2(34, 38, 788, 160)


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
	screen_state = "article"
	completed = false
	failed = false
	answer = ""
	balls.clear()

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)
	result_label.visible = false

	show_article_screen()
	update_system_control_label()
	layout_ui()
	queue_redraw()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if screen_state != "game":
		return

	if completed or failed:
		return

	move_balls(delta)
	queue_redraw()


func _draw():
	if screen_state != "game":
		return

	draw_rect(count_area, Color(0.90, 0.90, 0.90), true)

	for ball in balls:
		draw_circle(ball["pos"], ball["radius"], Color(0.76, 0.67, 0.56))
		draw_arc(ball["pos"], ball["radius"], 0, TAU, 24, Color(0.48, 0.43, 0.36), 4.0)


func setup_ui():
	LevelUtils.layout_background(background, window_size)
	background.z_index = -100

	if not LevelUtils.is_valid_node(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 10
		add_child(article_label)

	if not LevelUtils.is_valid_node(article_agree_button):
		article_agree_button = Button.new()
		article_agree_button.name = "ArticleAgreeButton"
		article_agree_button.text = "Souhlasím"
		article_agree_button.focus_mode = Control.FOCUS_NONE
		article_agree_button.z_index = 12
		article_agree_button.pressed.connect(_on_article_agree_pressed)
		add_child(article_agree_button)

	if not LevelUtils.is_valid_node(article_no_button):
		article_no_button = Button.new()
		article_no_button.name = "ArticleNoButton"
		article_no_button.text = "Nesouhlasím"
		article_no_button.focus_mode = Control.FOCUS_NONE
		article_no_button.z_index = 12
		article_no_button.pressed.connect(_on_article_no_pressed)
		add_child(article_no_button)

	if not LevelUtils.is_valid_node(instruction_label):
		instruction_label = Label.new()
		instruction_label.name = "InstructionLabel"
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.add_theme_font_size_override("font_size", 19)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 10
		add_child(instruction_label)

	if not LevelUtils.is_valid_node(input_label):
		input_label = Label.new()
		input_label.name = "InputLabel"
		input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		input_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		input_label.add_theme_font_size_override("font_size", 22)
		input_label.modulate = Color(0.10, 0.10, 0.10)
		input_label.z_index = 10
		add_child(input_label)

	if not LevelUtils.is_valid_node(result_label):
		result_label = Label.new()
		result_label.name = "ResultLabel"
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 17)
		result_label.z_index = 10
		add_child(result_label)

	if not LevelUtils.is_valid_node(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 12
		add_child(control_label)

	if digit_buttons.is_empty():
		for i in range(10):
			var btn = Button.new()
			btn.name = "DigitButton" + str(i)
			btn.text = str(i)
			btn.z_index = 12
			btn.focus_mode = Control.FOCUS_NONE
			btn.pressed.connect(_on_digit_pressed.bind(str(i)))
			LevelUtils.style_blue_button(btn)
			add_child(btn)
			digit_buttons.append(btn)

	if not LevelUtils.is_valid_node(confirm_button):
		confirm_button = Button.new()
		confirm_button.name = "ConfirmButton"
		confirm_button.text = "Potvrdit"
		confirm_button.z_index = 12
		confirm_button.focus_mode = Control.FOCUS_NONE
		confirm_button.pressed.connect(_on_confirm_pressed)
		LevelUtils.style_blue_button(confirm_button)
		add_child(confirm_button)

	if not LevelUtils.is_valid_node(delete_button):
		delete_button = Button.new()
		delete_button.name = "DeleteButton"
		delete_button.text = "Smazat"
		delete_button.z_index = 12
		delete_button.focus_mode = Control.FOCUS_NONE
		delete_button.pressed.connect(_on_delete_pressed)
		LevelUtils.style_blue_button(delete_button)
		add_child(delete_button)

	LevelUtils.style_green_button(article_agree_button)
	LevelUtils.style_red_button(article_no_button)

	layout_ui()


func show_article_screen():
	screen_state = "article"

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = LevelUtils.get_article_text(article_number)

	article_no_button.visible = true
	article_no_button.disabled = false
	article_no_button.text = "Nesouhlasím"
	LevelUtils.style_red_button(article_no_button)

	article_agree_button.visible = true
	article_agree_button.disabled = false
	article_agree_button.text = "Souhlasím"
	LevelUtils.style_green_button(article_agree_button)

	instruction_label.visible = false
	input_label.visible = false
	result_label.visible = false
	confirm_button.visible = false
	delete_button.visible = false

	for btn in digit_buttons:
		btn.visible = false

	queue_redraw()


func show_game_screen():
	screen_state = "game"

	completed = false
	failed = false
	answer = ""

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = false
	article_no_button.visible = false
	article_agree_button.visible = false

	instruction_label.visible = true
	input_label.visible = true
	result_label.visible = false
	confirm_button.visible = true
	delete_button.visible = true

	for btn in digit_buttons:
		btn.visible = true

	create_balls()
	update_input_label()
	layout_ui()
	queue_redraw()


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if screen_state == "article":
		article_label.position = Vector2(70, 30)
		article_label.size = Vector2(window_size.x - 140, window_size.y - 145)

		var button_size = Vector2(180, 44)
		var spacing = 80
		var total_width = button_size.x * 2 + spacing
		var start_x = window_size.x / 2.0 - total_width / 2.0
		var button_y = window_size.y - 68

		article_no_button.size = button_size
		article_agree_button.size = button_size

		article_no_button.position = Vector2(start_x, button_y)
		article_agree_button.position = Vector2(start_x + button_size.x + spacing, button_y)

		update_system_control_label_position()
		return

	count_area = Rect2(34, 38, window_size.x - 68, 160)

	instruction_label.position = Vector2(80, 214)
	instruction_label.size = Vector2(window_size.x - 160, 46)
	instruction_label.text = "Kolik kuliček je nahoře?"

	input_label.position = Vector2(120, 268)
	input_label.size = Vector2(window_size.x - 240, 48)

	result_label.position = Vector2(70, window_size.y - 74)
	result_label.size = Vector2(window_size.x - 140, 30)

	var start_x = window_size.x / 2.0 - 294.0
	var y1 = 330.0
	var y2 = 396.0

	for i in range(5):
		digit_buttons[i].position = Vector2(start_x + i * 80.0, y1)
		digit_buttons[i].size = Vector2(66, 50)

	for i in range(5, 10):
		digit_buttons[i].position = Vector2(start_x + (i - 5) * 80.0, y2)
		digit_buttons[i].size = Vector2(66, 50)

	confirm_button.position = Vector2(start_x + 430, y1)
	confirm_button.size = Vector2(176, 50)

	delete_button.position = Vector2(start_x + 430, y2)
	delete_button.size = Vector2(176, 50)

	update_system_control_label_position()


func _on_article_agree_pressed():
	if completed or failed:
		return

	show_game_screen()


func _on_article_no_pressed():
	if completed or failed:
		return

	fail_from_article()


func create_balls():
	balls.clear()

	var count = randi_range(15, 22)

	for _i in range(count):
		var radius = randf_range(12.0, 16.0)

		var pos = Vector2(
			randf_range(count_area.position.x + radius, count_area.end.x - radius),
			randf_range(count_area.position.y + radius, count_area.end.y - radius)
		)

		var vel = Vector2(
			randf_range(-135, 135),
			randf_range(-95, 95)
		)

		balls.append({
			"pos": pos,
			"vel": vel,
			"radius": radius
		})


func move_balls(delta):
	for ball in balls:
		var pos = ball["pos"] + ball["vel"] * delta
		var vel = ball["vel"]
		var radius = ball["radius"]

		if pos.x - radius < count_area.position.x or pos.x + radius > count_area.end.x:
			vel.x *= -1.0
			pos.x = clamp(pos.x, count_area.position.x + radius, count_area.end.x - radius)

		if pos.y - radius < count_area.position.y or pos.y + radius > count_area.end.y:
			vel.y *= -1.0
			pos.y = clamp(pos.y, count_area.position.y + radius, count_area.end.y - radius)

		ball["pos"] = pos
		ball["vel"] = vel


func _on_digit_pressed(digit: String):
	if completed or failed or screen_state != "game":
		return

	if answer.length() >= 2:
		return

	answer += digit
	update_input_label()


func _on_delete_pressed():
	if completed or failed or screen_state != "game":
		return

	answer = answer.substr(0, max(0, answer.length() - 1))
	update_input_label()


func _on_confirm_pressed():
	if completed or failed or screen_state != "game":
		return

	if answer == str(balls.size()):
		complete_level()
	else:
		fail_from_game()


func update_input_label():
	input_label.text = answer if answer != "" else "?"


func complete_level():
	if completed:
		return

	completed = true

	background.color = Color(0.84, 0.94, 0.84)

	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = GameState.result_success_text
	result_label.visible = true

	for btn in digit_buttons:
		btn.disabled = true

	confirm_button.disabled = true
	delete_button.disabled = true

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()

func fail_from_game():
	if failed:
		return

	failed = true

	for btn in digit_buttons:
		btn.disabled = true

	confirm_button.disabled = true
	delete_button.disabled = true

	background.color = Color(0.95, 0.82, 0.82)

	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = GameState.result_fail_text
	result_label.visible = true

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()
	
func fail_from_article():
	if failed:
		return

	failed = true

	article_no_button.disabled = true
	article_agree_button.disabled = true

	background.color = Color(0.95, 0.82, 0.82)

	article_label.modulate = Color(0.58, 0.0, 0.0)
	article_label.text = GameState.result_fail_text

	update_system_control_label()

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func update_system_control_label_position():
	LevelUtils.update_system_control_label(control_label, Vector2(window_size.x - 340, 8))


func update_system_control_label():
	LevelUtils.refresh_system_control_label(control_label)
