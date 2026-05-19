extends Node2D

const ARTICLE_ONE_LEVEL_CONFIG = {
	"path": "res://levels/Level0.tscn",
	"title": "Souhlasíte s článkem 1"
}

const LEVEL_CONFIGS = [
	{"path": "res://levels/Level1.tscn", "title": "Utíkající souhlas"},
	{"path": "res://levels/Level2.tscn", "title": "Kód"},
	{"path": "res://levels/Level3.tscn", "title": "Běhání"},
	{"path": "res://levels/Level4.tscn", "title": "Najdi souhlas"},
	{"path": "res://levels/Level5.tscn", "title": "Létající souhlas"},
	{"path": "res://levels/Level6.tscn", "title": "Hledání min"},
	{"path": "res://levels/Level7.tscn", "title": "Pinball"},
	{"path": "res://levels/Level8.tscn", "title": "Prohozený souhlas"},
	{"path": "res://levels/Level9.tscn", "title": "Pumpa souhlasu"},
	{"path": "res://levels/Level10.tscn", "title": "Reakce"},
	{"path": "res://levels/Level11.tscn", "title": "Odhad času"},
	{"path": "res://levels/Level12.tscn", "title": "Odhad barvy"},
	{"path": "res://levels/Level13.tscn", "title": "Překrytý souhlas"},
	{"path": "res://levels/Level14.tscn", "title": "Fronta souhlasů"},
	{"path": "res://levels/Level15.tscn", "title": "Neviditelný nesouhlas"},
	{"path": "res://levels/Level16.tscn", "title": "Utíkající nesouhlas"},
	{"path": "res://levels/Level17.tscn", "title": "Automat"},
	{"path": "res://levels/Level18.tscn", "title": "Počet kuliček"},
	{"path": "res://levels/Level19.tscn", "title": "Bodovací kulička"},
	{"path": "res://levels/Level20.tscn", "title": "Terč nesouhlasu"},
	{"path": "res://levels/Level21.tscn", "title": "Hledání slova"},
	{"path": "res://levels/Level22.tscn", "title": "Autentizační kód"}
]

var current_level = null

# permanent desktop
var desktop_background
var desktop_overlay
var desktop_game_icon
var desktop_game_label
var taskbar
var start_button
var clock_label
var start_menu
var start_menu_title
var menu_game_button
var menu_level_select_button
var menu_continue_button
var menu_shutdown_button

# fake XP / Win7 window
var window_shadow
var game_window
var title_bar
var title_bar_glow
var title_label
var content_panel
var content_root

# popup
var popup_button = null
var popup_label = null
var popup_title = null

var clock_timer = 0.0
var highest_unlocked_article = 1
var current_article_number = 1
var used_random_levels = []
var article_to_level = {}
var completed_articles = []
var testing_level_mode = false

var tos_article_titles = [
	"Článek 1: Postoje uživatelů",
	"Článek 2: Ohledy vůči vývojářům",
	"Článek 3: Postoj k chybám",
	"Článek 4: O sdílení zkušenosti",
	"Článek 5: Závislost",
	"Článek 6: Nakládání s osobními údaji",
	"Článek 7: Nakládání s herními daty",
	"Článek 8: Ohledně podvodů"
]


func _ready():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	randomize()

	GameState.max_selectable_level = get_level_count()

	build_desktop()
	layout_desktop()
	hide_game_window()
	update_clock()
	update_start_menu_buttons()


func _process(delta):
	clock_timer += delta

	if clock_timer >= 1.0:
		clock_timer = 0.0
		update_clock()

	layout_desktop()


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if start_menu and start_menu.visible:
			var click_pos = event.position

			var over_menu = Rect2(start_menu.position, start_menu.size).has_point(click_pos)
			var over_start = Rect2(start_button.position, start_button.size).has_point(click_pos)

			if not over_menu and not over_start:
				start_menu.visible = false


# =========================================================
# DESKTOP
# =========================================================

