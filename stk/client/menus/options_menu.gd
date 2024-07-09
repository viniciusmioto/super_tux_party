extends CenterContainer

const USER_OPTIONS_FILE = "user://options.cfg"

var _options_file = ConfigFile.new()
var _is_loading_options = false

#warning-ignore:unused_signal
signal quit

func _ready():
	# Populate with toggled translations in 'Project Settings > Localization > Locales Filter'.
	var languages = ProjectSettings.get("locale/locale_filter")[1]
	var language_control = $Menu/TabContainer/Visual/Language/OptionButton
	for i in languages.size():
		language_control.add_item(
				TranslationServer.get_locale_name(languages[i]), i+1)
		language_control.set_item_metadata(i+1, languages[i])
	
	load_options()

func _input(event):
	if get_viewport().gui_get_focus_owner() and $Menu/TabContainer.is_ancestor_of(get_viewport().gui_get_focus_owner()):
		if event.is_action_pressed("ui_focus_prev"):
			$Menu/TabContainer.current_tab = ($Menu/TabContainer.current_tab + $Menu/TabContainer.get_tab_count() - 1) % $Menu/TabContainer.get_tab_count()
			$Menu/TabContainer.get_current_tab_control().get_child(0).grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_focus_next"):
			$Menu/TabContainer.current_tab = ($Menu/TabContainer.current_tab + 1) % $Menu/TabContainer.get_tab_count()
			$Menu/TabContainer.get_current_tab_control().get_child(0).grab_focus()
			get_viewport().set_input_as_handled()

func _on_Fullscreen_toggled(button_pressed):
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (button_pressed) else Window.MODE_WINDOWED
	
	save_option("visual", "fullscreen", button_pressed)

func _on_VSync_toggled(button_pressed):
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if (button_pressed) else DisplayServer.VSYNC_DISABLED)
	
	save_option("visual", "vsync", button_pressed)


func _on_FXAA_toggled(button_pressed):
	get_viewport().set_use_fxaa(button_pressed)
	
	save_option("visual", "fxaa", button_pressed)

func _on_Language_item_selected(ID):
	var locales = ProjectSettings.get("locale/locale_filter")[1]
	var option_meta = $Menu/TabContainer/Visual/Language/OptionButton.get_item_metadata(ID)
	if not locales.has(option_meta):
		TranslationServer.set_locale(OS.get_locale())
		
		save_option("visual", "language", "")
		Global.language_changed.emit()
		return
	
	TranslationServer.set_locale(option_meta)
	
	save_option("visual", "language", option_meta)
	Global.language_changed.emit()

func _on_FrameCap_item_selected(ID):
	match ID:
		0:
			Engine.max_fps = 30
		1:
			Engine.max_fps = 60
		2:
			Engine.max_fps = 120
		3:
			Engine.max_fps = 144
		4:
			Engine.max_fps = 240
		5:
			Engine.max_fps = 0 # A zero value uncaps the frames.
	
	save_option("visual", "frame_cap", ID)

func _on_MSAA_item_selected(ID):
	match ID:
		0:
			get_viewport().set_msaa(0) #MSAA_DISABLED
		1:
			get_viewport().set_msaa(1) #MSAA_2X
		2:
			get_viewport().set_msaa(2) #MSAA_4X
		3:
			get_viewport().set_msaa(3) #MSAA_8X
		4:
			get_viewport().set_msaa(4) #MSAA_16X
	
	save_option("visual", "msaa", ID)

func _on_bus_toggled(enabled, index):
	AudioServer.set_bus_mute(index, not enabled)
	
	save_option("audio", AudioServer.get_bus_name(index).to_lower() + "_muted", not enabled)

func _on_volume_changed(value, index):
	AudioServer.set_bus_volume_db(index, value)
	
	var percentage = str((value + 80) / 80 * 100).pad_decimals(0) + "%"
	match index:
		0:
			$Menu/TabContainer/Audio/Master/Label.text = percentage
		1:
			$Menu/TabContainer/Audio/Music/Label.text = percentage
		2:
			$Menu/TabContainer/Audio/Effects/Label.text = percentage
	
	save_option("audio", AudioServer.get_bus_name(index).to_lower() + "_volume", value)

func _on_MuteUnfocus_toggled(button_pressed):
	Global.mute_window_unfocus = button_pressed
	
	save_option("audio", "mute_window_unfocus", button_pressed)

