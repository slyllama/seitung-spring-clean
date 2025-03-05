@tool
extends "res://lib/gadget/gadget.gd"

const AttenuatorUI = preload("res://lib/attenuator/attenuator.tscn")
var in_ui = false

func proc_story() -> void:
	var _sp = Save.data.story_point
	if _sp  == "clear_dv":
		visible = true
		active = true
	else:
		visible = false
		active = false

func _ready() -> void:
	super()
	if Engine.is_editor_hint(): return
	Save.story_advanced.connect(proc_story)
	proc_story()
	
	Global.command_sent.connect(func(_cmd):
		if _cmd == "/enableattn":
			visible = true
			active = true
		elif _cmd == "/disableattn":
			visible = false
			active = false
			if in_range:
				Global.generic_area_left.emit())

func _on_interacted() -> void:
	if in_ui: return # don't open multiple
	
	if !"discombobulator" in Global.current_effects:
		Global.announcement_sent.emit("The Attenuator is ready to charge some Dispersion Flux.")
		return
	
	in_ui = true
	var _ui = AttenuatorUI.instantiate()
	Global.hud.add_child(_ui)
	_ui.closed.connect(func():
		in_ui = false
		in_range = true
		Global.generic_area_entered.emit()
		Global.action_cam_enable.emit())
