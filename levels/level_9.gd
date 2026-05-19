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
var failed = false

var progress = 0.0
var progress_max = 100.0
var click_power = 5.0
var decay_speed = 8.0
var swap_chance = 0.33

var buttons_swapped = false

var bar_position = Vector2.ZERO
var bar_size = Vector2.ZERO



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
	completed = false
	failed = false
	progress = 0.0
	buttons_swapped = false

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

	style_green_button(agree_button)
	style_red_button(no_button)

	layout_ui()
	queue_redraw()


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

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func _process(delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()

	if not completed and not failed:
		progress -= decay_speed * delta
		progress = clamp(progress, 0.0, progress_max)

	queue_redraw()


func layout_ui():
	background.position = Vector2.ZERO
	background.size = window_size

	if article_label:
		article_label.position = Vector2(70, 36)
		article_label.size = Vector2(window_size.x - 140, window_size.y - 230)
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		article_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		article_label.add_theme_font_size_override("font_size", 18)

	bar_size = Vector2(window_size.x - 180, 26)
	bar_position = Vector2(90, window_size.y - 126)

	var button_size = Vector2(180, 44)
	var spacing = 80
	var total_width = button_size.x * 2 + spacing
	var start_x = window_size.x / 2.0 - total_width / 2.0
	var button_y = window_size.y - 68

	no_button.size = button_size
	agree_button.size = button_size

	if buttons_swapped:
		# Prohozené pozice
		agree_button.position = Vector2(start_x, button_y)
		no_button.position = Vector2(start_x + button_size.x + spacing, button_y)
	else:
		# Start: Nesouhlasím vlevo, Souhlasím vpravo
		no_button.position = Vector2(start_x, button_y)
		agree_button.position = Vector2(start_x + button_size.x + spacing, button_y)


func _draw():
	draw_progress_bar()


func draw_progress_bar():
	var bg_rect = Rect2(bar_position, bar_size)
	var fill_width = bar_size.x * (progress / progress_max)
	var fill_rect = Rect2(bar_position, Vector2(fill_width, bar_size.y))

	# pozadí baru
	draw_rect(bg_rect, Color(0.12, 0.25, 0.32), true)

	# vyplnění baru
	if fill_width > 0:
		draw_rect(fill_rect, Color(0.28, 0.78, 0.38), true)

	# okraj baru
	draw_rect(bg_rect, Color(0.05, 0.18, 0.24), false, 3.0)

	# procenta nad barem
	var percent_text = str(roundi(progress)) + "%"

	draw_string(
		ThemeDB.fallback_font,
		bar_position + Vector2(bar_size.x / 2.0 - 12, -12),
		percent_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.10, 0.10, 0.10)
	)


func _on_agree_pressed():
	if completed or failed:
		return

	progress += click_power
	progress = clamp(progress, 0.0, progress_max)

	if progress >= progress_max:
		finish_success()
		return

	if randf() < swap_chance:
		swap_buttons()

	queue_redraw()


func _on_no_pressed():
	if completed or failed:
		return

	fail_level()


func swap_buttons():
	buttons_swapped = not buttons_swapped
	layout_ui()


func finish_success():
	if completed:
		return

	completed = true

	agree_button.disabled = true
	no_button.disabled = true

	background.color = Color(0.84, 0.94, 0.84)

	article_label.modulate = Color(0.05, 0.38, 0.10)
	article_label.text = GameState.result_success_text


	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_finished.emit()


func fail_level():
	if failed:
		return

	failed = true

	agree_button.disabled = true
	no_button.disabled = true

	background.color = Color(0.95, 0.82, 0.82)

	article_label.modulate = Color(0.55, 0.0, 0.0)
	article_label.text = GameState.result_fail_text


	await get_tree().create_timer(GameState.result_freeze_time).timeout
	level_failed.emit()


func style_green_button(button: Button):
	var normal = make_button_style(Color(0.18, 0.62, 0.22), Color(0.08, 0.36, 0.12), 7)
	var hover = make_button_style(Color(0.25, 0.75, 0.30), Color(0.10, 0.42, 0.15), 7)
	var pressed = make_button_style(Color(0.10, 0.45, 0.16), Color(0.05, 0.26, 0.08), 7)
	var disabled = make_button_style(Color(0.52, 0.62, 0.52), Color(0.32, 0.42, 0.32), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)

	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	button.add_theme_font_size_override("font_size", 17)


func style_red_button(button: Button):
	var normal = make_button_style(Color(0.72, 0.12, 0.12), Color(0.42, 0.04, 0.04), 7)
	var hover = make_button_style(Color(0.90, 0.18, 0.18), Color(0.50, 0.05, 0.05), 7)
	var pressed = make_button_style(Color(0.52, 0.07, 0.07), Color(0.28, 0.02, 0.02), 7)
	var disabled = make_button_style(Color(0.62, 0.48, 0.48), Color(0.42, 0.30, 0.30), 7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
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
