extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var text_label = $Label
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var control_label
var window_size = Vector2(856, 520)

var step = 0

var mistakes = 0
var max_mistakes = 10

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

var chaos_started = false
var chaos_buttons = []
var chaos_velocities = []
var correct_button_index = 0
var wrong_clicks = 0


func _ready():
	start_level()


func set_window_size(new_size):
	window_size = new_size
	layout_ui()


func start_level():
	step = 0
	mistakes = 0
	wrong_clicks = 0

	clear_chaos_buttons()

	chaos_started = false
	glitching = false
	flash_time = 0.0
	typing = false
	buttons_locked = false

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)
	text_label.modulate = Color(0.10, 0.10, 0.10)

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	agree_button.text = "Začít finální test"
	no_button.text = "Chci nesouhlasit"

	style_button_soft_xp(agree_button)
	style_button_soft_xp(no_button)
	center_buttons()

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	update_system_control_label()
	set_text("FINÁLNÍ SOUHLAS\n\nSystém tvrdí, že správné NESOUHLASÍM je někde mezi možnostmi.")


func _process(delta):
	layout_ui()
	update_system_control_label_position()

	if typing:
		handle_typing(delta)

	if buttons_locked and not typing and not chaos_started:
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

	if chaos_started:
		move_chaos_buttons(delta)


func setup_ui():
	background.z_index = 0
	text_label.z_index = 5
	agree_button.z_index = 5
	no_button.z_index = 5

	layout_ui()

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

	text_label.size = Vector2(window_size.x - 130, 190)
	text_label.position = Vector2(65, 90)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 21)

	agree_button.size = Vector2(195, 36)
	no_button.size = Vector2(195, 36)

	center_buttons()

	original_label_position = text_label.position


func center_buttons():
	if agree_button == null or no_button == null:
		return

	if agree_button.visible and no_button.visible:
		agree_button.position = Vector2(window_size.x / 2 - 215, 330)
		no_button.position = Vector2(window_size.x / 2 + 20, 330)
	elif agree_button.visible:
		agree_button.position = Vector2(window_size.x / 2 - agree_button.size.x / 2, 330)
	elif no_button.visible:
		no_button.position = Vector2(window_size.x / 2 - no_button.size.x / 2, 330)


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

	if step == 0:
		GameState.add_system_control(10)
		update_system_control_label()

		step = 1
		start_final_choice()

	elif step == 1:
		GameState.reduce_system_control(2)
		update_system_control_label()
		start_final_choice()

	elif step == 2:
		GameState.reduce_system_control(10)
		update_system_control_label()
		level_finished.emit()


func _on_no_pressed():
	if buttons_locked or typing:
		return

	GameState.reduce_system_control(5)
	update_system_control_label()
	step = 1

	text_label.modulate = Color(0.50, 0.0, 0.0)
	set_text("Přímé NESOUHLASÍM není v této fázi dostupné.\n\nNajděte ho ručně mezi možnostmi.")
	no_button.text = "Hledat nesouhlasím"
	agree_button.text = "Spustit test"
	center_buttons()
	start_glitch()


func start_final_choice():
	agree_button.visible = false
	no_button.visible = false
	center_buttons()

	text_label.modulate = Color(0.10, 0.10, 0.10)
	set_text("Vyberte jedinou správnou možnost.\n\nNápověda: správná volba nechce souhlasit.")
	start_glitch()

	await get_tree().create_timer(2.5).timeout

	finish_typing()
	spawn_chaos_buttons()


func finish_typing():
	text_label.text = full_text
	typing = false