func build_desktop():
	var screen = get_viewport_rect().size

	desktop_background = TextureRect.new()
	desktop_background.name = "DesktopBackground"
	desktop_background.texture = load("res://assets/xp_background.jpg")
	desktop_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desktop_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	desktop_background.position = Vector2.ZERO
	desktop_background.size = screen
	desktop_background.z_index = -50
	add_child(desktop_background)

	desktop_overlay = ColorRect.new()
	desktop_overlay.name = "DesktopOverlay"
	desktop_overlay.color = Color(1, 1, 1, 0.02)
	desktop_overlay.position = Vector2.ZERO
	desktop_overlay.size = screen
	desktop_overlay.z_index = -49
	add_child(desktop_overlay)

	desktop_game_icon = TextureButton.new()
	desktop_game_icon.name = "DesktopGameIcon"
	var icon_path = "res://assets/app_icon.png"
	if not ResourceLoader.exists(icon_path):
		icon_path = "res://assets/app_icon.svg"
	if not ResourceLoader.exists(icon_path):
		icon_path = "res://assets/app_icon.jpg"
	var icon_texture = null
	if ResourceLoader.exists(icon_path):
		icon_texture = load(icon_path)
	else:
		icon_texture = load("res://icon.svg")

	var icon_texture_small = icon_texture
	if icon_texture != null and icon_texture.has_method("get_image"):
		var icon_image = icon_texture.get_image()
		if icon_image != null:
			icon_image.resize(60, 60, Image.INTERPOLATE_LANCZOS)
			icon_texture_small = ImageTexture.create_from_image(icon_image)

	desktop_game_icon.texture_normal = icon_texture_small
	desktop_game_icon.texture_pressed = icon_texture_small
	desktop_game_icon.texture_hover = icon_texture_small
	desktop_game_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	desktop_game_icon.clip_contents = true
	desktop_game_icon.tooltip_text = "Klikni pro spuštění hry"

	var empty_style = StyleBoxFlat.new()
	empty_style.bg_color = Color(0, 0, 0, 0)
	empty_style.border_width_left = 0
	empty_style.border_width_top = 0
	empty_style.border_width_right = 0
	empty_style.border_width_bottom = 0
	desktop_game_icon.add_theme_stylebox_override("normal", empty_style)
	desktop_game_icon.add_theme_stylebox_override("hover", empty_style)
	desktop_game_icon.add_theme_stylebox_override("pressed", empty_style)
	desktop_game_icon.add_theme_stylebox_override("focused", empty_style)
	desktop_game_icon.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	desktop_game_icon.pressed.connect(start_new_game)
	desktop_game_icon.size = Vector2(60, 60)
	add_child(desktop_game_icon)

	desktop_game_label = Label.new()
	desktop_game_label.name = "DesktopGameLabel"
	desktop_game_label.text = "Hra Installer.exe"
	desktop_game_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desktop_game_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desktop_game_label.add_theme_font_size_override("font_size", 12)
	desktop_game_label.modulate = Color(1, 1, 1)
	add_child(desktop_game_label)

	taskbar = Panel.new()
	taskbar.name = "Taskbar"
	taskbar.z_index = 50
	taskbar.add_theme_stylebox_override("panel", make_taskbar_style())
	add_child(taskbar)

	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "Start"
	start_button.z_index = 51
	style_start_button(start_button)
	start_button.pressed.connect(_on_start_pressed)
	add_child(start_button)

	clock_label = Label.new()
	clock_label.name = "ClockLabel"
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clock_label.add_theme_font_size_override("font_size", 13)
	clock_label.modulate = Color(1, 1, 1)
	clock_label.z_index = 51
	add_child(clock_label)

	start_menu = Panel.new()
	start_menu.name = "StartMenu"
	start_menu.visible = false
	start_menu.z_index = 60
	start_menu.add_theme_stylebox_override("panel", make_start_menu_style())
	add_child(start_menu)

	start_menu_title = Label.new()
	start_menu_title.name = "StartMenuTitle"
	start_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	start_menu_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_menu_title.add_theme_font_size_override("font_size", 16)
	start_menu_title.modulate = Color(1, 1, 1)
	start_menu.add_child(start_menu_title)

	menu_game_button = Button.new()
	menu_game_button.name = "MenuGameButton"
	menu_game_button.text = "Spustit hru"
	style_menu_button(menu_game_button)
	menu_game_button.pressed.connect(start_new_game)
	start_menu.add_child(menu_game_button)

	menu_level_select_button = Button.new()
	menu_level_select_button.name = "MenuLevelSelectButton"
	menu_level_select_button.text = "Vybrat level"
	style_menu_button(menu_level_select_button)
	menu_level_select_button.pressed.connect(Callable(self, "show_level_select_menu").bind(true))
	start_menu.add_child(menu_level_select_button)

	menu_continue_button = Button.new()
	menu_continue_button.name = "MenuContinueButton"
	menu_continue_button.text = "Pokračovat"
	style_menu_button(menu_continue_button)
	menu_continue_button.pressed.connect(resume_game)
	start_menu.add_child(menu_continue_button)

	menu_shutdown_button = Button.new()
	menu_shutdown_button.name = "MenuShutdownButton"
	menu_shutdown_button.text = "Vypnout"
	style_menu_button(menu_shutdown_button)
	menu_shutdown_button.pressed.connect(fake_shutdown)
	start_menu.add_child(menu_shutdown_button)

	build_game_window()


