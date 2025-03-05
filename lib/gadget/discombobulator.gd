extends Node3D

const Dialogue = preload("res://lib/dialogue/dialogue.tscn")
const DIALOGUE_DATA = {
	"_entry": {
		"string": "The maintenance shed is filled to the brim with tools and magitech alike: shovels, replacement golem parts, and jade battery cells, all neatly stowed and labeled. I should make sure to straighten up any crates that have gone awry before Ratchet wanders back in here again.",
		"options": {
			"discombobulator": "Take a coil of Raw Dispersion Flux.",
			"close": "I'm all sorted, thanks."
		}
	},
	"discombobulator": { "reference": "_exit" },
	"close": { "reference": "_exit" }
}

@onready var dialogue_data = DIALOGUE_DATA.duplicate()

func proc_story() -> void:
	var _p = Save.data.story_point
	if _p == "game_start" or _p == "pick_weeds":
		$Collision.active = false
		$Collision.visible = false
	else:
		$Collision.active = true
		$Collision.visible = true

func _ready() -> void:
	Save.story_advanced.connect(proc_story)
	proc_story()

func _on_collision_interacted() -> void:
	if Global.deco_pane_open or Global.dialogue_open: return
	Global.generic_area_left.emit()
	dialogue_data = DIALOGUE_DATA.duplicate(true)
	
	# Add an option to clear an effect (and golems) if you have it
	if Utilities.is_holding_dv_charge():
		dialogue_data._entry["options"].erase("close")
		dialogue_data._entry.options["clear"] = "I'd like to return my Golems. (Clears effects.)"
		dialogue_data._entry.options["close"] = "I'm all sorted, thanks."
		dialogue_data["clear"] = { "reference": "_exit" }
	
	var _d = Dialogue.instantiate()
	_d.data = dialogue_data
	Global.hud.add_child(_d)
	_d.open()
	
	_d.closed.connect(Global.generic_area_entered.emit)
	_d.block_played.connect(func(id):
		if id == "discombobulator":
			Global.add_effect.emit("discombobulator")
			$GolemSound.play()
		elif id == "clear":
			Global.remove_effect.emit("discombobulator")
			Global.remove_effect.emit("dv_charge")
			Global.remove_effect.emit("d_jormag")
			Global.remove_effect.emit("d_karlkatorrik")
			Global.remove_effect.emit("d_mordremoth")
			Global.remove_effect.emit("d_primordus")
			Global.remove_effect.emit("d_soo_won")
			Global.remove_effect.emit("d_zhaitan"))
