@tool
extends Decoration

func _ready() -> void:
	super()
	
	if Engine.is_editor_hint(): return
	SettingsHandler.setting_changed.connect(func(parameter):
		if parameter == "foliage_density":
			$Bamboo.visible = false
			$Bamboo2.visible = false
			$Bamboo3.visible = false
			var _value = SettingsHandler.settings[parameter]
			if _value == "low":
				$Bamboo.visible = true
			elif _value == "medium":
				$Bamboo.visible = true
			elif _value == "high":
				$Bamboo.visible = true
				$Bamboo2.visible = true
			else:
				$Bamboo.visible = true
				$Bamboo2.visible = true
				$Bamboo3.visible = true
	)
