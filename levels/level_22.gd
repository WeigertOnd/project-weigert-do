extends Node2D

const ArticleData = preload("res://data/ArticleData.gd")

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
var code_label: Label
var countdown_label: Label
var input_box: LineEdit
var result_label: Label
var control_label: Label

var code_value = ""
var time_left = 12.0
var completed = false
var failed = false
var fail_freeze_time = 0.8


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
	time_left = 12.0
	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)
	show_article_screen()
	update_system_control_label()
	layout_ui()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()
	update_system_control_label_position()

	if screen_state != "game" or completed or failed:
		return

	time_left -= delta
	update_countdown()
	if time_left <= 0.0:
		fail_level("Čas vypršel. Kód nebyl opsán včas.")


func setup_ui():
	background.position = Vector2.ZERO
	background.size = window_size
	background.z_index = -100

	if article_label == null or not is_instance_valid(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 16)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 10
		add_child(article_label)

	if article_agree_button == null or not is_instance_valid(article_agree_button):
		article_agree_button = Button.new()
		article_agree_button.text = "Souhlasím"
		article_agree_button.focus_mode = Control.FOCUS_NONE
		article_agree_button.z_index = 12
		article_agree_button.pressed.connect(_on_article_agree_pressed)
		add_child(article_agree_button)

	if article_no_button == null or not is_instance_valid(article_no_button):
		article_no_button = Button.new()
		article_no_button.text = "Nesouhlasím"
		article_no_button.focus_mode = Control.FOCUS_NONE
		article_no_button.z_index = 12
		article_no_button.pressed.connect(_on_article_no_pressed)
		add_child(article_no_button)

	if instruction_label == null or not is_instance_valid(instruction_label):
		instruction_label = Label.new()
		instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instruction_label.add_theme_font_size_override("font_size", 18)
		instruction_label.modulate = Color(0.15, 0.15, 0.15)
		instruction_label.z_index = 20
		add_child(instruction_label)

	if code_label == null or not is_instance_valid(code_label):
		code_label = Label.new()
		code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		code_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		code_label.add_theme_font_size_override("font_size", 34)
		code_label.modulate = Color(0.08, 0.12, 0.18)
		code_label.z_index = 20
		add_child(code_label)

	if countdown_label == null or not is_instance_valid(countdown_label):
		countdown_label = Label.new()
		countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		countdown_label.add_theme_font_size_override("font_size", 20)
		countdown_label.modulate = Color(0.50, 0.0, 0.0)
		countdown_label.z_index = 20
		add_child(countdown_label)

	if input_box == null or not is_instance_valid(input_box):
		input_box = LineEdit.new()
		input_box.placeholder_text = "Opiš kód"
		input_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
		input_box.max_length = 15
		input_box.z_index = 20
		input_box.text_changed.connect(_on_input_changed)
		add_child(input_box)

	if result_label == null or not is_instance_valid(result_label):
		result_label = Label.new()
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 18)
		result_label.z_index = 20
		add_child(result_label)

	if control_label == null or not is_instance_valid(control_label):
		control_label = Label.new()
		control_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		control_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		control_label.size = Vector2(320, 24)
		control_label.add_theme_font_size_override("font_size", 13)
		control_label.modulate = Color(1.0, 0.20, 0.20)
		control_label.z_index = 25
		add_child(control_label)

	style_green_button(article_agree_button)
	style_red_button(article_no_button)
	layout_ui()


func show_article_screen():
	screen_state = "article"
	background.color = Color(0.96, 0.96, 0.92)
	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)
	article_no_button.visible = true
	article_no_button.disabled = false
	article_agree_button.visible = true
	article_agree_button.disabled = false
	set_game_visible(false)


func show_game_screen():
	screen_state = "game"
	completed = false
	failed = false
	time_left = 12.0
	code_value = make_code()
	background.color = Color(0.96, 0.96, 0.92)
	article_label.visible = false
	article_no_button.visible = false
	article_agree_button.visible = false
	set_game_visible(true)
	code_label.text = code_value
	input_box.text = ""
	input_box.grab_focus()
	result_label.visible = false
	update_countdown()
	layout_ui()


