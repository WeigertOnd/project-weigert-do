extends Node2D

const ArticleData = preload("res://data/ArticleData.gd")

signal level_finished
signal level_failed

var background: ColorRect
var text_label: Label
var agree_button: Button
var no_button: Button

var window_size = Vector2(856, 520)
var last_window_size = Vector2.ZERO

var article_number = 1
var screen_state = "article"

var grid_buttons = {}
var mines = {}
var revealed = {}
var flagged = {}

# 7 řádků, 21 sloupců
var rows = 7
var cols = 21
var current_clickable_col = 0

# Počet min
var mine_count = 15

var grid_origin = Vector2.ZERO
var cell_size = Vector2(28, 24)
var cell_gap = 3

var path_rows = []


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
	current_clickable_col = 0

	clear_grid()
	setup_ui()
	show_article_screen()


func setup_ui():
	background = get_node_or_null("ColorRect")

	if background == null:
		background = ColorRect.new()
		background.name = "ColorRect"
		add_child(background)

	background.z_index = -10
	background.color = Color(0.96, 0.96, 0.92)

	text_label = get_node_or_null("Label")

	if text_label == null:
		text_label = Label.new()
		text_label.name = "Label"
		add_child(text_label)

	text_label.z_index = 5
	text_label.modulate = Color(0.10, 0.10, 0.10)

	agree_button = get_node_or_null("AgreeButton")

	if agree_button == null:
		agree_button = Button.new()
		agree_button.name = "AgreeButton"
		add_child(agree_button)

	no_button = get_node_or_null("NoButton")

	if no_button == null:
		no_button = Button.new()
		no_button.name = "NoButton"
		add_child(no_button)

	agree_button.z_index = 10
	no_button.z_index = 10

	if not agree_button.pressed.is_connected(_on_agree_pressed):
		agree_button.pressed.connect(_on_agree_pressed)

	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

	layout_ui()
	last_window_size = window_size


func show_article_screen():
	screen_state = "article"
	clear_grid()

	text_label.visible = true
	text_label.modulate = Color(0.10, 0.10, 0.10)
	text_label.text = ArticleData.get_title(article_number) + "\n\n" + ArticleData.get_text(article_number)

	agree_button.visible = true
	no_button.visible = true
	agree_button.disabled = false
	no_button.disabled = false

	agree_button.text = "Souhlasím"
	no_button.text = "Nesouhlasím"

	style_green_button(agree_button)
	style_red_button(no_button)

	layout_ui()


func show_mine_game():
	screen_state = "mine_game"
	current_clickable_col = 0

	agree_button.visible = false
	no_button.visible = false

	text_label.visible = true
	text_label.modulate = Color(0.10, 0.10, 0.10)
	set_mine_instruction_text()

	generate_minefield()
	create_grid_buttons()
	update_grid_visuals()

	layout_ui()


func set_mine_instruction_text():
	text_label.text = (
		"HLEDÁNÍ MIN\n\n"
		+ "Dostaň se z levé strany na pravou.\n"
		+ "Levé kliknutí odkryje pole. Pravé kliknutí označí podezřelé pole.\n"
		+ "Číslo ukazuje počet min v okolí."
	)


func generate_minefield():
	mines.clear()
	revealed.clear()
	flagged.clear()
	path_rows.clear()

	# 1) Vytvoříme jednu bezpečnou cestu zleva doprava.
	var current_row = randi_range(0, rows - 1)

	for col in range(cols):
		path_rows.append(current_row)

		var direction = randi_range(-1, 1)
		current_row = clamp(current_row + direction, 0, rows - 1)

	# 2) Nejdřív nastavíme všechna pole jako bezpečná.
	for row in range(rows):
		for col in range(cols):
			var key = get_key(row, col)
			mines[key] = false
			revealed[key] = false
			flagged[key] = false

	# 3) Připravíme seznam polí, kde může být mina.
	# Mina nesmí být:
	# - v prvním sloupci
	# - v bezpečné cestě
	var possible_mine_cells = []

	for row in range(rows):
		for col in range(cols):
			if col == 0:
				continue

			if path_rows[col] == row:
				continue

			possible_mine_cells.append(get_key(row, col))

	# 4) Zamícháme seznam a položíme přesně 20 min.
	possible_mine_cells.shuffle()

	var mines_to_place = min(mine_count, possible_mine_cells.size())

	for i in range(mines_to_place):
		var key = possible_mine_cells[i]
		mines[key] = true

	print("DEBUG miny položeny: ", mines_to_place)
	print("DEBUG bezpečná cesta: ", path_rows)