func build_game_window():
	window_shadow = Panel.new()
	window_shadow.name = "WindowShadow"
	window_shadow.visible = false
	window_shadow.z_index = 10
	window_shadow.add_theme_stylebox_override("panel", make_shadow_style())
	add_child(window_shadow)

	game_window = Panel.new()
	game_window.name = "GameWindow"
	game_window.visible = false
	game_window.z_index = 11
	game_window.add_theme_stylebox_override("panel", make_window_frame_style())
	add_child(game_window)

	title_bar = Panel.new()
	title_bar.name = "TitleBar"
	title_bar.visible = false
	title_bar.z_index = 12
	title_bar.add_theme_stylebox_override("panel", make_title_bar_style())
	add_child(title_bar)

	title_bar_glow = ColorRect.new()
	title_bar_glow.name = "TitleBarGlow"
	title_bar_glow.visible = false
	title_bar_glow.color = Color(1, 1, 1, 0.18)
	title_bar_glow.z_index = 13
	add_child(title_bar_glow)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.visible = false
	title_label.text = "I AGREE?"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.modulate = Color(1, 1, 1)
	title_label.z_index = 14
	add_child(title_label)

	content_panel = Panel.new()
	content_panel.name = "ContentPanel"
	content_panel.visible = false
	content_panel.z_index = 12
	content_panel.add_theme_stylebox_override("panel", make_content_style())
	add_child(content_panel)

	content_root = Node2D.new()
	content_root.name = "ContentRoot"
	content_root.visible = false
	content_root.z_index = 15
	add_child(content_root)


func layout_desktop():
	var screen = get_viewport_rect().size

	if desktop_background:
		desktop_background.position = Vector2.ZERO
		desktop_background.size = screen

	if desktop_overlay:
		desktop_overlay.position = Vector2.ZERO
		desktop_overlay.size = screen

	if taskbar:
		taskbar.position = Vector2(0, screen.y - 42)
		taskbar.size = Vector2(screen.x, 42)

	if desktop_game_icon:
		desktop_game_icon.position = Vector2(24, 24)
		desktop_game_icon.size = Vector2(60, 60)

	if desktop_game_label:
		desktop_game_label.position = Vector2(24, 24 + 60 + 6)
		desktop_game_label.size = Vector2(60, 18)

	if start_button:
		start_button.position = Vector2(8, screen.y - 36)
		start_button.size = Vector2(100, 30)

	if clock_label:
		clock_label.position = Vector2(screen.x - 92, screen.y - 32)
		clock_label.size = Vector2(76, 22)

	if start_menu:
		start_menu.position = Vector2(8, screen.y - 326)
		start_menu.size = Vector2(250, 280)

		if start_menu_title:
			start_menu_title.position = Vector2(14, 10)
			start_menu_title.size = Vector2(210, 30)

		if menu_game_button:
			menu_game_button.position = Vector2(18, 56)
			menu_game_button.size = Vector2(214, 40)

		if menu_level_select_button:
			menu_level_select_button.position = Vector2(18, 104)
			menu_level_select_button.size = Vector2(214, 40)

		if menu_continue_button:
			menu_continue_button.position = Vector2(18, 152)
			menu_continue_button.size = Vector2(214, 40)

		if menu_shutdown_button:
			menu_shutdown_button.position = Vector2(18, 224)
			menu_shutdown_button.size = Vector2(214, 40)

	layout_game_window()

