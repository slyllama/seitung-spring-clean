@tool
extends Crumb
var rng = RandomNumberGenerator.new()

const N1 = "This streak of Dragonvoid casts a looming shadow over the garden."
const N2 = "I'll need Attuned Dispersion Flux to dispel it."

func clear() -> void:
	Global.announcement_sent.emit("The air lightens as the Flux disperses the somber void.")
	Global.remove_effect.emit("d_" + custom_data)
	Global.bug_crumb_left.emit()
	super()

func process_custom_data() -> void:
	super()
	$SpatialText/FG/Title/CollectionIcon.texture = load(
		"res://lib/hud/fx_list/textures/fx_d_" + custom_data + ".png")
	$SpatialText/FG/Title.text = ("[center]Dragonvoid\nof "
		+ Utilities.DRAGON_DATA[custom_data].name + "[/center]")

func _ready() -> void:
	super()
	$DragonvoidArc/AnimationPlayer.play("Wobble")
	body_entered.connect(func(body):
		#if Save.data.story_point == "game_start": return # not unlocked yet
		if body is CharacterBody3D:
			Global.dragonvoid_crumb_entered.emit())
	
	body_exited.connect(func(body):
		#if Save.data.story_point == "game_start": return # not unlocked yet
		if body is CharacterBody3D:
			Global.dragonvoid_crumb_left.emit())

func interact() -> void:
	if (Save.data.story_point == "game_start" or Save.data.story_point == "pick_weeds"
		or Save.data.story_point == "clear_bugs"):
		Global.announcement_sent.emit(N1)
		return # not unlocked yet
	else:
		
		if "d_" + custom_data in Global.current_effects:
			var _f = FishingInstance.instantiate()
			_f.completed.connect(clear)
			_f.canceled.connect(func():
				Global.remove_effect.emit("d_" + custom_data))
			add_child(_f)
			return
		elif "discombobulator" in Global.current_effects:
			Global.announcement_sent.emit(N1 + " " + N2)
			return
		else:
			Global.announcement_sent.emit(N1 + " " + N2)