func _on_PauseUnfocus_toggled(button_pressed):
	Global.pause_window_unfocus = button_pressed
	
	save_option("misc", "pause_window_unfocus", button_pressed)

func get_option_value_safely(section, key, default, min_value=null, max_value=null):
	var value = _options_file.get_value(section, key, default)
	if typeof(value) != typeof(default) or (min_value != null and value < min_value) or (max_value != null and value > max_value):
		return default
	
	return value

func load_options():
	var err = _options_file.load(USER_OPTIONS_FILE)
	if err != OK:
		print("Error while loading options: " + error_string(err))
	
	_is_loading_options = true # Avoid saving options while loading them.
	
	var language = get_option_value_safely("visual", "language", "")
	var language_id = ProjectSettings.get("locale/locale_filter")[1].find(language)
	if language_id == -1:
		language_id = 0
	else:
		language_id += 1
	_on_Language_item_selected(language_id)
	$Menu/TabContainer/Visual/Language/OptionButton.select(language_id)
	
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (get_option_value_safely("visual", "fullscreen", false)) else Window.MODE_WINDOWED
	$Menu/TabContainer/Visual/Fullscreen.button_pressed = ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))
	
	var fxaa = get_option_value_safely("visual", "fxaa", false)
	$Menu/TabContainer/Visual/FXAA.button_pressed = fxaa
	
	#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if (get_option_value_safely("visual", "vsync", false)) else DisplayServer.VSYNC_DISABLED)
	$Menu/TabContainer/Visual/VSync.button_pressed = (DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED)
	
	var frame_id = get_option_value_safely("visual", "frame_cap", 1, 0, 5)
	_on_FrameCap_item_selected(frame_id)
	$Menu/TabContainer/Visual/FrameCap/OptionButton.select(frame_id)
	
	var msaa = get_option_value_safely("visual", "msaa", 0)
	$Menu/TabContainer/Visual/MSAA/OptionButton.select(msaa)
	
	var quality = get_option_value_safely("visual", "quality", 1)
	$Menu/TabContainer/Visual/Quality/OptionButton.select(quality)
	
	AudioServer.set_bus_mute(0, get_option_value_safely("audio", "master_muted", false))
	AudioServer.set_bus_mute(1, get_option_value_safely("audio", "music_muted", false))
	AudioServer.set_bus_mute(2, get_option_value_safely("audio", "effects_muted", false))
	
	$Menu/TabContainer/Audio/Master/CheckBox.button_pressed = not AudioServer.is_bus_mute(0)
	$Menu/TabContainer/Audio/Music/CheckBox.button_pressed = not AudioServer.is_bus_mute(1)
	$Menu/TabContainer/Audio/Effects/CheckBox.button_pressed = not AudioServer.is_bus_mute(2)
	
	Global.mute_window_unfocus = get_option_value_safely("audio", "mute_window_unfocus", true)
	$Menu/TabContainer/Audio/MuteUnfocus.button_pressed = Global.mute_window_unfocus
	
	# Setting the 'value' of 'Range' nodes directly also fires their signals.
	$Menu/TabContainer/Audio/MasterVolume.value = get_option_value_safely("audio", "master_volume", 0.0, -80, 0)
	$Menu/TabContainer/Audio/MusicVolume.value = get_option_value_safely("audio", "music_volume", 0.0, -80, 0)
	$Menu/TabContainer/Audio/EffectsVolume.value = get_option_value_safely("audio", "effects_volume", 0.0, -80, 0)
	
	Global.pause_window_unfocus = get_option_value_safely("misc", "pause_window_unfocus", true)
	$Menu/TabContainer/Misc/PauseUnfocus.button_pressed = Global.pause_window_unfocus
	
	_is_loading_options = false

func save_option(section, key, value):
	if _is_loading_options:
		return
	
	_options_file.set_value(section, key, value)
	var err = _options_file.save(USER_OPTIONS_FILE)
	if err != OK:
		print("Error while saving options: " + error_string(err))

func _on_GraphicQuality_item_selected(ID):
	# Taken from: https://github.com/godotengine/godot-demo-projects/blob/0dfb54ff7f31960bec814d23dedc031227ac176e/3d/graphics_settings/settings.gd#L160
	match ID:
		0: # Ultra
			RenderingServer.directional_shadow_atlas_set_size(16384, true)
			get_viewport().positional_shadow_atlas_size = 16384
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA)
		1: # Medium
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
			get_viewport().positional_shadow_atlas_size = 4096
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
		2: # Low
			RenderingServer.directional_shadow_atlas_set_size(512, true)
			# Disable positional (omni/spot) light shadows entirely to further improve performance.
			# These often don't contribute as much to a scene compared to directional light shadows.
			get_viewport().positional_shadow_atlas_size = 0
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
	save_option("visual", "quality", ID)