func layout_game_window():
	var screen = get_viewport_rect().size
	var window_size = Vector2(880, 580)
	var window_pos = Vector2(
		(screen.x - window_size.x) / 2,
		(screen.y - window_size.y) / 2 - 22
	)

	if window_shadow:
		window_shadow.position = window_pos + Vector2(10, 12)
		window_shadow.size = window_size

	if game_window:
		game_window.position = window_pos
		game_window.size = window_size

	if title_bar:
		title_bar.position = window_pos + Vector2(5, 5)
		title_bar.size = Vector2(window_size.x - 10, 36)

	if title_bar_glow:
		title_bar_glow.position = window_pos + Vector2(7, 7)
		title_bar_glow.size = Vector2(window_size.x - 14, 14)

	if title_label:
		title_label.position = window_pos + Vector2(18, 11)
		title_label.size = Vector2(680, 22)

	if content_panel:
		content_panel.position = window_pos + Vector2(12, 48)
		content_panel.size = Vector2(window_size.x - 24, window_size.y - 60)

	if content_root:
		content_root.position = get_window_content_origin()

		if current_level and is_instance_valid(current_level):
			if current_level.has_method("set_window_size"):
				current_level.set_window_size(get_window_content_size())
			elif current_level.has_method("set_window_rect"):
				current_level.set_window_rect(Rect2(Vector2.ZERO, get_window_content_size()))


func get_window_content_origin() -> Vector2:
	return content_panel.position


func get_window_content_size() -> Vector2:
	return content_panel.size


func show_game_window():
	window_shadow.visible = true
	game_window.visible = true
	title_bar.visible = true
	title_bar_glow.visible = true
	title_label.visible = true
	content_panel.visible = true
	content_root.visible = true


func hide_game_window():
	window_shadow.visible = false
	game_window.visible = false
	title_bar.visible = false
	title_bar_glow.visible = false
	title_label.visible = false
	content_panel.visible = false
	content_root.visible = false


func set_window_title(new_title: String):
	if title_label:
		title_label.text = new_title


func update_clock():
	if clock_label:
		var time_text = Time.get_time_string_from_system()

		if time_text.length() >= 5:
			clock_label.text = time_text.substr(0, 5)
		else:
			clock_label.text = time_text


func update_start_menu_buttons():
	if menu_continue_button:
		menu_continue_button.disabled = current_level == null


# =========================================================
# START MENU
# =========================================================

func _on_start_pressed():
	start_menu.visible = not start_menu.visible
	update_start_menu_buttons()


