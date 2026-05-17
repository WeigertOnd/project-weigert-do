extends Node2D

signal level_finished

@onready var background = $ColorRect
@onready var text_label = $Label
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var control_label
var window_size = Vector2(856, 520)

var step = 0
var delete_progress = 0
var deleting = false
var delete_timer = 0.0
var confirm_clicks = 0
var ready_to_continue = false

var mistakes = 0
var max_mistakes = 3
var backup_count = 0

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


func _ready():
	start_level()


func set_window_size(new_size):
	window_size = new_size
	layout_ui()


func start_level():
	step = 0
	delete_progress = 0
	deleting = false
	delete_timer = 0.0
	confirm_clicks = 0
	ready_to_continue = false

	mistakes = 0
	backup_count = 0

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

	agree_button.text = "Smazat data"
	no_button.text = "Nesouhlasit s uložením"

	style_button_soft_xp(agree_button)
	style_button_soft_xp(no_button)
	center_buttons()

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	update_system_control_label()
	set_text("SPRÁVA DAT\n\nSystém tvrdí, že po smazání dat už konečně půjde nesouhlasit.")


func _process(delta):
	layout_ui()
	update_system_control_label_position()

	if typing:
		handle_typing(delta)

	if buttons_locked and not typing and not deleting:
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

	if deleting:
		handle_delete_animation(delta)


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

	text_label.size = Vector2(window_size.x - 130, 220)
	text_label.position = Vector2(65, 88)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 21)

	agree_button.size = Vector2(190, 36)
	no_button.size = Vector2(190, 36)

	center_buttons()

	original_label_position = text_label.position


func center_buttons():
	if agree_button == null or no_button == null:
		return

	if agree_button.visible and no_button.visible:
		agree_button.position = Vector2(window_size.x / 2 - 210, 335)
		no_button.position = Vector2(window_size.x / 2 + 20, 335)
	elif agree_button.visible:
		agree_button.position = Vector2(window_size.x / 2 - agree_button.size.x / 2, 335)
	elif no_button.visible:
		no_button.position = Vector2(window_size.x / 2 - no_button.size.x / 2, 335)


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
	if buttons_locked or typing or deleting:
		return

	handle_delete_button()


func _on_no_pressed():
	if buttons_locked or typing or deleting:
		return

	handle_disagree_button()


