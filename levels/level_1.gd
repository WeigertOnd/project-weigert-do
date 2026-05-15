extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var text_label = $Label
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var control_label
var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var no_attempts = 0
var agree_attempts = 0
var mistakes = 0
var max_mistakes = 3

var no_button_escape_distance = 105
var no_button_escape_speed = 7

var glitching = false
var glitch_time = 0.0
var original_label_position = Vector2.ZERO

var flash_time = 0.0
var flash_original_color = Color(0.96, 0.96, 0.92)

var typing = false
var full_text = ""
var typing_index = 0
var typing_speed = 0.028
var typing_timer = 0.0

var buttons_locked = false
var unlock_timer = 0.0

var no_button_running = true


func _ready():
	start_level()


func set_window_size(new_size):
	if window_size == new_size:
		return

	window_size = new_size
	layout_ui()
	last_window_size = window_size


func start_level():
	no_attempts = 0
	agree_attempts = 0
	mistakes = 0

	no_button_escape_distance = 105
	no_button_escape_speed = 7

	glitching = false
	flash_time = 0.0
	typing = false
	buttons_locked = false
	no_button_running = true

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)
	text_label.modulate = Color(0.10, 0.10, 0.10)

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"

	style_button_soft_xp(agree_button)
	style_button_soft_xp(no_button)

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	update_system_control_label()
	set_text("Před pokračováním musíte souhlasit s podmínkami.")


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	update_system_control_label_position()

	if typing:
		handle_typing(delta)

	if buttons_locked and not typing:
		unlock_timer -= delta

		if unlock_timer <= 0:
			unlock_buttons()

	if glitching:
		glitch_time -= delta

		text_label.position.x = original_label_position.x + randf_range(-3, 3)
		text_label.position.y = original_label_position.y + randf_range(-2, 2)

		if glitch_time <= 0:
			glitching = false
			text_label.position = original_label_position

	if flash_time > 0:
		flash_time -= delta

		if flash_time <= 0:
			background.color = flash_original_color

	if no_button_running and no_button.visible and not buttons_locked:
		move_no_button_away_from_mouse()


func setup_ui():
	background.z_index = 0
	text_label.z_index = 5
	agree_button.z_index = 5
	no_button.z_index = 5

	layout_ui()
	last_window_size = window_size

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.name = "SystemControlLabel"
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 10
		add_child(control_label)

	update_system_control_label_position()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	text_label.size = Vector2(window_size.x - 140, 135)
	text_label.position = Vector2(70, 128)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 22)

	agree_button.size = Vector2(132, 34)
	no_button.size = Vector2(132, 34)

	agree_button.position = Vector2(window_size.x / 2 - 150, 318)
	no_button.position = Vector2(window_size.x / 2 + 18, 318)

	original_label_position = text_label.position


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return

	control_label.position = Vector2(window_size.x - 340, window_size.y - 34)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_button_soft_xp(button):
	var normal = make_button_style(
		Color(0.94, 0.94, 0.91),
		Color(0.43, 0.48, 0.58),
		5
	)

	var hover = make_button_style(
		Color(0.98, 0.99, 1.0),
		Color(0.22, 0.47, 0.88),
		5
	)

	var pressed = make_button_style(
		Color(0.76, 0.86, 0.98),
		Color(0.16, 0.33, 0.70),
		5
	)

	var disabled = make_button_style(
		Color(0.84, 0.84, 0.82),
		Color(0.64, 0.64, 0.64),
		5
	)

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


func set_text(new_text):
	lock_buttons()
	full_text = new_text
	text_label.text = ""
	typing_index = 0
	typing_timer = 0.0
	typing = true


func handle_typing(delta):
	typing_timer += delta

	if typing_timer >= typing_speed:
		typing_timer = 0.0

		if typing_index < full_text.length():
			text_label.text += full_text[typing_index]
			typing_index += 1
		else:
			typing = false
			unlock_timer = 0.45


func lock_buttons():
	buttons_locked = true
	agree_button.disabled = true
	no_button.disabled = true


func unlock_buttons():
	buttons_locked = false
	agree_button.disabled = false
	no_button.disabled = false


