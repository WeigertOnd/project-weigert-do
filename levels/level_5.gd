extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect
@onready var text_label = $Label
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var screen_state = "article"

var chaos_buttons = []
var chaos_velocities = []
var correct_button_index = -1

var button_count = 31
var wrong_button_count = 30

var button_size = Vector2(132, 34)
var min_speed = 100.0
var max_speed = 260.0

var chaos_started = false
var game_finished = false


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
	chaos_started = false
	game_finished = false
	correct_button_index = -1

	clear_chaos_buttons()
	setup_ui()
	show_article_screen()


func setup_ui():
	background.z_index = -10
	text_label.z_index = 5
	agree_button.z_index = 10
	no_button.z_index = 10

	background.color = Color(0.96, 0.96, 0.92)

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func show_article_screen():
	screen_state = "article"
	chaos_started = false
	game_finished = false

	clear_chaos_buttons()

	background.color = Color(0.96, 0.96, 0.92)

	text_label.visible = true
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = LevelUtils.get_article_text(article_number)

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"

	LevelUtils.style_green_button(agree_button)
	LevelUtils.style_red_button(no_button)

	layout_ui()


func show_chaos_game():
	screen_state = "chaos"
	chaos_started = true
	game_finished = false

	clear_chaos_buttons()

	agree_button.visible = false
	no_button.visible = false

	text_label.visible = true
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = ("NAJDI SOUHLASÍM")

	spawn_chaos_buttons()
	layout_ui()


func spawn_chaos_buttons():
	correct_button_index = randi_range(0, button_count - 1)

	for i in range(button_count):
		var button = Button.new()
		button.name = "ChaosButton" + str(i)
		button.size = button_size
		button.z_index = 12

		if i == correct_button_index:
			button.text = "Souhlasím"
		else:
			button.text = "Nesouhlasím"

		style_chaos_button(button)

		var random_x = randf_range(30, window_size.x - button.size.x - 30)
		var random_y = randf_range(135, window_size.y - button.size.y - 70)
		button.position = Vector2(random_x, random_y)

		add_child(button)
		chaos_buttons.append(button)

		var velocity = Vector2(
			randf_range(-max_speed, max_speed),
			randf_range(-max_speed, max_speed)
		)

		if velocity.length() < min_speed:
			velocity = velocity.normalized() * min_speed

			if velocity.length() == 0:
				velocity = Vector2(min_speed, min_speed)

		chaos_velocities.append(velocity)

		button.pressed.connect(Callable(self, "_on_chaos_button_pressed").bind(i))


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if chaos_started and not game_finished:
		move_chaos_buttons(delta)


func move_chaos_buttons(delta):
	for i in range(chaos_buttons.size()):
		var button = chaos_buttons[i]

		if not LevelUtils.is_valid_node(button):
			continue

		var velocity = chaos_velocities[i]
		button.position += velocity * delta

		var min_x = 10
		var max_x = window_size.x - button.size.x - 10
		var min_y = 120
		var max_y = window_size.y - button.size.y - 58

		if button.position.x < min_x:
			button.position.x = min_x
			velocity.x *= -1

		if button.position.x > max_x:
			button.position.x = max_x
			velocity.x *= -1

		if button.position.y < min_y:
			button.position.y = min_y
			velocity.y *= -1

		if button.position.y > max_y:
			button.position.y = max_y
			velocity.y *= -1

		chaos_velocities[i] = velocity


func _on_chaos_button_pressed(index: int):
	if not chaos_started or game_finished:
		return

	if index == correct_button_index:
		win_level()
	else:
		fail_level()


func win_level():
	if game_finished:
		return

	game_finished = true
	chaos_started = false

	clear_chaos_buttons()

	text_label.modulate = Color(0.05, 0.38, 0.10)
	text_label.text = GameState.result_success_text

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func fail_level():
	if game_finished:
		return

	game_finished = true
	chaos_started = false

	clear_chaos_buttons()

	text_label.modulate = Color(0.55, 0.0, 0.0)
	text_label.text = GameState.result_fail_text
	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func clear_chaos_buttons():
	for button in chaos_buttons:
		if LevelUtils.is_valid_node(button):
			button.queue_free()

	chaos_buttons.clear()
	chaos_velocities.clear()


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if screen_state == "article":
		text_label.position = Vector2(70, 40)
		text_label.size = Vector2(window_size.x - 140, window_size.y - 145)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 20)

	elif screen_state == "chaos":
		text_label.position = Vector2(70, 34)
		text_label.size = Vector2(window_size.x - 140, 90)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 18)

	no_button.size = Vector2(180, 44)
	agree_button.size = Vector2(180, 44)

	var button_y = window_size.y - 68

	no_button.position = Vector2(window_size.x / 2.0 - 220, button_y)
	agree_button.position = Vector2(window_size.x / 2.0 + 40, button_y)


func _on_agree_pressed():
	if screen_state == "article":
		show_chaos_game()


func _on_no_pressed():
	agree_button.disabled = true
	no_button.disabled = true

	text_label.modulate = Color(0.58, 0.0, 0.0)
	text_label.text = GameState.result_fail_text

	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func style_chaos_button(button: Button):
	var normal = LevelUtils.make_button_style(Color(0.94, 0.94, 0.91), Color(0.43, 0.48, 0.58), 5)
	var hover = LevelUtils.make_button_style(Color(0.98, 0.99, 1.0), Color(0.22, 0.47, 0.88), 5)
	var pressed = LevelUtils.make_button_style(Color(0.76, 0.86, 0.98), Color(0.16, 0.33, 0.70), 5)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

	button.add_theme_color_override("font_color", Color(0.04, 0.04, 0.04))
	button.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	button.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	button.add_theme_font_size_override("font_size", 12)
