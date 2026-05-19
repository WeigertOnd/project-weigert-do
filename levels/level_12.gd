extends Node2D

const LevelUtils = preload("res://levels/LevelUtils.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect
@onready var target_panel = $TargetPanel
@onready var preview_panel = $PreviewPanel
@onready var r_slider = $RSlider
@onready var g_slider = $GSlider
@onready var b_slider = $BSlider
@onready var r_label = $RLabel
@onready var g_label = $GLabel
@onready var b_label = $BLabel
@onready var result_label = $ResultLabel
@onready var check_button = $CheckButton
@onready var agree_button = $NoButton

var article_label: Label

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var screen_state = "article"

var target_r = 0
var target_g = 0
var target_b = 0

var unlocked = false
var completed = false
var failed = false

var required_similarity = 92.0

var attempts = 0
var max_attempts = 5
var fail_freeze_time = 1.0


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

	unlocked = false
	completed = false
	failed = false
	attempts = 0

	target_r = randi_range(0, 255)
	target_g = randi_range(0, 255)
	target_b = randi_range(0, 255)

	setup_ui()
	background.color = Color(0.96, 0.96, 0.92)

	show_article_screen()
	layout_ui()


func setup_ui():
	background.z_index = -10

	target_panel.z_index = 3
	preview_panel.z_index = 3
	r_slider.z_index = 4
	g_slider.z_index = 4
	b_slider.z_index = 4
	r_label.z_index = 4
	g_label.z_index = 4
	b_label.z_index = 4
	result_label.z_index = 4
	check_button.z_index = 5
	agree_button.z_index = 5

	if not LevelUtils.is_valid_node(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 18)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 5
		add_child(article_label)

	check_button.focus_mode = Control.FOCUS_NONE
	agree_button.focus_mode = Control.FOCUS_NONE

	if not r_slider.value_changed.is_connected(_on_slider_changed):
		r_slider.value_changed.connect(_on_slider_changed)

	if not g_slider.value_changed.is_connected(_on_slider_changed):
		g_slider.value_changed.connect(_on_slider_changed)

	if not b_slider.value_changed.is_connected(_on_slider_changed):
		b_slider.value_changed.connect(_on_slider_changed)

	if not check_button.pressed.is_connected(_on_check_pressed):
		check_button.pressed.connect(_on_check_pressed)

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	layout_ui()
	last_window_size = window_size


func show_article_screen():
	screen_state = "article"

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = LevelUtils.get_article_text(article_number)

	target_panel.visible = false
	preview_panel.visible = false
	r_slider.visible = false
	g_slider.visible = false
	b_slider.visible = false
	r_label.visible = false
	g_label.visible = false
	b_label.visible = false
	result_label.visible = false

	check_button.visible = true
	check_button.disabled = false
	check_button.text = "Nesouhlasím"
	LevelUtils.style_red_button(check_button)

	agree_button.visible = true
	agree_button.disabled = false
	agree_button.text = "Souhlasím"
	LevelUtils.style_green_button(agree_button)

	layout_ui()


func show_game_screen():
	screen_state = "game"

	unlocked = false
	completed = false
	failed = false
	attempts = 0

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = false

	target_panel.visible = true
	preview_panel.visible = true
	r_slider.visible = true
	g_slider.visible = true
	b_slider.visible = true
	r_label.visible = true
	g_label.visible = true
	b_label.visible = true
	result_label.visible = true

	target_panel.color = rgb_color(target_r, target_g, target_b)

	r_slider.value = 128
	g_slider.value = 128
	b_slider.value = 128

	check_button.visible = true
	check_button.disabled = false
	check_button.text = "Zkontrolovat"
	LevelUtils.style_blue_button(check_button)

	agree_button.visible = true
	agree_button.disabled = true
	agree_button.text = "Souhlasím"
	LevelUtils.style_green_button(agree_button)

	result_label.modulate = Color(0.18, 0.18, 0.18)
	update_result_text()

	update_preview()
	layout_ui()


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()


func layout_ui():
	LevelUtils.layout_background(background, window_size)

	if screen_state == "article":
		if article_label:
			article_label.position = Vector2(70, 40)
			article_label.size = Vector2(window_size.x - 140, window_size.y - 145)
			article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			article_label.add_theme_font_size_override("font_size", 18)

		var button_size = Vector2(180, 44)
		var spacing = 80
		var total_width = button_size.x * 2 + spacing
		var start_x = window_size.x / 2.0 - total_width / 2.0
		var button_y = window_size.y - 68

		check_button.size = button_size
		agree_button.size = button_size

		check_button.position = Vector2(start_x, button_y)
		agree_button.position = Vector2(start_x + button_size.x + spacing, button_y)

		return

	target_panel.position = Vector2(window_size.x / 2 - 210, 72)
	target_panel.size = Vector2(170, 118)

	preview_panel.position = Vector2(window_size.x / 2 + 40, 72)
	preview_panel.size = Vector2(170, 118)

	var label_x = window_size.x / 2 - 205
	var slider_x = window_size.x / 2 - 140
	var slider_width = 280

	layout_slider_row(r_label, r_slider, "R", label_x, slider_x, 232, slider_width)
	layout_slider_row(g_label, g_slider, "G", label_x, slider_x, 282, slider_width)
	layout_slider_row(b_label, b_slider, "B", label_x, slider_x, 332, slider_width)

	result_label.position = Vector2(window_size.x / 2 - 270, 382)
	result_label.size = Vector2(540, 36)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 16)

	check_button.size = Vector2(170, 42)
	agree_button.size = Vector2(190, 42)

	check_button.position = Vector2(window_size.x / 2 - 190, 438)
	agree_button.position = Vector2(window_size.x / 2 + 20, 438)