func create_grid_buttons():
	# DŮLEŽITÉ:
	# Tady nesmí být clear_grid(), protože by smazalo i vygenerované miny.
	clear_grid_buttons_only()

	for row in range(rows):
		for col in range(cols):
			var button = Button.new()
			button.name = "Cell_%d_%d" % [row, col]
			button.z_index = 8
			button.size = cell_size
			button.text = ""
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(Callable(self, "_on_cell_pressed").bind(row, col))
			button.gui_input.connect(Callable(self, "_on_cell_gui_input").bind(row, col))

			add_child(button)
			grid_buttons[get_key(row, col)] = button

	position_grid_buttons()


func position_grid_buttons():
	var total_width = cols * cell_size.x + (cols - 1) * cell_gap

	grid_origin = Vector2(
		window_size.x / 2.0 - total_width / 2.0,
		190
	)

	for row in range(rows):
		for col in range(cols):
			var key = get_key(row, col)

			if not grid_buttons.has(key):
				continue

			var button = grid_buttons[key]
			button.position = grid_origin + Vector2(
				col * (cell_size.x + cell_gap),
				row * (cell_size.y + cell_gap)
			)

			button.size = cell_size


func update_grid_visuals():
	for row in range(rows):
		for col in range(cols):
			var key = get_key(row, col)

			if not grid_buttons.has(key):
				continue

			var button = grid_buttons[key]
			var is_revealed = revealed.get(key, false)
			var is_flagged = flagged.get(key, false)
			var is_clickable = col <= current_clickable_col and not is_revealed

			button.disabled = not is_clickable

			if is_revealed:
				var count = get_adjacent_mine_count(row, col)
				button.text = str(count)
				style_revealed_cell(button, count)

			elif col <= current_clickable_col:
				if is_flagged:
					button.text = "⚑"
					style_flagged_cell(button)
				else:
					button.text = ""
					style_clickable_cell(button)

			else:
				button.text = ""
				style_locked_cell(button)


func _on_cell_pressed(row: int, col: int):
	if screen_state != "mine_game":
		return

	if col > current_clickable_col:
		return

	var key = get_key(row, col)

	if revealed.get(key, false):
		return

	if flagged.get(key, false):
		return

	if mines.get(key, false):
		reveal_mine(row, col)
		return

	reveal_safe_cell(row, col)


func _on_cell_gui_input(event: InputEvent, row: int, col: int):
	if screen_state != "mine_game":
		return

	if not event is InputEventMouseButton:
		return

	if not event.pressed:
		return

	if event.button_index != MOUSE_BUTTON_RIGHT:
		return

	if col > current_clickable_col:
		return

	var key = get_key(row, col)

	if revealed.get(key, false):
		return

	flagged[key] = not flagged.get(key, false)

	update_grid_visuals()


func reveal_safe_cell(row: int, col: int):
	var key = get_key(row, col)
	revealed[key] = true
	flagged[key] = false

	if col == current_clickable_col:
		current_clickable_col += 1

	if current_clickable_col >= cols:
		win_level()
		return

	update_grid_visuals()

	text_label.modulate = Color(0.10, 0.10, 0.10)
	set_mine_instruction_text()


func reveal_mine(row: int, col: int):
	var key = get_key(row, col)
	revealed[key] = true
	flagged[key] = false

	if grid_buttons.has(key):
		var button = grid_buttons[key]
		button.text = "✕"
		style_mine_cell(button)

	text_label.modulate = Color(0.55, 0.0, 0.0)
	text_label.text = (
		"MINA NALEZENA\n\n"
		+ "Pro pokračování musíte souhlasit se všemi podmínkami."
	)

	for button in grid_buttons.values():
		button.disabled = true

	await get_tree().create_timer(1.4).timeout
	level_failed.emit()


