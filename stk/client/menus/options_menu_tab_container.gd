extends TabContainer

var tab_labels_dict = {
	"Visual" : "MENU_OPTIONS_VISUAL",
	"Audio" : "MENU_OPTIONS_AUDIO",
	"Controls" : "MENU_OPTIONS_CONTROLS",
	"Misc" : "MENU_OPTIONS_MISC",
	"Credits" : "MENU_LABEL_CREDITS"
}

func _ready():
	# Update tab names to translated strings
	for tab in get_tab_count():
		set_tab_title(tab, tab_labels_dict[get_tab_title(tab)])