func _on_change_controls_pressed(player_id: int):
	$Menu.hide()
	$ControlRemapper.player_id = player_id
	$ControlRemapper.show()

func _on_ControlRemapper_quit():
	$Menu.show()
	var button := $Menu/TabContainer/Controls.get_child($ControlRemapper.player_id - 1)
	button.grab_focus()
	
#*** Credits menu ***#
func process_hyperlinks(input: String) -> String:
	var out := ""
	
	var pos = input.find("[")
	while pos != -1:
		var end = input.find("]")
		if end != -1 and input[end+1] == "(":
			var urlend = input.find(")", end+1)
			out += input.substr(0, pos)
			out += "[color=#00aaff][url=" + input.substr(end+2, urlend - end - 2) + "]" \
					+ input.substr(pos + 1, end - pos - 1) + "[/url][/color]"
			input = input.substr(urlend+1, input.length() - urlend)
		else:
			out += input.substr(0, pos+1)
			input = input.substr(pos+1, input.length() - pos)
		pos = input.find("[")
	out += input
	return out

func print_licenses(f: FileAccess) -> String:
	var text = ""
	
	var current_dir := ""
	var has_files = true
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("## "):
			current_dir = line.substr(3, line.length() - 3)
			if not current_dir.ends_with("/"):
				current_dir += "/"
			has_files = false
		elif line.begins_with("### "):
			var unescaped := line.substr(4, line.length() - 4).replace("\\*", "*")
			var files = unescaped.split("|")
			for file in files:
				text += "[color=#ffffff]" + current_dir + file.lstrip(" \t\v").rstrip(" \t\v") + ":[/color]\n"
			has_files = true
		else:
			if not has_files: # Special edge case: top_level entries start with '## '
				text += "[color=#ffffff]" + current_dir.substr(0, current_dir.length() - 1) + ":[/color]\n"
				has_files = true
			text += "[indent]" + process_hyperlinks(line) + '[/indent]\n'
	
	return text

func _on_TabContainer_tab_selected(tab):
	if tab == 4:
		var text = """[color=#ffffff][center]SuperTuxParty is brought to you by:[/center]
[color=#ffaa00][center][url=https://gitlab.com/Dragoncraft89]Dragoncraft89[/url], [url=https://gitlab.com/Antiwrapper]Antiwrapper[/url], [url=https://yeldham.itch.io]Yeldham[/url], [url=https://gitlab.com/RiderExMachina]RiderExMachina[/url], [url=https://gitlab.com/Hejka26]Hejka26[/url], [url=https://gitlab.com/airon90]airon90[/url], [url=https://gitlab.com/swolfschristophe]swolfschristophe[/url], [url=https://gitlab.com/pastmidnight14]pastmidnight14[/url], [url=https://gitlab.com/kratz00]kratz00[/url], [url=https://gitlab.com/Independent-Eye]Independent-Eye[/url] and [url=https://gitlab.com/doggoofspeed]DoggoOfSpeed[/url][/center][color=#e5e5e5]

[center]with [color=#66aa00]ART[/color] by:[/center]
"""
		var license_art := FileAccess.open("res://licenses/LICENSE-ART.md", FileAccess.READ)
		text += print_licenses(license_art)
		license_art.close()
	
		text += "[center]and [color=#66aa00]MUSIC[/color] by:[/center]\n"
	
		var license_music := FileAccess.open("res://licenses/LICENSE-MUSIC.md", FileAccess.READ)
		text += print_licenses(license_music)
		license_music.close()
	
		text += "[center][color=#66aa00]SHADERS[/color] by:[/center]\n"
	
		var license_shader := FileAccess.open("res://licenses/LICENSE-SHADER.md", FileAccess.READ)
		text += print_licenses(license_shader)
		license_shader.close()
	
		var license_fonts := FileAccess.open("res://licenses/LICENSE-FONTS.md", FileAccess.READ)
		text += print_licenses(license_fonts)
		license_shader.close()
		
		$Menu/TabContainer/Credits/RichTextLabel.text = text

func _on_Credits_meta_clicked(meta):
	OS.shell_open(meta) # Open links in the credits