func win_level():
	for button in grid_buttons.values():
		button.disabled = true

	text_label.modulate = Color(0.05, 0.38, 0.10)
	text_label.text = (
		"CESTA VYČIŠTĚNA\n\n"
		+ "Dostal/a ses bezpečně z levé strany na pravou.\n\n"
		+ "Souhlas byl úspěšně potvrzen."
	)

	await get_tree().create_timer(1.4).timeout
	level_finished.emit()


func get_adjacent_mine_count(row: int, col: int) -> int:
	var count = 0

	for r in range(row - 1, row + 2):
		for c in range(col - 1, col + 2):
			if r == row and c == col:
				continue

			if r < 0 or r >= rows:
				continue

			if c < 0 or c >= cols:
				continue

			if mines.get(get_key(r, c), false):
				count += 1

	return count


func clear_grid_buttons_only():
	for button in grid_buttons.values():
		if button != null and is_instance_valid(button):
			button.queue_free()

	grid_buttons.clear()


func clear_grid():
	clear_grid_buttons_only()
	mines.clear()
	revealed.clear()
	flagged.clear()
	path_rows.clear()


func get_key(row: int, col: int) -> String:
	return str(row) + "_" + str(col)


func _process(_delta):
	if last_window_size != window_size:
		last_window_size = window_size
		layout_ui()


func layout_ui():
	if background:
		background.position = Vector2.ZERO
		background.size = window_size

	if screen_state == "article":
		text_label.position = Vector2(70, 40)
		text_label.size = Vector2(window_size.x - 140, window_size.y - 145)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 20)

	elif screen_state == "mine_game":
		text_label.position = Vector2(60, 20)
		text_label.size = Vector2(window_size.x - 120, 140)
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_label.add_theme_font_size_override("font_size", 17)

		position_grid_buttons()

	if agree_button and no_button:
		no_button.size = Vector2(180, 44)
		agree_button.size = Vector2(180, 44)

		var button_y = window_size.y - 68

		no_button.position = Vector2(window_size.x / 2.0 - 220, button_y)
		agree_button.position = Vector2(window_size.x / 2.0 + 40, button_y)


func _on_agree_pressed():
	if screen_state == "article":
		show_mine_game()


func _on_no_pressed():
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


func style_clickable_cell(button: Button):
	var normal = make_button_style(Color(0.92, 0.95, 1.0), Color(0.26, 0.44, 0.72), 4)
	var hover = make_button_style(Color(1.0, 1.0, 1.0), Color(0.14, 0.34, 0.78), 4)
	var pressed = make_button_style(Color(0.76, 0.84, 0.98), Color(0.12, 0.28, 0.65), 4)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.08, 0.16, 0.28))
	button.add_theme_font_size_override("font_size", 9)


func style_flagged_cell(button: Button):
	var normal = make_button_style(Color(0.96, 0.84, 0.42), Color(0.56, 0.38, 0.08), 4)
	var hover = make_button_style(Color(1.0, 0.90, 0.52), Color(0.64, 0.44, 0.10), 4)
	var pressed = make_button_style(Color(0.86, 0.72, 0.30), Color(0.46, 0.30, 0.06), 4)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.18, 0.12, 0.02))
	button.add_theme_font_size_override("font_size", 10)


func style_locked_cell(button: Button):
	var normal = make_button_style(Color(0.45, 0.56, 0.66), Color(0.22, 0.34, 0.46), 4)
	var disabled = make_button_style(Color(0.45, 0.56, 0.66), Color(0.22, 0.34, 0.46), 4)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.80, 0.86))
	button.add_theme_font_size_override("font_size", 9)


func style_revealed_cell(button: Button, count: int):
	var bg = Color(0.82, 0.88, 0.92)

	if count == 0:
		bg = Color(0.90, 0.94, 0.92)

	var normal = make_button_style(bg, Color(0.30, 0.44, 0.56), 4)
	var disabled = make_button_style(bg, Color(0.30, 0.44, 0.56), 4)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.04, 0.10, 0.18))
	button.add_theme_color_override("font_disabled_color", Color(0.04, 0.10, 0.18))
	button.add_theme_font_size_override("font_size", 9)


func style_mine_cell(button: Button):
	var normal = make_button_style(Color(0.75, 0.12, 0.16), Color(0.40, 0.02, 0.04), 4)
	var disabled = make_button_style(Color(0.75, 0.12, 0.16), Color(0.40, 0.02, 0.04), 4)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 9)


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
