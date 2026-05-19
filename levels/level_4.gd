extends Node2D

const ArticleData = preload("res://data/ArticleData.gd")

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

var memory_buttons = []
var correct_button_index = -1

var reveal_time = 1.5
var shuffle_steps = 25
var shuffle_delay = 0.45
var is_shuffling = false
var can_choose = false

var grid_origin = Vector2.ZERO
var grid_cols = 4
var grid_rows = 4
var grid_button_size = Vector2(150, 48)
var grid_gap = Vector2(18, 16)


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
	correct_button_index = -1
	is_shuffling = false
	can_choose = false

	clear_memory_buttons()
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
	clear_memory_buttons()

	background.color = Color(0.96, 0.96, 0.92)

	text_label.visible = true
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"

	style_green_button(agree_button)
	style_red_button(no_button)

	layout_ui()


func show_memory_game():
	screen_state = "memory"
	clear_memory_buttons()

	background.color = Color(0.96, 0.96, 0.92)

	agree_button.visible = false
	no_button.visible = false

	text_label.visible = true
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = (
		"ZAPAMATUJ SI SOUHLAS\n\n"
		+ "Klikni na místo, kde je schované tlačítko Souhlasím."
	)

	create_memory_buttons()
	layout_ui()

	await get_tree().create_timer(reveal_time).timeout

	if screen_state != "memory":
		return

	hide_memory_button_texts()
	await shuffle_memory_buttons()

	if screen_state != "memory":
		return

	can_choose = true

func create_memory_buttons():
	var total_buttons = grid_cols * grid_rows
	correct_button_index = randi_range(0, total_buttons - 1)

	for i in range(total_buttons):
		var btn = Button.new()
		btn.name = "MemoryButton" + str(i)
		btn.z_index = 12
		btn.size = grid_button_size

		if i == correct_button_index:
			btn.text = "Souhlasím"
			style_green_button(btn)
		else:
			btn.text = "Nesouhlasím"
			style_red_button(btn)

		btn.pressed.connect(Callable(self, "_on_memory_button_pressed").bind(btn))
		add_child(btn)
		memory_buttons.append(btn)

	position_memory_buttons()


func position_memory_buttons():
	var total_width = grid_cols * grid_button_size.x + (grid_cols - 1) * grid_gap.x
	var total_height = grid_rows * grid_button_size.y + (grid_rows - 1) * grid_gap.y

	grid_origin = Vector2(
		window_size.x / 2.0 - total_width / 2.0,
		245
	)

	for i in range(memory_buttons.size()):
		var col = i % grid_cols
		var row = floori(float(i) / float(grid_cols))

		memory_buttons[i].position = grid_origin + Vector2(
			col * (grid_button_size.x + grid_gap.x),
			row * (grid_button_size.y + grid_gap.y)
		)

		memory_buttons[i].size = grid_button_size


func hide_memory_button_texts():
	for btn in memory_buttons:
		btn.text = "???"
		style_hidden_button(btn)


func shuffle_memory_buttons():
	is_shuffling = true
	can_choose = false

	for step in range(shuffle_steps):
		if screen_state != "memory":
			return

		var available_indices = []

		for i in range(memory_buttons.size()):
			available_indices.append(i)

		available_indices.shuffle()

		var pairs_count = min(4, floori(memory_buttons.size() / 2))

		var tween = create_tween()
		tween.set_parallel(true)

		for pair_index in range(pairs_count):
			var a = available_indices[pair_index * 2]
			var b = available_indices[pair_index * 2 + 1]

			var pos_a = memory_buttons[a].position
			var pos_b = memory_buttons[b].position

			tween.tween_property(
				memory_buttons[a],
				"position",
				pos_b,
				shuffle_delay
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

			tween.tween_property(
				memory_buttons[b],
				"position",
				pos_a,
				shuffle_delay
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		await tween.finished

	is_shuffling = false
	can_choose = true


func _on_memory_button_pressed(btn: Button):
	if screen_state != "memory":
		return

	if is_shuffling or not can_choose:
		return

	can_choose = false

	var selected_is_correct = false

	if btn.name == "MemoryButton" + str(correct_button_index):
		selected_is_correct = true

	reveal_all_memory_buttons()

	if selected_is_correct:
		btn.text = "Souhlasím"
		style_green_button(btn)

		text_label.modulate = Color(0.05, 0.38, 0.10)
		await get_tree().create_timer(1.2).timeout
		level_finished.emit()
	else:
		btn.text = "Nesouhlasím"
		style_red_button(btn)

		text_label.modulate = Color(0.55, 0.0, 0.0)
		await get_tree().create_timer(1.4).timeout
		level_failed.emit()


func reveal_all_memory_buttons():
	for i in range(memory_buttons.size()):
		var btn = memory_buttons[i]

		if i == correct_button_index:
			btn.text = "Souhlasím"
			style_green_button(btn)
		else:
			btn.text = "Nesouhlasím"
			style_red_button(btn)


func clear_memory_buttons():
	for btn in memory_buttons:
		if btn != null and is_instance_valid(btn):
			btn.queue_free()

	memory_buttons.clear()


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	if screen_state == "article":
		text_label.position = Vector2(70, 40)
		text_label.size = Vector2(window_size.x - 140, window_size.y - 145)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 20)

	elif screen_state == "memory":
		text_label.position = Vector2(70, 42)
		text_label.size = Vector2(window_size.x - 140, 140)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 20)

		position_memory_buttons()

	no_button.size = Vector2(180, 44)
	agree_button.size = Vector2(180, 44)

	var button_y = window_size.y - 68

	no_button.position = Vector2(window_size.x / 2.0 - 220, button_y)
	agree_button.position = Vector2(window_size.x / 2.0 + 40, button_y)


func _on_agree_pressed():
	if screen_state == "article":
		show_memory_game()


func _on_no_pressed():
	level_failed.emit()


func style_green_button(button: Button):
	var normal = make_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12), 7)
	var hover = make_button_style(Color(0.25, 0.75, 0.30), Color(0.10, 0.42, 0.15), 7)
	var pressed = make_button_style(Color(0.10, 0.45, 0.16), Color(0.05, 0.26, 0.08), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 17)


func style_red_button(button: Button):
	var normal = make_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04), 7)
	var hover = make_button_style(Color(0.90, 0.18, 0.18), Color(0.50, 0.05, 0.05), 7)
	var pressed = make_button_style(Color(0.52, 0.07, 0.07), Color(0.28, 0.02, 0.02), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 17)


func style_hidden_button(button: Button):
	var normal = make_button_style(Color(0.74, 0.74, 0.70), Color(0.42, 0.44, 0.48), 7)
	var hover = make_button_style(Color(0.82, 0.82, 0.78), Color(0.25, 0.34, 0.58), 7)
	var pressed = make_button_style(Color(0.62, 0.62, 0.60), Color(0.28, 0.30, 0.34), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.20, 0.20, 0.20))
	button.add_theme_color_override("font_hover_color", Color(0.10, 0.10, 0.10))
	button.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.05))
	button.add_theme_font_size_override("font_size", 16)


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
	return sb