func layout_slider_row(label: Label, slider: HSlider, prefix: String, label_x: float, slider_x: float, y: float, slider_width: float):
	label.position = Vector2(label_x, y - 2)
	label.size = Vector2(48, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.modulate = Color(0.12, 0.12, 0.12)
	label.text = prefix + ":"

	slider.position = Vector2(slider_x, y)
	slider.size = Vector2(slider_width, 24)
	slider.min_value = 0
	slider.max_value = 255
	slider.step = 1


func _on_slider_changed(_value):
	if screen_state != "game":
		return

	update_preview()


func update_preview():
	var r = int(r_slider.value)
	var g = int(g_slider.value)
	var b = int(b_slider.value)

	preview_panel.color = rgb_color(r, g, b)

	r_label.text = "R:"
	g_label.text = "G:"
	b_label.text = "B:"


func _on_check_pressed():
	if screen_state == "article":
		fail_level_from_article()
		return

	if screen_state != "game":
		return

	if unlocked or completed or failed:
		return

	var similarity = get_similarity()

	if similarity >= required_similarity:
		unlocked = true

		agree_button.disabled = false
		agree_button.text = "Souhlasím"
		LevelUtils.style_green_button(agree_button)

		check_button.disabled = true

		result_label.modulate = Color(0.0, 0.50, 0.0)
		result_label.text = "Dost blízko: " + str(int(similarity)) + " %. Souhlasím odemčeno."

		GameState.reduce_system_control(4)
	else:
		attempts += 1

		result_label.modulate = Color(0.62, 0.0, 0.0)
		result_label.text = (
			"Mimo toleranci: "
			+ str(int(similarity))
			+ " %. Pokus "
			+ str(attempts)
			+ "/"
			+ str(max_attempts)
			+ "."
		)

		GameState.add_system_control(5)

		if attempts >= max_attempts:
			fail_level_from_game()


func _on_agree_pressed():
	if screen_state == "article":
		show_game_screen()
		return

	if screen_state != "game":
		return

	if not unlocked or completed or failed:
		return

	completed = true

	agree_button.disabled = true
	check_button.disabled = true

	background.color = Color(0.84, 0.94, 0.84)

	result_label.modulate = Color(0.0, 0.50, 0.0)
	result_label.text = "Přijato."

	await get_tree().create_timer(0.7).timeout
	level_finished.emit()


func fail_level_from_article():
	if failed:
		return

	failed = true

	background.color = Color(0.95, 0.82, 0.82)

	check_button.disabled = true
	agree_button.disabled = true

	article_label.modulate = Color(0.55, 0.0, 0.0)
	article_label.text = ("SOUHLAS NEBYL DOKONČEN")


	GameState.add_system_control(8)

	await get_tree().create_timer(fail_freeze_time).timeout
	level_failed.emit()


func fail_level_from_game():
	if failed:
		return

	failed = true

	background.color = Color(0.95, 0.82, 0.82)

	check_button.disabled = true
	agree_button.disabled = true

	result_label.modulate = Color(0.56, 0.0, 0.0)
	result_label.text = "Pokusy vyčerpány: " + str(attempts) + "/" + str(max_attempts)

	GameState.add_system_control(10)

	await get_tree().create_timer(fail_freeze_time).timeout
	level_failed.emit()


func update_result_text():
	result_label.text = (
		"Tref barvu alespoň na "
		+ str(int(required_similarity))
		+ " %. Pokusy: "
		+ str(attempts)
		+ "/"
		+ str(max_attempts)
		+ "."
	)


func get_similarity() -> float:
	var dr = abs(float(int(r_slider.value) - target_r))
	var dg = abs(float(int(g_slider.value) - target_g))
	var db = abs(float(int(b_slider.value) - target_b))

	var weighted_difference = dr * 0.30 + dg * 0.59 + db * 0.11

	var similarity = 100.0 - weighted_difference

	return clamp(similarity, 0.0, 100.0)


func rgb_color(r: int, g: int, b: int) -> Color:
	return Color(float(r) / 255.0, float(g) / 255.0, float(b) / 255.0)

