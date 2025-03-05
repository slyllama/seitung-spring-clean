extends Node
# Utilities
# Various handy tools!

const DEG = "[char=0x000000B0]"
const TICK = "[char=0x00002713]"
const BIGNUM = -9999
const BIGVEC3 = Vector3(BIGNUM, BIGNUM, BIGNUM)

const DRAGON_DATA = {
	"jormag": {
		"name": "Jormag",
		"color": Color("90d6d0")
	},
	"kralkatorrik": {
		"name": "Kralkatorrik",
		"color": Color("dc6cb5")
	},
	"mordremoth": {
		"name": "Mordremoth",
		"color": Color("85ab37")
	},
	"primordus": {
		"name": "Primordus",
		"color": Color("e9694c")
	},
	"soo_won": {
		"name": "Soo-Won",
		"color": Color("4da3bf")
	},
	"zhaitan": {
		"name": "Zhaitan",
		"color": Color("57375c")
	}
}

func is_holding_dv_charge() -> bool: # is the player holding a Dragonvoid charge of any kind?
	if ("discombobulator" in Global.current_effects
		or "dv_charge" in Global.current_effects
		or "d_jormag" in Global.current_effects
		or "d_kralkatorrik" in Global.current_effects
		or "d_mordremoth" in Global.current_effects
		or "d_primordus" in Global.current_effects
		or "d_soo_won" in Global.current_effects
		or "d_zhaitan" in Global.current_effects):
		return(true)
	else:
		return(false)

func get_time() -> String:
	var time = Time.get_time_dict_from_system()
	return("%02d:%02d:%02d" % [time.hour, time.minute, time.second])

func set_window_mode(window_mode: String) -> void:
		if window_mode == "full_screen": get_window().mode = Window.MODE_FULLSCREEN
		elif window_mode == "maximized": get_window().mode = Window.MODE_MAXIMIZED
		elif window_mode == "exclusive_full_screen": get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
		else: get_window().mode = Window.MODE_WINDOWED

func get_user_vol() -> float:
	if "volume" in SettingsHandler.settings:
		return(clamp(float(SettingsHandler.settings.volume), 0.0, 1.0))
	else:
		return(0.0)

# Set master volume on the bus
func set_master_vol(vol = get_user_vol()) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(vol))

# Get all children recursively
func get_all_children(node: Node) -> Array:
	var nodes: Array = []
	if !node: return([])
	for n in node.get_children():
		if n.get_child_count() > 0:
			nodes.append(n)
			nodes.append_array(get_all_children(n, ))
		else: nodes.append(n)
	return(nodes)

# Pretty (and rounded) presentation of Vector2 values
func fmt_vec2(vec: Vector2) -> String:
	return(str(snapped(vec.x, 0.1))
		+ ", " + str(snapped(vec.y, 0.1)))

# Pretty (and rounded) presentation of Vector3 values
func fmt_vec3(vec: Vector3) -> String:
	return(str(snapped(vec.x, 0.1))
		+ ", " + str(snapped(vec.y, 0.1))
		+ ", " + str(snapped(vec.z, 0.1)))

func critical_lerp(delta: float, speed: float) -> float:
	return(clamp(1.0 - exp(-speed * delta), 0.0, 1.0))
