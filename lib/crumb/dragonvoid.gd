@tool
extends Crumb
var rng = RandomNumberGenerator.new()

const N1 = "This streak of Dragonvoid casts a looming shadow over the garden."
const N2 = "I'll need the correct Attuned Dispersion Flux to dispel it."

func clear() -> void:
	#Global.announcement_sent.emit("The air lightens as the Flux disperses the somber void.")
	Global.remove_effect.emit("d_" + custom_data)
	SteamHandler.add_to_stat("void_dispelled")
	Global.ripple.emit()
	Global.bug_crumb_left.emit()
	super()

func _update_interact_text():
	if Save.is_at_story_point("clear_dv") and Save.has_dv_charge():
		Global.interact_hint = "Dispel"

func proc_story() -> void:
	if !Save.is_at_story_point("clear_dv"):
		$VisualArea.visible = false
	else: $VisualArea.visible = true

func process_custom_data() -> void:
	super()
	$Icon/FG/Title/CollectionIcon.texture = load(
		"res://lib/hud/fx_list/textures/fx_d_" + custom_data + ".png")
	$Text/FG/Title.text = ("[center]Dragonvoid\nof "
		+ Utilities.DRAGON_DATA[custom_data].name + "[/center]")

func _ready() -> void:
	super()
	$DragonvoidArc/AnimationPlayer.play("Wobble")
	
	if !Engine.is_editor_hint():
		Save.story_advanced.connect(proc_story)
		proc_story()
		
		Global.summon_story_panel.connect(func(_data):
			if overlaps_body(Global.player):
				Global.dragonvoid_crumb_left.emit())
		
		Global.close_story_panel.connect(func():
			if overlaps_body(Global.player):
				_update_interact_text()
				Global.dragonvoid_crumb_entered.emit())
	
	body_entered.connect(func(body):
		if Global.story_panel_open: return
		if body is CharacterBody3D:
			_update_interact_text()
			Global.dragonvoid_crumb_entered.emit())
	
	body_exited.connect(func(body):
		if Global.story_panel_open: return
		if body is CharacterBody3D:
			Global.dragonvoid_crumb_left.emit())

func interact() -> void:
	if (Save.data.story_point == "game_start" or Save.data.story_point == "pick_weeds"
		or Save.data.story_point == "clear_bugs"):
		Global.announcement_sent.emit(N1)
		return # not unlocked yet
	else:
		#if "discombobulator" in Global.current_effects:
			#Global.announcement_sent.emit(N1 + " " + N2)
			#return
		if "d_" + custom_data in Global.current_effects:
			var _f = FishingInstance.instantiate()
			$Blight.play()
			_f.completed.connect(clear)
			_f.canceled.connect(func():
				Global.remove_effect.emit("d_" + custom_data))
			add_child(_f)
		else:
			Global.announcement_sent.emit(N1 + " " + N2)
