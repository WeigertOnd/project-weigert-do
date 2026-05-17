extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var text_label = $Label
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var control_label
var window_size = Vector2(856, 520)

var step = 0
var deny_attempts = 0

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

var auto_changing = false
var auto_change_time = 0.0
var auto_change_step = 0
var auto_change_delay = 1.4


func _ready():
	start_level()


func set_window_size(new_size):
	window_size = new_size
	layout_ui()


func start_level():
	step = 0
	deny_attempts = 0
	mistakes = 0

	auto_changing = false
	auto_change_time = 0.0
	auto_change_step = 0
	auto_change_delay = 1.4

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

	agree_button.text = "Povolit vše"
	no_button.text = "Obnovit nesouhlasím"

	style_button_soft_xp(agree_button)
	style_button_soft_xp(no_button)
	center_buttons()

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	update_system_control_label()
	set_text("NASTAVENÍ SOUKROMÍ\n\nSystém tvrdí, že tlačítko NESOUHLASÍM lze obnovit v nastavení.")


func _process(delta):
	layout_ui()
	update_system_control_label_position()

	if typing:
		handle_typing(delta)

	if buttons_locked and not typing and not auto_changing:
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

	if auto_changing:
		handle_auto_change(delta)


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
	if buttons_locked or typing or auto_changing:
		return

	step += 1

	GameState.add_system_control(15)
	update_system_control_label()

	add_mistake("Systém zaznamenal povolení doporučeného nastavení.")

	if mistakes >= max_mistakes:
		return

	if step == 1:
		no_button.visible = false
		center_buttons()
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text(
			"Systém přijal povolení všeho.\n\n"
			+ "Tím se tlačítko NESOUHLASÍM neobnoví.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		agree_button.text = "Vrátit se"
		start_glitch()

	elif step == 2:
		no_button.visible = true
		agree_button.text = "Povolit vše"
		no_button.text = "Obnovit nesouhlasím"
		center_buttons()
		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text(
			"Nastavení bylo vráceno.\n\n"
			+ "Ale systém si vaši ochotu zapamatoval.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		start_glitch()

	else:
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text(
			"Povolit vše je rychlé.\n\n"
			+ "Ale rychlé neznamená správné.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		start_glitch()


func _on_no_pressed():
	if buttons_locked or typing or auto_changing:
		return

	deny_attempts += 1

	if deny_attempts == 1:
		GameState.reduce_system_control(5)
		update_system_control_label()

		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text("Požadavek přijat.\n\nObnovuji tlačítko NESOUHLASÍM...")
		agree_button.visible = false
		no_button.visible = false
		center_buttons()
		start_glitch()

		await get_tree().create_timer(1.2).timeout
		start_auto_privacy_change()

	elif deny_attempts == 2:
		GameState.reduce_system_control(5)
		update_system_control_label()

		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text("Obnova tlačítka vyžaduje povolení sledování.\n\nSystém čeká na vaši spolupráci.")
		agree_button.visible = true
		no_button.visible = true
		agree_button.text = "Povolit sledování"
		no_button.text = "Odmítnout spolupráci"
		center_buttons()
		start_glitch()

	else:
		GameState.reduce_system_control(5)
		update_system_control_label()

		agree_button.visible = false
		no_button.visible = false
		center_buttons()
		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text("Odmítnutí spolupráce bylo uloženo.\n\nPřesměrovávám na kontrolu identity...")
		start_glitch()

		await get_tree().create_timer(2.4).timeout
		level_finished.emit()


func add_mistake(reason):
	mistakes += 1

	auto_change_delay = max(0.7, auto_change_delay - 0.2)

	start_glitch()

	if mistakes >= max_mistakes:
		trigger_level_reset(reason)


func trigger_level_reset(reason):
	lock_buttons()
	auto_changing = false

	agree_button.visible = false
	no_button.visible = false
	center_buttons()

	background.color = Color(0.95, 0.82, 0.82)
	text_label.modulate = Color(0.55, 0.0, 0.0)
	text_label.text = (
		"KOREKCE SOUKROMÍ\n\n"
		+ reason
		+ "\n\nDoporučené nastavení bylo obnoveno.\n"
		+ "Kontrola systému: " + str(GameState.system_control) + "%\n\n"
		+ "Level bude obnoven."
	)

	await get_tree().create_timer(2.8).timeout
	start_level()


func start_auto_privacy_change():
	auto_changing = true
	auto_change_time = 0.0
	auto_change_step = 0
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = ""
	lock_buttons()


func handle_auto_change(delta):
	auto_change_time += delta

	if auto_change_time < auto_change_delay:
		return

	auto_change_time = 0.0
	auto_change_step += 1

	if auto_change_step == 1:
		text_label.text = "NASTAVENÍ SOUKROMÍ\n\nTlačítko NESOUHLASÍM: OBNOVUJE SE\nSledování: VYPNUTO\nMikrofon: ZAPNUTO\nKamera: ZAPNUTO"
		start_glitch()

	elif auto_change_step == 2:
		text_label.text = "NASTAVENÍ SOUKROMÍ\n\nTlačítko NESOUHLASÍM: OBNOVUJE SE\nSledování: VYPNUTO\nMikrofon: VYPNUTO\nKamera: ZAPNUTO"
		start_glitch()

	elif auto_change_step == 3:
		text_label.text = "NASTAVENÍ SOUKROMÍ\n\nTlačítko NESOUHLASÍM: TÉMĚŘ HOTOVO\nSledování: VYPNUTO\nMikrofon: VYPNUTO\nKamera: VYPNUTO"
		start_glitch()

	elif auto_change_step == 4:
		text_label.modulate = Color(0.55, 0.0, 0.0)
		text_label.text = "CHYBA SYNCHRONIZACE\n\nNESOUHLASÍM není kompatibilní s doporučeným nastavením."
		start_glitch()

	elif auto_change_step == 5:
		text_label.text = "Obnovuji doporučené nastavení..."
		start_glitch()

	elif auto_change_step == 6:
		text_label.modulate = Color(0.10, 0.10, 0.10)
		text_label.text = "NASTAVENÍ SOUKROMÍ\n\nTlačítko NESOUHLASÍM: ODEBRÁNO\nSledování: ZAPNUTO\nMikrofon: ZAPNUTO\nKamera: ZAPNUTO"
		start_glitch()

	elif auto_change_step == 7:
		auto_changing = false
		agree_button.visible = true
		no_button.visible = true
		agree_button.text = "Přijmout doporučení"
		no_button.text = "Zkusit znovu"
		center_buttons()
		set_text("Doporučené nastavení bylo obnoveno.\n\nChcete zkusit obnovit NESOUHLASÍM znovu?")


func start_glitch():
	glitching = true
	glitch_time = 0.35
	start_flash()


func start_flash():
	flash_original_color = background.color
	background.color = Color(0.95, 0.82, 0.82)
	flash_time = 0.07