func show_tos_articles_screen():
	show_popup_window(
		"Terms of Service",
		"",
		"Zpět",
		Callable(self, "go_to_desktop")
	)

	var size = get_window_content_size()

	if popup_label:
		popup_label.visible = false

	if popup_title:
		popup_title.text = "Terms of Service"
		popup_title.position = Vector2(40, 32)
		popup_title.size = Vector2(size.x - 80, 38)
		popup_title.add_theme_font_size_override("font_size", 26)

	if popup_button:
		popup_button.text = "Zpět"
		popup_button.position = Vector2(size.x / 2 - 105, size.y - 58)
		popup_button.size = Vector2(210, 38)

	var subtitle = Label.new()
	subtitle.name = "TosSubtitle"
	subtitle.text = "Hru lze spustit až po přečtení odemčeného článku"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(40, 78)
	subtitle.size = Vector2(size.x - 80, 26)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.modulate = Color(0.18, 0.18, 0.18)
	content_root.add_child(subtitle)

	var list_panel = Panel.new()
	list_panel.name = "TosListPanel"
	list_panel.position = Vector2(56, 120)
	list_panel.size = Vector2(size.x - 112, 328)
	list_panel.add_theme_stylebox_override("panel", make_tos_list_style())
	content_root.add_child(list_panel)

	var start_y = 132
	var row_height = 30
	var row_spacing = 8
	var title_width = size.x - 280

	for i in range(tos_article_titles.size()):
		var article_number = i + 1
		var y = start_y + i * (row_height + row_spacing)
		var is_unlocked = article_number <= highest_unlocked_article
		var is_completed = completed_articles.has(article_number)

		var article_label = Label.new()
		article_label.name = "TosArticleLabel" + str(article_number)
		article_label.text = tos_article_titles[i]

		article_label.position = Vector2(76, y)
		article_label.size = Vector2(title_width, row_height)
		article_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		article_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		article_label.add_theme_font_size_override("font_size", 14)

		if is_completed:
			article_label.modulate = Color(0.20, 0.48, 0.20)
		elif is_unlocked:
			article_label.modulate = Color(0.12, 0.12, 0.12)
		else:
			article_label.modulate = Color(0.55, 0.55, 0.55)

		content_root.add_child(article_label)

		var read_button = Button.new()
		read_button.name = "TosReadButton" + str(article_number)
		read_button.position = Vector2(size.x - 184, y)
		read_button.size = Vector2(108, row_height)

		if is_completed:
			read_button.text = "✓ Přečteno"
			read_button.disabled = true
			style_completed_button(read_button)
		elif is_unlocked:
			read_button.text = "Přečíst"
			read_button.disabled = false
			style_window_button(read_button)
			read_button.pressed.connect(Callable(self, "_on_tos_read_pressed").bind(article_number))
		else:
			read_button.text = "Zamčeno"
			read_button.disabled = true
			style_window_button(read_button)

		content_root.add_child(read_button)


func _on_tos_read_pressed(article_number: int):
	if article_number > highest_unlocked_article:
		return

	if completed_articles.has(article_number):
		return

	testing_level_mode = false
	current_article_number = article_number

	if article_number == 1:
		start_article_one_level()
		return

	var level_number = get_or_create_random_level_for_article(article_number)
	start_selected_level(level_number)


func get_or_create_random_level_for_article(article_number: int) -> int:
	if article_to_level.has(article_number):
		return article_to_level[article_number]

	var available_levels = []

	for level_number in range(1, get_level_count() + 1):
		if not used_random_levels.has(level_number):
			available_levels.append(level_number)

	if available_levels.is_empty():
		push_error("Nejsou dostupné žádné další levely.")
		return 1

	var random_index = randi_range(0, available_levels.size() - 1)
	var selected_level = available_levels[random_index]

	used_random_levels.append(selected_level)
	article_to_level[article_number] = selected_level

	return selected_level


func get_level_count() -> int:
	return LEVEL_CONFIGS.size()


func get_level_config(level_number: int) -> Dictionary:
	if level_number < 1 or level_number > get_level_count():
		return {}

	return LEVEL_CONFIGS[level_number - 1]


func get_level_select_label(level_number: int) -> String:
	var config = get_level_config(level_number)

	if config.is_empty():
		return "Level " + str(level_number)

	return "Level %d: %s" % [level_number, String(config["title"])]


func start_article_one_level():
	load_level(
		String(ARTICLE_ONE_LEVEL_CONFIG["path"]),
		String(ARTICLE_ONE_LEVEL_CONFIG["title"]),
		Callable(self, "finish_level_and_return_to_select").bind(0)
	)


func start_configured_level(level_number: int):
	var config = get_level_config(level_number)

	if config.is_empty():
		return

	load_level(
		String(config["path"]),
		String(config["title"]),
		Callable(self, "finish_level_and_return_to_select").bind(level_number)
	)


func make_tos_list_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.98, 0.95)
	sb.border_color = Color(0.05, 0.20, 0.30)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	return sb