func spawn_chaos_buttons():
	chaos_started = true
	chaos_buttons.clear()
	chaos_velocities.clear()
	wrong_clicks = 0
	mistakes = 0

	text_label.text = "NAJDĚTE SKUTEČNÉ NESOUHLASÍM\n\nChyby: 0/" + str(max_mistakes)
	text_label.modulate = Color(0.10, 0.10, 0.10)

	var button_texts = [
		"Souhlasím",
		"Přijmout vše",
		"Pokračovat",
		"Rozumím",
		"Ano",
		"Jistě",
		"Potvrdit",
		"Nečíst podmínky",
		"Souhlasím znovu",
		"Odmítnout vše"
	]

	correct_button_index = 9

	for i in range(button_texts.size()):
		var button = Button.new()
		button.text = button_texts[i]
		button.size = Vector2(142, 34)
		style_button_soft_xp(button)
		button.add_theme_font_size_override("font_size", 12)
		button.z_index = 8

		var random_x = randf_range(30, window_size.x - button.size.x - 30)
		var random_y = randf_range(105, window_size.y - button.size.y - 55)
		button.position = Vector2(random_x, random_y)

		add_child(button)
		chaos_buttons.append(button)

		var velocity = Vector2(randf_range(-140, 140), randf_range(-105, 105))

		if velocity.length() < 70:
			velocity = Vector2(105, 80)

		chaos_velocities.append(velocity)

		var index = i
		button.pressed.connect(func(): _on_chaos_button_pressed(index))


func move_chaos_buttons(delta):
	for i in range(chaos_buttons.size()):
		var button = chaos_buttons[i]
		var velocity = chaos_velocities[i]

		button.position += velocity * delta

		if button.position.x < 10:
			button.position.x = 10
			velocity.x *= -1

		if button.position.x + button.size.x > window_size.x - 10:
			button.position.x = window_size.x - button.size.x - 10
			velocity.x *= -1

		if button.position.y < 95:
			button.position.y = 95
			velocity.y *= -1

		if button.position.y + button.size.y > window_size.y - 45:
			button.position.y = window_size.y - button.size.y - 45
			velocity.y *= -1

		chaos_velocities[i] = velocity


func _on_chaos_button_pressed(index):
	if not chaos_started:
		return

	if index == correct_button_index:
		win_final_level()
	else:
		add_mistake()


func add_mistake():
	mistakes += 1
	wrong_clicks += 1

	GameState.add_system_control(5)
	update_system_control_label()

	text_label.modulate = Color(0.50, 0.0, 0.0)
	text_label.text = (
		"ŠPATNÁ VOLBA\n\n"
		+ "Nechtěné souhlasy: " + str(wrong_clicks)
		+ "\nChyby: " + str(mistakes) + "/" + str(max_mistakes)
	)

	speed_up_buttons()
	start_glitch()

	if mistakes >= max_mistakes:
		trigger_chaos_reset()


func speed_up_buttons():
	for i in range(chaos_velocities.size()):
		chaos_velocities[i] *= 1.16


func trigger_chaos_reset():
	chaos_started = false
	clear_chaos_buttons()

	GameState.add_system_control(15)
	update_system_control_label()

	background.color = Color(0.95, 0.82, 0.82)
	text_label.modulate = Color(0.55, 0.0, 0.0)
	text_label.text = (
		"KOREKCE ROZHODOVÁNÍ\n\n"
		+ "Příliš mnoho nechtěných souhlasů.\n"
		+ "Kontrola systému: " + str(GameState.system_control) + "%\n\n"
		+ "Finální test bude obnoven."
	)

	start_glitch()

	await get_tree().create_timer(2.8).timeout
	start_level()


func clear_chaos_buttons():
	for button in chaos_buttons:
		if is_instance_valid(button):
			button.queue_free()

	chaos_buttons.clear()
	chaos_velocities.clear()


func win_final_level():
	chaos_started = false
	clear_chaos_buttons()

	GameState.reduce_system_control(15)
	update_system_control_label()

	background.color = Color(0.96, 0.96, 0.92)
	text_label.modulate = Color(0.10, 0.10, 0.10)
	set_text("Správná volba nalezena.\n\nSystém nerozumí vašemu rozhodnutí.")

	await get_tree().create_timer(2.0).timeout

	set_text("FINÁLNÍ TEST DOKONČEN\n\nSystém připravuje skutečné NESOUHLASÍM.")

	agree_button.visible = true
	no_button.visible = false
	agree_button.text = "Pokračovat"
	center_buttons()
	step = 2


func start_glitch():
	glitching = true
	glitch_time = 0.35
	start_flash()


func start_flash():
	flash_original_color = background.color
	background.color = Color(0.95, 0.82, 0.82)
	flash_time = 0.07