func set_game_visible(visible: bool):
	instruction_label.visible = visible
	code_label.visible = visible
	countdown_label.visible = visible
	input_box.visible = visible
	input_box.editable = visible
	result_label.visible = visible and result_label.visible


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	if screen_state == "article":
		article_label.position = Vector2(70, 30)
		article_label.size = Vector2(window_size.x - 140, window_size.y - 145)
		var article_button_size = Vector2(180, 44)
		var spacing = 80
		var total_width = article_button_size.x * 2 + spacing
		var start_x = window_size.x / 2.0 - total_width / 2.0
		var button_y = window_size.y - 68
		article_no_button.size = article_button_size
		article_agree_button.size = article_button_size
		article_no_button.position = Vector2(start_x, button_y)
		article_agree_button.position = Vector2(start_x + article_button_size.x + spacing, button_y)
		update_system_control_label_position()
		return

	instruction_label.position = Vector2(60, 78)
	instruction_label.size = Vector2(window_size.x - 120, 36)
	instruction_label.text = "Opiš dvanáctimístný kód dřív, než zmizí."
	code_label.position = Vector2(60, 144)
	code_label.size = Vector2(window_size.x - 120, 58)
	countdown_label.position = Vector2(60, 214)
	countdown_label.size = Vector2(window_size.x - 120, 34)
	input_box.position = Vector2(window_size.x / 2.0 - 180, 278)
	input_box.size = Vector2(360, 46)
	result_label.position = Vector2(70, window_size.y - 82)
	result_label.size = Vector2(window_size.x - 140, 34)
	update_system_control_label_position()


func make_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var output = ""
	for i in range(15):
		output += chars.substr(randi_range(0, chars.length() - 1), 1)
	return output


func _on_input_changed(new_text: String):
	if screen_state != "game" or completed or failed:
		return
	input_box.text = new_text.to_upper()
	input_box.caret_column = input_box.text.length()
	if input_box.text == code_value:
		complete_level()


func _on_article_agree_pressed():
	if completed or failed:
		return
	show_game_screen()


func _on_article_no_pressed():
	if completed or failed:
		return
	fail_level("Souhlas nebyl dokončen.")


func complete_level():
	completed = true
	input_box.editable = false
	background.color = Color(0.84, 0.94, 0.84)
	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Kód opsán včas."
	result_label.visible = true
	GameState.reduce_system_control(5)
	update_system_control_label()
	await get_tree().create_timer(0.9).timeout
	level_finished.emit()


func fail_level(message: String):
	if failed:
		return
	failed = true
	background.color = Color(0.95, 0.82, 0.82)
	if screen_state == "article":
		article_no_button.disabled = true
		article_agree_button.disabled = true
		article_label.modulate = Color(0.58, 0.0, 0.0)
		article_label.text = message
	else:
		input_box.editable = false
	result_label.modulate = Color(0.58, 0.0, 0.0)
	result_label.text = message
	result_label.visible = true
	GameState.add_system_control(10)
	update_system_control_label()
	await get_tree().create_timer(fail_freeze_time).timeout
	level_failed.emit()


func update_countdown():
	countdown_label.text = "Čas: " + str(max(0, ceili(time_left))) + " s"


func update_system_control_label_position():
	if control_label == null or not is_instance_valid(control_label):
		return
	control_label.position = Vector2(window_size.x - 340, 8)
	control_label.text = GameState.get_system_control_text()


func update_system_control_label():
	if control_label != null and is_instance_valid(control_label):
		control_label.text = GameState.get_system_control_text()


func style_green_button(button: Button):
	button.add_theme_stylebox_override("normal", make_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(0.25, 0.75, 0.30), Color(0.10, 0.42, 0.15)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color(0.10, 0.45, 0.16), Color(0.05, 0.26, 0.08)))
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 16)


func style_red_button(button: Button):
	button.add_theme_stylebox_override("normal", make_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04)))
	button.add_theme_stylebox_override("hover", make_button_style(Color(0.90, 0.18, 0.18), Color(0.50, 0.05, 0.05)))
	button.add_theme_stylebox_override("pressed", make_button_style(Color(0.52, 0.07, 0.07), Color(0.28, 0.02, 0.02)))
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 16)


func make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	return sb