func start_new_game():
	start_menu.visible = false
	reset_tos_game_progress()
	show_tos_articles_screen()

func reset_tos_game_progress():
	GameState.reset_level_progress()
	highest_unlocked_article = 1
	current_article_number = 1
	used_random_levels.clear()
	article_to_level.clear()
	completed_articles.clear()


func show_level_select_menu(show_all_levels: bool = false):
	start_menu.visible = false
	show_popup_window(
		"Vybrat level",
		"",
		"Zrušit",
		Callable(self, "go_to_desktop")
	)

	var size = get_window_content_size()

	if popup_label:
		popup_label.visible = false
	if popup_title:
		popup_title.position = Vector2(40, 18)
		popup_title.size = Vector2(size.x - 80, 34)
	if popup_button:
		popup_button.position = Vector2(size.x / 2 - 105, 462)

	var start_y = 66
	var button_width = 300
	var button_height = 30
	var button_spacing = 5
	var column_spacing = 22
	var columns = 2

	for i in range(1, get_level_count() + 1):
		var column = (i - 1) % columns
		var row = floori(float(i - 1) / float(columns))
		var total_width = button_width * columns + column_spacing
		var level_button = Button.new()
		level_button.name = "LevelButton" + str(i)
		level_button.text = get_level_select_label(i)
		level_button.position = Vector2(size.x / 2 - total_width / 2 + column * (button_width + column_spacing), start_y + row * (button_height + button_spacing))
		level_button.size = Vector2(button_width, button_height)
		style_window_button(level_button)
		if show_all_levels:
			level_button.pressed.connect(Callable(self, "start_selected_level_for_testing").bind(i))
		else:
			level_button.disabled = not GameState.is_level_unlocked(i)
			if level_button.disabled:
				level_button.text += " (zamceno)"
				level_button.modulate = Color(0.65, 0.65, 0.65)
			else:
				level_button.pressed.connect(Callable(self, "start_selected_level").bind(i))

		content_root.add_child(level_button)


func resume_game():
	start_menu.visible = false

	if current_level == null:
		start_new_game()
	else:
		show_game_window()


func fake_shutdown():
	start_menu.visible = false
	show_popup_window(
		"Vypnout systém",
		"Opravdu chcete vypnout aplikaci?",
		"Vypnout",
		Callable(self, "_really_quit")
	)


func _really_quit():
	get_tree().quit()


# =========================================================
# LEVEL LOADING
# =========================================================

func clear_window_content():
	if content_root:
		for child in content_root.get_children():
			child.queue_free()

	current_level = null
	popup_button = null
	popup_label = null
	popup_title = null

	update_start_menu_buttons()


func get_level_window_title(window_title_text: String, use_article_title: bool) -> String:
	if use_article_title:
		return "Souhlasíte s článkem " + str(current_article_number)

	return window_title_text


func load_level(level_path: String, window_title_text: String, finished_function: Callable, use_article_title: bool = true):
	clear_window_content()
	show_game_window()
	set_window_title(get_level_window_title(window_title_text, use_article_title))

	if not ResourceLoader.exists(level_path):
		show_popup_window(
			"Chyba",
			"Soubor levelu nebyl nalezen:\n" + level_path,
			"Zpět na plochu",
			Callable(self, "go_to_desktop")
		)
		return

	var level_scene = load(level_path)
	current_level = level_scene.instantiate()
	content_root.add_child(current_level)

	if current_level.has_method("set_article_number"):
		current_level.set_article_number(current_article_number)

	if current_level.has_signal("level_finished"):
		current_level.level_finished.connect(finished_function)

	if current_level.has_signal("level_failed"):
		current_level.level_failed.connect(Callable(self, "fail_tos_game"))

	if current_level.has_method("set_window_size"):
		current_level.set_window_size(get_window_content_size())
	elif current_level.has_method("set_window_rect"):
		current_level.set_window_rect(Rect2(Vector2.ZERO, get_window_content_size()))

	update_start_menu_buttons()


func go_to_desktop():
	clear_window_content()
	hide_game_window()
	start_menu.visible = false


