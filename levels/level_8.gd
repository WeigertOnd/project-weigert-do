extends Node2D

const ArticleData = preload("res://data/ArticleData.gd")

signal level_finished
signal level_failed

@onready var background = $ColorRect
@onready var agree_button = $AgreeButton
@onready var no_button = $NoButton

var article_label: Label

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var completed = false
var flash_time = 0.0


func _ready():
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
	completed = false
	flash_time = 0.0

	setup_ui()

	background.color = Color(0.96, 0.96, 0.92)

	article_label.visible = true
	article_label.modulate = Color(0.10, 0.10, 0.10)
	article_label.text = ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"

	agree_button.disabled = false
	no_button.disabled = false
	agree_button.visible = true
	no_button.visible = true

	style_green_button_no_hover_change(agree_button)
	style_red_button_no_hover_change(no_button)

	layout_ui()


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if flash_time > 0:
		flash_time -= delta

		if flash_time <= 0:
			background.color = Color(0.96, 0.96, 0.92)


func setup_ui():
	background.z_index = -10
	agree_button.z_index = 10
	no_button.z_index = 10

	if article_label == null or not is_instance_valid(article_label):
		article_label = Label.new()
		article_label.name = "ArticleLabel"
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 18)
		article_label.modulate = Color(0.10, 0.10, 0.10)
		article_label.z_index = 5
		add_child(article_label)

	agree_button.focus_mode = Control.FOCUS_NONE
	no_button.focus_mode = Control.FOCUS_NONE

	if not agree_button.mouse_entered.is_connected(_on_agree_mouse_entered):
		agree_button.mouse_entered.connect(_on_agree_mouse_entered)

	if not agree_button.mouse_exited.is_connected(_on_agree_mouse_exited):
		agree_button.mouse_exited.connect(_on_agree_mouse_exited)

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)


	if not no_button.mouse_entered.is_connected(_on_no_mouse_entered):
		no_button.mouse_entered.connect(_on_no_mouse_entered)

	if not no_button.mouse_exited.is_connected(_on_no_mouse_exited):
		no_button.mouse_exited.connect(_on_no_mouse_exited)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

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

	no_button.size = button_size
	agree_button.size = button_size

	# Nesouhlasím vlevo
	no_button.position = Vector2(start_x, button_y)

	# Souhlasím vpravo
	agree_button.position = Vector2(start_x + button_size.x + spacing, button_y)


func _on_agree_mouse_entered():
	if completed:
		return

	# Původní Souhlasím se po hoveru změní na Nesouhlasím.
	# Tohle je teď špatné tlačítko.
	agree_button.text = "Nesouhlasím"


func _on_agree_mouse_exited():
	if completed:
		return

	agree_button.text = "Souhlasím"


func _on_no_mouse_entered():
	if completed:
		return

	# Původní Nesouhlasím se po hoveru změní na Souhlasím.
	# Tohle je teď správné tlačítko.
	no_button.text = "Souhlasím"


func _on_no_mouse_exited():
	if completed:
		return

	no_button.text = "Nesouhlasím"


func _on_agree_pressed():
	if completed:
		return

	# Tohle tlačítko před hoverem říká Souhlasím,
	# ale po hoveru říká Nesouhlasím, takže je to fail.
	completed = true

	# Freeze UI
	agree_button.disabled = true
	no_button.disabled = true

	agree_button.text = "Nesouhlasím"
	no_button.text = "Souhlasím"

	article_label.modulate = Color(0.58, 0.0, 0.0)
	article_label.text = GameState.result_fail_text

	flash_time = 0.0


	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func _on_no_pressed():
	if completed:
		return

	# Tohle tlačítko před hoverem říká Nesouhlasím,
	# ale po hoveru říká Souhlasím, takže je správné.
	completed = true

	agree_button.disabled = true
	no_button.disabled = true

	agree_button.text = "Nesouhlasím"
	no_button.text = "Souhlasím"

	background.color = Color(0.84, 0.94, 0.84)
	article_label.modulate = Color(0.0, 0.50, 0.0)
	article_label.text = GameState.result_success_text


	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func start_flash():
	background.color = Color(0.95, 0.82, 0.82)
	flash_time = 0.11


func style_green_button_no_hover_change(button: Button):
	var normal = make_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12), 7)
	var pressed = make_button_style(Color(0.10, 0.45, 0.16), Color(0.05, 0.26, 0.08), 7)
	var disabled = make_button_style(Color(0.52, 0.62, 0.52), Color(0.32, 0.42, 0.32), 7)

	button.add_theme_stylebox_override("normal", normal)

	# Hover je stejný jako normal, aby se při najetí neměnila barva.
	button.add_theme_stylebox_override("hover", normal)

	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	button.add_theme_font_size_override("font_size", 17)


func style_red_button_no_hover_change(button: Button):
	var normal = make_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04), 7)
	var pressed = make_button_style(Color(0.52, 0.07, 0.07), Color(0.28, 0.02, 0.02), 7)
	var disabled = make_button_style(Color(0.62, 0.48, 0.48), Color(0.42, 0.30, 0.30), 7)

	button.add_theme_stylebox_override("normal", normal)

	# Hover je stejný jako normal.
	button.add_theme_stylebox_override("hover", normal)

	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
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
	sb.shadow_color = Color(1, 1, 1, 0.20)
	sb.shadow_size = 1
	return sb