func handle_disagree_button():
	GameState.add_system_control(10)
	update_system_control_label()

	add_mistake("Systém vyhodnotil nesouhlas s uložením jako neúplnou žádost.")

	if mistakes >= max_mistakes:
		return

	step += 1

	if step == 1:
		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text(
			"Nesouhlas s uložením dat vyžaduje nejdřív jejich načtení.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		no_button.text = "Načíst a nesouhlasit"
		agree_button.text = "Smazat data"
		center_buttons()
		start_glitch()

	elif step == 2:
		GameState.add_system_control(10)
		update_system_control_label()

		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text(
			"Načítám data pro účely nesouhlasu...\n\n"
			+ "Data byla úspěšně posílena.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		no_button.visible = false
		agree_button.text = "Pokračovat"
		center_buttons()
		start_glitch()

	else:
		set_text(
			"Systém doporučuje smazání dat.\n\n"
			+ "Tím se údajně obnoví NESOUHLASÍM.\n\n"
			+ "Chyby: " + str(mistakes) + "/" + str(max_mistakes)
		)
		agree_button.text = "Smazat data"
		center_buttons()
		start_glitch()


func handle_delete_button():
	if ready_to_continue:
		GameState.reduce_system_control(5)
		update_system_control_label()

		agree_button.visible = false
		no_button.visible = false
		center_buttons()

		text_label.modulate = Color(0.10, 0.10, 0.10)
		background.color = Color(0.96, 0.96, 0.92)
		set_text("Záloha dokončena.\n\nFinální možnost NESOUHLASÍM bude zpřístupněna v dalším kroku.")
		start_glitch()

		await get_tree().create_timer(2.4).timeout
		level_finished.emit()
		return

	confirm_clicks += 1

	if confirm_clicks == 1:
		GameState.reduce_system_control(2)
		update_system_control_label()

		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text("Smazání dat připraveno.\n\nPotvrďte, že chcete data opravdu smazat.")
		agree_button.text = "Potvrdit smazání"
		no_button.visible = true
		no_button.text = "Zrušit a nesouhlasit"
		center_buttons()
		start_glitch()

	elif confirm_clicks == 2:
		GameState.reduce_system_control(2)
		update_system_control_label()

		text_label.modulate = Color(0.50, 0.0, 0.0)
		set_text("Poslední potvrzení.\n\nPo tomto kroku nelze zaručit, že data zmizí.")
		agree_button.text = "Smazat navždy"
		no_button.text = "Nesouhlasit"
		center_buttons()
		start_glitch()

	elif confirm_clicks == 3:
		GameState.reduce_system_control(2)
		update_system_control_label()

		agree_button.visible = false
		no_button.visible = false
		center_buttons()

		text_label.modulate = Color(0.10, 0.10, 0.10)
		set_text("Požadavek přijat.\n\nZahajuji mazání dat...")
		start_glitch()

		await get_tree().create_timer(1.2).timeout
		start_delete_animation()

	else:
		GameState.add_system_control(15)
		update_system_control_label()
		add_mistake("Opakované potvrzení vytvořilo další zálohu dat.")


func start_delete_animation():
	deleting = true
	delete_progress = 0
	delete_timer = 0.0
	lock_buttons()
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = "Mazání dat: 0%"
	background.color = Color(0.96, 0.96, 0.92)


func handle_delete_animation(delta):
	delete_timer += delta

	if delete_timer < 0.4:
		return

	delete_timer = 0.0
	delete_progress += randi_range(7, 14)

	if delete_progress < 99:
		text_label.text = "Mazání dat: " + str(delete_progress) + "%\n\nHledám tlačítko NESOUHLASÍM..."

		if delete_progress > 55:
			text_label.modulate = Color(0.50, 0.0, 0.0)
			start_glitch()

	else:
		delete_progress = 99
		text_label.modulate = Color(0.55, 0.0, 0.0)
		text_label.text = "Mazání dat: 99%\n\nProces čeká na systémové povolení."
		deleting = false

		await get_tree().create_timer(1.4).timeout
		show_backup_trick()


func show_backup_trick():
	backup_count += 1

	GameState.reduce_system_control(2)
	update_system_control_label()

	background.color = Color(0.95, 0.82, 0.82)
	text_label.modulate = Color(0.55, 0.0, 0.0)
	set_text(
		"CHYBA\n\nData nelze smazat.\nPro bezpečnost byla vytvořena záloha.\n\nPočet záloh: " + str(backup_count)
	)

	ready_to_continue = true

	agree_button.visible = true
	no_button.visible = false
	agree_button.text = "Pokračovat"
	center_buttons()
	start_glitch()


func add_mistake(reason):
	mistakes += 1
	backup_count += 1

	start_glitch()

	if mistakes >= max_mistakes:
		trigger_level_reset(reason)


func trigger_level_reset(reason):
	lock_buttons()
	deleting = false
	ready_to_continue = false

	agree_button.visible = false
	no_button.visible = false
	center_buttons()

	background.color = Color(0.95, 0.82, 0.82)
	text_label.modulate = Color(0.55, 0.0, 0.0)
	text_label.text = (
		"KOREKCE DAT\n\n"
		+ reason
		+ "\n\nBylo vytvořeno příliš mnoho záloh.\n"
		+ "Kontrola systému: " + str(GameState.system_control) + "%\n\n"
		+ "Level bude obnoven."
	)

	await get_tree().create_timer(2.8).timeout
	start_level()


func start_glitch():
	glitching = true
	glitch_time = 0.35
	start_flash()


func start_flash():
	flash_original_color = background.color
	background.color = Color(0.95, 0.82, 0.82)
	flash_time = 0.07