# =========================================================
# POPUP WINDOWS
# =========================================================

func show_popup_window(window_title_text: String, body_text: String, button_text: String, next_action: Callable):
	clear_window_content()
	show_game_window()
	set_window_title(window_title_text)

	var size = get_window_content_size()

	popup_title = Label.new()
	popup_title.name = "PopupTitle"
	popup_title.text = window_title_text
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_title.position = Vector2(40, 72)
	popup_title.size = Vector2(size.x - 80, 44)
	popup_title.add_theme_font_size_override("font_size", 28)
	popup_title.modulate = Color(0.1, 0.1, 0.1)
	content_root.add_child(popup_title)

	popup_label = Label.new()
	popup_label.name = "PopupLabel"
	popup_label.text = body_text
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.position = Vector2(70, 166)
	popup_label.size = Vector2(size.x - 140, 170)
	popup_label.add_theme_font_size_override("font_size", 20)
	popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_label.modulate = Color(0.15, 0.15, 0.15)
	content_root.add_child(popup_label)

	popup_button = Button.new()
	popup_button.name = "PopupButton"
	popup_button.text = button_text
	popup_button.position = Vector2(size.x / 2 - 105, 382)
	popup_button.size = Vector2(210, 42)
	style_window_button(popup_button)
	content_root.add_child(popup_button)

	if next_action.is_valid():
		popup_button.pressed.connect(next_action)

	update_start_menu_buttons()


func show_final_screen():
	show_popup_window(
		"Podmínky odsouhlaseny",
		"Všech 8 článků bylo odsouhlaseno.\nNyní můžeš pokračovat ke stažení Hry.",
		"Pokračovat",
		Callable(self, "_on_continue_download_pressed")
	)


func _on_continue_download_pressed():
	show_popup_window(
		"Stahování aplikace",
		"Připravuji stažení Hry...\nProsím čekej.",
		"Stahuji...",
		Callable()
	)

	if popup_button and is_instance_valid(popup_button):
		popup_button.disabled = true

	await get_tree().create_timer(5).timeout
	show_download_failed_screen()


func show_download_failed_screen():
	show_popup_window(
		"Chyba stahování",
		"Stažení Hry nebylo dokončeno.\n",
		"Zkusit znovu stáhnout",
		Callable(self, "_on_retry_download_pressed")
	)


func _on_retry_download_pressed():
	reset_tos_game_progress()
	show_tos_articles_screen()


# =========================================================
# LEVEL FLOW
# =========================================================

func fail_tos_game():
	if testing_level_mode:
		testing_level_mode = false
		show_level_select_menu(true)
		return

	show_popup_window(
		"Souhlas nebyl dokončen",
		"Pro pokračování musíte souhlasit se všemi podmínkami.",
		"Začít znovu",
		Callable(self, "_on_fail_restart_pressed")
	)

func _on_fail_restart_pressed():
	reset_tos_game_progress()
	show_tos_articles_screen()

func finish_level_and_return_to_select(_completed_level: int):
	if testing_level_mode:
		testing_level_mode = false
		show_level_select_menu(true)
		return

	if not completed_articles.has(current_article_number):
		completed_articles.append(current_article_number)

	if current_article_number >= tos_article_titles.size():
		show_final_screen()
		return

	if current_article_number >= highest_unlocked_article:
		highest_unlocked_article = clamp(current_article_number + 1, 1, tos_article_titles.size())

	show_tos_articles_screen()

# =========================================================
# DIRECT LEVEL START (for level select menu)
# =========================================================

func start_selected_level_for_testing(level_number: int):
	testing_level_mode = true
	current_article_number = 1
	start_selected_level(level_number)

func start_selected_level(level_number: int):
	if level_number < 1 or level_number > get_level_count():
		return

	start_configured_level(level_number)


# =========================================================
# XP / WINDOWS 7 INSPIRED STYLES
# =========================================================

func make_taskbar_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.24, 0.62)
	sb.border_width_top = 2
	sb.border_color = Color(0.47, 0.68, 1.0)
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 4
	return sb


