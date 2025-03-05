@tool
extends "res://lib/gadget/gadget.gd"
# Pulley
# Script for the character Pulley-4!

const intro_dialogue_data = {
	#"_texture": "sticker_pulley",
	"_entry": {
		"string": "(Curse t-t-this infuriating, abhorrent... why won’t it just...) Oh, f-f-friend, good morning! The overnight magnetic realignment h-h-helped, did it?",
		"options": {
			"new_bot": "All three rods seem to be floating just right, Ratchet: I'm feeling like a new bot."
		}
	},
	"new_bot": {
		"string": "M-m-magnificent! So uh, well... want to t-take them for a spin... give them a stretch?",
		"options": {
			"icky": "A stretch, huh - sounds like someone has an icky job lined up for an idle set of jade rods."
		}
	},
	"icky": {
		"string": "I just... These rotten weeds and b-b-bugs; I can't. The static! Swooping and d-d-diving. Worse than Unchained grubs.",
		"options": {
			"alchemy": "It's okay, Ratchet. I'll handle it, starting with the weeds."
		}
	},
	"alchemy": {
		"string": "Thank you, t-t-thank you. Alchemy - t-t-this Dragonvoid has been interfering with t-t-the renovation cataloging system. I'll have to keep w-w-working on it.",
		"options": {
			"handle": "(Leave ratchet to their business.)"
		}
	},
	"handle": {
		"reference": "_exit"
	}
}

const pick_weeds_alt_dialogue = {
	"_entry": {
		"string": "(Ratchet is mumbling to themselves as they consult data on their heads-up display.)",
		"options": {
			"interference": "What's with the interference?",
			"ship": "How are your ship repairs coming along, Ratchet?",
			"done": "I'll leave you to it."
		}
	},
	"interference": {
		"string": "Shadow of the Dragonvoid... despair... h-h-haze... it inhibits m-m-machinery and renders devices inoperable. We must clear it out if we are to re-engage the renovation c-c-cataloging system.",
		"options": {
			"done": "You've got this, Ratchet.",
			"_entry": "(Ask Ratchet more.)"
		}
	},
	"ship": {
		"string": "Ship-p-p is... sixty-five percent optimal! Dents g-g-gone; engine calibration underway. Thanks, friend; that craft will n-never have t-t-to experience Aetherblade misconduct again.",
		"options": {
			"done": "I'm so happy to hear that, Ratchet. You deserve that; I wouldn't be here recovering if it weren't for you, that's for sure.",
			"_entry": "(Ask Ratchet more.)"
		}
	},
	"done": {
		"reference": "_exit"
	}
}

const clear_bugs_alt_dialogue = {
	"_entry": {
		"string": "(Ratchet is rapidly mumbling esoteric-sounding calculations.)",
		"options": {
			"stinks": "This stinks, Ratchet!"
		}
	},
	"stinks": {
		"string": "Keep at it-t-t, friend; just g-g-give me a minute. Ratchet has some ideas about clearing out this interference for good.",
		"options": {
			"done": "I'll leave you to it."
		}
	},
	"done": {
		"reference": "_exit"
	}
}

const dv_intro_dialogue = {
	"_entry": {
		"string": "(Ratchet is looking more smug than a Snaff Prize winner.)",
		"options": {
			"communicator": "I... was right over there... did you really need to use the communicator, Ratchet?"
		}
	},
	"communicator": {
		"string": "Standard g-g-golem operating procedure. Now! T-t-take the Raw Dispersion Flux; we're going to attune it in this genius m-machine I've developed.",
		"options": {
			"procedure": "(...)"
		}
	},
	"procedure": {
		"string": "Each Dragonvoid blight seems to resonate with the m-magic of a certain Elder Dragon. Use the device to play a melody and t-t-tune the flux to the correct Dragon, and then you can dispel it as you would any old bug!",
		"options": {
			"got_this": "(Through the communicator) I'll check it out; I've got this. Over!"
		}
	},
	"got_this": {
		"reference": "_exit"
	}
}

const no_dv_charge = {
	"_entry": {
		"string": "Your c-c-circuit functions are stable... no energy spikes... no anomalies... you mustn't have used t-t-the Attenuator yet, huh. N-no, it's perfectly safe.",
		"options": {
			"done": "Okay..."
		}
	},
	"done": {
		"reference": "exit"
	}
}

const debug_dialogue = {
	"_entry": {
		"string": "((Debug options!))",
		"options": {
			"time": "((Toggle the time of day.))",
			"clear": "((Clear all decorations (can't be undone).))",
			"reset": "((Reset decorations to default (can't be undone).))",
			"done": "((I'm done for now.))"
		}
	},
	"done": {
		"reference": "_exit"
	}
}

func _ready() -> void:
	# Quick fix to an ambient occlusion issue
	$PulleyMesh/GolemSkeleton/Skeleton3D/ArmBase_L/ArmBase_L.rotation_degrees.y = 180.0
	$PulleyMesh/GolemSkeleton/Skeleton3D/Armpivot_L/Armpivot_L.rotation_degrees.y = 180.0
	$PulleyMesh/AnimationPlayer.play("Base")

func _on_interacted() -> void:
	if Global.in_exclusive_ui or Global.dialogue_open: return
	Global.generic_area_left.emit()
	
	if Save.data.story_point == "game_start":
		spawn_dialogue(intro_dialogue_data, true)
	elif Save.data.story_point == "pick_weeds":
		spawn_dialogue(pick_weeds_alt_dialogue)
	elif Save.data.story_point == "clear_bugs":
		spawn_dialogue(clear_bugs_alt_dialogue)
	elif Save.data.story_point == "ratchet_dv":
		spawn_dialogue(dv_intro_dialogue, true)
	
	else:
		var _d = Dialogue.instantiate()
		_d.data = debug_dialogue
		_d.block_played.connect(func(id):
			if id == "time":
				if Global.time_of_day == "day":
					Global.command_sent.emit("/time=night")
				elif Global.time_of_day == "night":
					Global.command_sent.emit("/time=day")
			elif id == "clear":
				Global.command_sent.emit("/cleardeco")
				await get_tree().process_frame
				Global.command_sent.emit("/savedeco")
			elif id == "reset":
				Global.command_sent.emit("/resetdeco")
				await get_tree().process_frame
				Global.command_sent.emit("/savedeco")
		)
		
		Global.hud.add_child(_d)
		_d.closed.connect(func():
			Global.generic_area_entered.emit()
			Global.hearts_emit.emit()
		)
		_d.open()