func _on_agree_pressed():
	if buttons_locked or typing:
		return

	GameState.add_system_control(15)
	update_system_control_label()

	add_mistake("Kliknutí na SOUHLASÍM posílilo systém.")
	agree_attempts += 1

	if mistakes >= max_mistakes:
		return

	if agree_attempts == 1:
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text("Tohle bylo snadné.\n\nA právě proto to není správná cesta.\n\nChyby: " + str(mistakes) + "/" + str(max_mistakes))
		agree_button.text = "Souhlasím znovu"
		start_glitch()

	elif agree_attempts == 2:
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text("Systém oceňuje spolupráci.\n\nNESOUHLASÍM bude teď rychlejší.\n\nChyby: " + str(mistakes) + "/" + str(max_mistakes))
		agree_button.text = "Přestat souhlasit"
		start_glitch()

	else:
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text("Souhlas není vítězství.\n\nZkus se systému postavit.\n\nChyby: " + str(mistakes) + "/" + str(max_mistakes))
		agree_button.text = "Souhlasím"
		start_glitch()
		move_agree_button_randomly()


func _on_no_pressed():
	if buttons_locked or typing:
		return

	no_attempts += 1

	if no_attempts == 1:
		GameState.reduce_system_control(5)
		update_system_control_label()

		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text("Pokus o nesouhlas zaznamenán.\n\nTo nebylo očekáváno.")
		no_button.text = "Nesouhlasím?"
		randomize_no_button_position()
		start_glitch()

	elif no_attempts == 2:
		GameState.reduce_system_control(5)
		update_system_control_label()

		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text("Systém kontroluje vaši motivaci.\n\nProč chcete nesouhlasit?")
		no_button.text = "Protože můžu"
		agree_button.text = "Raději souhlasím"
		randomize_no_button_position()
		start_glitch()

	elif no_attempts == 3:
		GameState.add_system_control(10)
		update_system_control_label()

		no_button_running = false
		no_button.visible = false
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text("Možnost NESOUHLASÍM byla dočasně odebrána.\n\nDůvod: nevhodné použití.")
		start_glitch()

		await get_tree().create_timer(2.2).timeout

		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text("Přesměrovávám vás do nastavení soukromí...")

		await get_tree().create_timer(2.0).timeout

		level_finished.emit()


func add_mistake(reason):
	mistakes += 1
	no_button_escape_distance += 20
	no_button_escape_speed += 2

	start_glitch()

	if mistakes >= max_mistakes:
		trigger_level_reset(reason)


func trigger_level_reset(reason):
	lock_buttons()
	no_button_running = false

	agree_button.visible = false
	no_button.visible = false

	text_label.modulate = Color(0.55, 0.0, 0.0)
	text_label.text = (
		"Chyba systému\n\n"
		+ reason
		+ "\n\nKontrola systému: "
		+ str(GameState.system_control)
		+ "%\n\nLevel bude obnoven."
	)

	await get_tree().create_timer(2.8).timeout
	start_level()


func get_content_rect() -> Rect2:
	return Rect2(
		Vector2(30, 70),
		Vector2(window_size.x - 60, window_size.y - 110)
	)


func randomize_no_button_position():
	var rect = get_content_rect()

	var random_x = randf_range(rect.position.x, rect.position.x + rect.size.x - no_button.size.x)
	var random_y = randf_range(rect.position.y, rect.position.y + rect.size.y - no_button.size.y)

	no_button.position = Vector2(random_x, random_y)


func move_agree_button_randomly():
	var rect = get_content_rect()

	var random_x = randf_range(rect.position.x, rect.position.x + rect.size.x - agree_button.size.x)
	var random_y = randf_range(rect.position.y, rect.position.y + rect.size.y - agree_button.size.y)

	agree_button.position = Vector2(random_x, random_y)


func move_no_button_away_from_mouse():
	var mouse_position = to_local(get_global_mouse_position())
	var button_center = no_button.position + no_button.size / 2
	var distance = mouse_position.distance_to(button_center)

	if distance < no_button_escape_distance:
		var direction = button_center - mouse_position

		if direction.length() == 0:
			direction = Vector2(randf_range(-1, 1), randf_range(-1, 1))

		direction = direction.normalized()
		no_button.position += direction * no_button_escape_speed
		keep_no_button_inside_content()


func keep_no_button_inside_content():
	var rect = get_content_rect()

	no_button.position.x = clamp(
		no_button.position.x,
		rect.position.x,
		rect.position.x + rect.size.x - no_button.size.x
	)

	no_button.position.y = clamp(
		no_button.position.y,
		rect.position.y,
		rect.position.y + rect.size.y - no_button.size.y
	)


func start_glitch():
	glitching = true
	glitch_time = 0.35
	start_flash()


func start_flash():
	flash_original_color = background.color
	background.color = Color(0.95, 0.82, 0.82)
	flash_time = 0.07