func make_start_menu_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.94, 0.97, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.10, 0.32, 0.78)
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.corner_radius_bottom_left = 5
	sb.corner_radius_bottom_right = 5
	sb.shadow_color = Color(0, 0, 0, 0.38)
	sb.shadow_size = 10
	return sb


func make_shadow_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.18)
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	return sb


func make_window_frame_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.55, 0.75, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.05, 0.28, 0.72)
	sb.corner_radius_top_left = 11
	sb.corner_radius_top_right = 11
	sb.corner_radius_bottom_left = 9
	sb.corner_radius_bottom_right = 9
	sb.shadow_color = Color(1, 1, 1, 0.25)
	sb.shadow_size = 2
	return sb


func make_title_bar_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.38, 0.86)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.65, 0.82, 1.0)
	sb.corner_radius_top_left = 9
	sb.corner_radius_top_right = 9
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.shadow_color = Color(1, 1, 1, 0.16)
	sb.shadow_size = 3
	return sb


func make_content_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.96, 0.92)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.72, 0.75, 0.80)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	return sb


func style_start_button(btn: Button):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.23, 0.62, 0.10)
	normal.border_color = Color(0.11, 0.38, 0.05)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.shadow_color = Color(1, 1, 1, 0.25)
	normal.shadow_size = 2

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.33, 0.76, 0.16)
	hover.border_color = Color(0.13, 0.45, 0.08)
	hover.border_width_left = 1
	hover.border_width_top = 1
	hover.border_width_right = 1
	hover.border_width_bottom = 1
	hover.corner_radius_top_left = 16
	hover.corner_radius_top_right = 16
	hover.corner_radius_bottom_left = 16
	hover.corner_radius_bottom_right = 16
	hover.shadow_color = Color(1, 1, 1, 0.30)
	hover.shadow_size = 2

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0.17, 0.46, 0.07)
	pressed.border_color = Color(0.08, 0.26, 0.04)
	pressed.border_width_left = 1
	pressed.border_width_top = 1
	pressed.border_width_right = 1
	pressed.border_width_bottom = 1
	pressed.corner_radius_top_left = 16
	pressed.corner_radius_top_right = 16
	pressed.corner_radius_bottom_left = 16
	pressed.corner_radius_bottom_right = 16

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 15)


func style_menu_button(btn: Button):
	var normal = make_soft_button_style(Color(0.97, 0.98, 1.0), Color(0.56, 0.64, 0.78), 5)
	var hover = make_soft_button_style(Color(0.88, 0.93, 1.0), Color(0.20, 0.44, 0.88), 5)
	var pressed = make_soft_button_style(Color(0.76, 0.85, 0.98), Color(0.16, 0.34, 0.72), 5)
	var disabled = make_soft_button_style(Color(0.82, 0.82, 0.82), Color(0.65, 0.65, 0.65), 5)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color(0.07, 0.07, 0.07))
	btn.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
	btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	btn.add_theme_color_override("font_disabled_color", Color(0.42, 0.42, 0.42))
	btn.add_theme_font_size_override("font_size", 14)


func style_window_button(btn):
	var normal = make_soft_button_style(Color(0.94, 0.94, 0.91), Color(0.46, 0.50, 0.58), 4)
	var hover = make_soft_button_style(Color(0.98, 0.99, 1.0), Color(0.20, 0.44, 0.86), 4)
	var pressed = make_soft_button_style(Color(0.78, 0.86, 0.98), Color(0.16, 0.33, 0.68), 4)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	btn.add_theme_color_override("font_hover_color", Color(0.03, 0.03, 0.03))
	btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.02))
	btn.add_theme_font_size_override("font_size", 14)

func style_completed_button(btn: Button):
	var normal = make_soft_button_style(Color(0.24, 0.68, 0.28), Color(0.10, 0.42, 0.14), 4)
	var disabled = make_soft_button_style(Color(0.24, 0.68, 0.28), Color(0.10, 0.42, 0.14), 4)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 14)


func make_soft_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
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
	sb.shadow_color = Color(1, 1, 1, 0.18)
	sb.shadow_size = 1
	return sb
