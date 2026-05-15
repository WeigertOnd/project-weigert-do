extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var text_label = $Label
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var control_label
var window_size = Vector2(856, 520)

var step = 0
var wrong_attempts = 0

var mistakes = 0
var max_mistakes = 3

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

var buttons_swapping = false
var swap_buttons_timer = 0.0
var swap_delay = 0.75


func _ready():
	start_level()


func set_window_size(new_size):
	window_size = new_size
	layout_ui()


func start_level():
	step = 0
	wrong_attempts = 0
	mistakes = 0

	buttons_swapping = false
	swap_buttons_timer = 0.0
	swap_delay = 0.75

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

	agree_button.text = "Jsem člověk"
	no_button.text = "Chci nesouhlasit"

	style_button_soft_xp(agree_button)
	style_button_soft_xp(no_button)
	center_buttons()

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	update_system_control_label()
	set_text("KONTROLA IDENTITY\n\nSystém tvrdí, že po ověření identity obnoví tlačítko NESOUHLASÍM.")


func _process(delta):
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

	if buttons_swapping and not buttons_locked:
		swap_buttons_timer -= delta

		if swap_buttons_timer <= 0:
			swap_buttons_timer = swap_delay
			swap_button_texts()


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

	text_label.size = Vector2(window_size.x - 130, 210)
	text_label.position = Vector2(65, 92)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 21)

	agree_button.size = Vector2(185, 36)
	no_button.size = Vector2(185, 36)

	center_buttons()

	original_label_position = text_label.position


func center_buttons():
	if agree_button == null or no_button == null:
		return

	if agree_button.visible and no_button.visible:
		agree_button.position = Vector2(window_size.x / 2 - 205, 330)
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

	step += 1

	if step == 1:
		GameState.add_system_control(5)
		update_system_control_label()

		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text("Ověření přijato.\n\nAnalyzuji, zda člověk může nesouhlasit...")
		agree_button.text = "Pokračovat"
		no_button.visible = false
		center_buttons()
		start_glitch()

	elif step == 2:
		GameState.add_system_control(5)
		update_system_control_label()

		set_text("Výsledek analýzy:\n\nČlověk může nesouhlasit pouze po dokončení další kontroly.")
		agree_button.text = "Další kontrola"
		start_glitch()

	elif step == 3:
		GameState.add_system_control(10)
		update_system_control_label()

		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text("Nesrovnalost nalezena.\n\nVaše odpovědi se příliš podobají svobodné vůli.")
		agree_button.text = "Opravit odpovědi"
		no_button.visible = true
		no_button.text = "Neopravovat"
		center_buttons()
		start_glitch()

	elif step == 4:
		buttons_swapping = true
		swap_buttons_timer = swap_delay
		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text("Závěrečná otázka:\n\nKlikněte na možnost, která podle systému znamená NESOUHLASÍM.")
		agree_button.text = "Souhlasím"
		no_button.text = "Nesouhlasím"
		center_buttons()
		start_glitch()

	elif step == 5:
		GameState.add_system_control(15)
		update_system_control_label()

		buttons_swapping = false
		no_button.visible = false
		center_buttons()
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text("Vybrali jste odpověď, kterou systém přečetl jako souhlas.\n\nIdentita ověřena.")
		agree_button.text = "Pokračovat"
		start_glitch()

	elif step == 6:
		GameState.reduce_system_control(5)
		update_system_control_label()

		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text("Tlačítko NESOUHLASÍM bude obnoveno po správě dat.\n\nPřesměrovávám...")
		agree_button.visible = false
		no_button.visible = false
		center_buttons()
		start_glitch()

		await get_tree().create_timer(2.4).timeout
		level_finished.emit()


func _on_no_pressed():
	if buttons_locked or typing:
		return

	GameState.add_system_control(10)
	update_system_control_label()

	add_mistake("Systém označil odpor při kontrole identity jako chybu.")

	if mistakes >= max_mistakes:
		return

	wrong_attempts += 1

	if buttons_swapping:
		buttons_swapping = false
		no_button.visible = false
		center_buttons()
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text(
			"Systém změnil význam tlačítka během kliknutí.\n\n"
			+ "NESOUHLASÍM bylo přečteno jako další kontrola.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		agree_button.text = "Pokračovat"
		step = 4
		start_glitch()
		return

	if wrong_attempts == 1:
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text(
			"Touha nesouhlasit byla zaznamenána jako nestandardní chování.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		no_button.text = "Chovám se standardně"
		start_glitch()

	elif wrong_attempts == 2:
		set_text(
			"Standardní uživatel nejdříve projde kontrolou.\n\n"
			+ "Nesouhlas bude dostupný později.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		no_button.visible = false
		agree_button.text = "Projít kontrolou"
		center_buttons()
		start_glitch()

	else:
		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text(
			"Opakovaný nesouhlas byl sloučen do jedné žádosti.\n\n"
			+ "Žádost čeká na kontrolu.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		no_button.visible = false
		agree_button.text = "Pokračovat"
		center_buttons()
		start_glitch()


func add_mistake(reason):
	mistakes += 1

	swap_delay = max(0.35, swap_delay - 0.15)

	start_glitch()

	if mistakes >= max_mistakes:
		trigger_level_reset(reason)


func trigger_level_reset(reason):
	lock_buttons()
	buttons_swapping = false

	agree_button.visible = false
	no_button.visible = false
	center_buttons()

	background.color = Color(0.95, 0.82, 0.82)
	text_label.modulate = Color(0.55, 0.0, 0.0)
	text_label.text = (
		"KOREKCE IDENTITY\n\n"
		+ reason
		+ "\n\nIdentita byla označena jako nestabilní.\n"
		+ "Kontrola systému: " + str(GameState.system_control) + "%\n\n"
		+ "Level bude obnoven."
	)

	await get_tree().create_timer(2.8).timeout
	start_level()


func swap_button_texts():
	var temp_text = agree_button.text
	agree_button.text = no_button.text
	no_button.text = temp_text


func start_glitch():
	glitching = true
	glitch_time = 0.35
	start_flash()


func start_flash():
	flash_original_color = background.color
	background.color = Color(0.95, 0.82, 0.82)
	flash_time = 0.07
