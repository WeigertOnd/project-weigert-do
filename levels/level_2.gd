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

var code_length = 4
var max_attempts = 20

var secret_code = ""
var current_guess = ""
var attempts = 0
var guess_history = []

var history_label: Label


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
	secret_code = ""
	current_guess = ""
	attempts = 0
	guess_history.clear()

	setup_ui()
	show_article_screen()


func setup_ui():
	background.z_index = 0
	text_label.z_index = 5
	agree_button.z_index = 5
	no_button.z_index = 5

	background.color = Color(0.96, 0.96, 0.92)

	if history_label == null or not is_instance_valid(history_label):
		history_label = Label.new()
		history_label.name = "HistoryLabel"
		history_label.z_index = 5
		history_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		history_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		history_label.add_theme_font_size_override("font_size", 16)
		history_label.modulate = Color(0.10, 0.10, 0.10)
		add_child(history_label)

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func show_article_screen():
	screen_state = "article"

	background.color = Color(0.96, 0.96, 0.92)

	text_label.text = ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)
	text_label.modulate = Color(0.10, 0.10, 0.10)

	if history_label:
		history_label.visible = false
		history_label.text = ""

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"

	style_green_button(agree_button)
	style_red_button(no_button)

	layout_ui()


func show_code_game_screen():
	screen_state = "code_game"

	secret_code = generate_secret_code()
	current_guess = ""
	attempts = 0
	guess_history.clear()

	background.color = Color(0.96, 0.96, 0.92)

	agree_button.visible = false
	no_button.visible = false
	agree_button.disabled = true
	no_button.disabled = true

	if history_label:
		history_label.visible = true
		history_label.text = "Historie pokusů:\n"

	text_label.modulate = Color(0.10, 0.10, 0.10)
	update_code_game_text()

	layout_ui()


func generate_secret_code() -> String:
	var code = ""

	for i in range(code_length):
		code += str(randi_range(0, 9))

	print("kód: ", code)

	return code


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()


func _unhandled_input(event):
	if screen_state != "code_game":
		return

	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if event.keycode >= KEY_0 and event.keycode <= KEY_9:
		add_digit(str(event.keycode - KEY_0))
	elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9:
		add_digit(str(event.keycode - KEY_KP_0))
	elif event.keycode == KEY_BACKSPACE:
		remove_last_digit()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		if current_guess.length() == code_length:
			check_guess()


func add_digit(digit: String):
	if current_guess.length() >= code_length:
		return

	current_guess += digit

	if current_guess.length() == code_length:
		check_guess()
	else:
		update_code_game_text()


func remove_last_digit():
	if current_guess.length() == 0:
		return

	current_guess = current_guess.substr(0, current_guess.length() - 1)
	update_code_game_text()


func check_guess():
	attempts += 1

	if current_guess == secret_code:
		text_label.modulate = Color(0.05, 0.38, 0.10)
		text_label.text = (
			"OVĚŘENÍ SOUHLASU\n\n"
			+ "Kód byl správně zadán.\n\n"
			+ "Zadaný kód: " + current_guess + "\n"
			+ "Počet pokusů: " + str(attempts) + "\n\n"
			+ "Souhlas byl ověřen."
		)

		await get_tree().create_timer(1.4).timeout
		level_finished.emit()
		return

	var hint = get_hint(secret_code, current_guess)
	var hint_text = build_hint_text(hint)
	var history_line = current_guess

	if hint_text != "":
		history_line += "  →  " + hint_text
	else:
		history_line += "  →  nic nesedí"

	guess_history.append(history_line)
	current_guess = ""

	if attempts > max_attempts:
		show_fail_screen()
		return

	update_code_game_text()


func show_fail_screen():
	text_label.modulate = Color(0.55, 0.0, 0.0)
	text_label.text = (
		"OVĚŘENÍ SOUHLASU\n\n"
		+ "Limit pokusů byl vyčerpán.\n\n"
		+ "Počet pokusů: " + str(attempts) + "/" + str(max_attempts) + "\n\n"
		+ "Pro pokračování musíte souhlasit se všemi podmínkami."
	)

	await get_tree().create_timer(1.8).timeout
	level_failed.emit()


func get_hint(code: String, guess: String) -> Dictionary:
	var correct_position = 0
	var wrong_position = 0

	var code_counts = {}
	var guess_counts = {}

	for i in range(code_length):
		var code_digit = code.substr(i, 1)
		var guess_digit = guess.substr(i, 1)

		if code_digit == guess_digit:
			correct_position += 1
		else:
			if not code_counts.has(code_digit):
				code_counts[code_digit] = 0
			code_counts[code_digit] += 1

			if not guess_counts.has(guess_digit):
				guess_counts[guess_digit] = 0
			guess_counts[guess_digit] += 1

	for digit in guess_counts.keys():
		if code_counts.has(digit):
			wrong_position += min(guess_counts[digit], code_counts[digit])

	return {
		"correct_position": correct_position,
		"wrong_position": wrong_position
	}


func build_hint_text(hint: Dictionary) -> String:
	var text = ""

	if hint["correct_position"] > 0:
		text += str(hint["correct_position"]) + " na správné pozici"

	if hint["wrong_position"] > 0:
		if text != "":
			text += ", "
		text += str(hint["wrong_position"]) + " na špatné pozici"

	return text


func update_code_game_text():
	var visible_guess = current_guess

	while visible_guess.length() < code_length:
		visible_guess += "_"

	text_label.text = (
		"OVĚŘENÍ SOUHLASU\n\n"
		+ "Zadej 4místný kód pomocí klávesnice.\n"
		+ "Číslice mohou být od 0 do 9 a mohou se opakovat.\n\n"
		+ "Aktuální zadání: " + visible_guess + "\n"
		+ "Počet pokusů: " + str(attempts) + "/" + str(max_attempts)
	)

	update_history_text()


func update_history_text():
	if history_label == null or not is_instance_valid(history_label):
		return

	var history_text = "Historie pokusů:\n"

	for item in guess_history:
		history_text += item + "\n"

	history_label.text = history_text


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

		if history_label:
			history_label.visible = false

	elif screen_state == "code_game":
		text_label.position = Vector2(60, 52)
		text_label.size = Vector2((window_size.x / 2.0) - 80, window_size.y - 120)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 18)

		if history_label:
			history_label.visible = true
			history_label.position = Vector2(window_size.x / 2.0 + 20, 52)
			history_label.size = Vector2((window_size.x / 2.0) - 70, window_size.y - 120)
			history_label.add_theme_font_size_override("font_size", 13)

	no_button.size = Vector2(180, 44)
	agree_button.size = Vector2(180, 44)

	var button_y = window_size.y - 68

	if screen_state == "article":
		no_button.position = Vector2(window_size.x / 2.0 - 220, button_y)
		agree_button.position = Vector2(window_size.x / 2.0 + 40, button_y)


func _on_agree_pressed():
	if screen_state == "article":
		show_code_game_screen()


func _on_no_pressed():
	if screen_state == "article":
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
