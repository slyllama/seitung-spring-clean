extends CanvasLayer

var closed = false # prevent double interactions

func _set_shader_value(val: float) -> void: # 0-1
	var _e = ease(val, 0.2)
	$Base.material.set_shader_parameter("paint_mask_exponent", (1 - _e) * 10)

func open(
	title = "((Title))",
	description = "((Description))",
	sticker = load("res://generic/textures/stickers/sticker_placeholder.png")):
	$Base/Content/Title.text = "[center]" + title + "[/center]"
	# Includes shortcuts for second paragraph
	$Base/Content/Description.text = description.replace("<", "\n[font_size=9] [/font_size]\n[color=white]").replace(">", "[/color]")
	$Base/Content/Sticker.texture = sticker
	$PlayDialogue.play()
	
	Global.story_panel_open = true
	Global.action_cam_disable.emit()
	
	var fade_tween = create_tween()
	fade_tween.tween_method(_set_shader_value, 0.0, 1.0, 0.27)
	var content_fade_tween = create_tween()
	content_fade_tween.tween_property($Base/Content, "modulate:a", 1.0, 0.27)
	content_fade_tween.set_parallel()
	
	for _i in 2: # wait for command line to process
		await get_tree().process_frame
	
	await get_tree().create_timer(0.1).timeout
	$JadeWingsBase/JadeAnim.play("float")

func close():
	if closed: return # should only happen once
	closed = true
	Global.story_panel_open = false
	Global.close_story_panel.emit()
	
	# Do closing stuff
	var fade_tween = create_tween()
	fade_tween.tween_method(_set_shader_value, 1.0, 0.0, 0.27)
	var content_fade_tween = create_tween()
	content_fade_tween.tween_property($Base/Content, "modulate:a", 0.0, 0.27)
	content_fade_tween.set_parallel()
	$Paper.play()
	$JadeWingsBase/JadeAnim.play_backwards("float")
	
	await fade_tween.finished
	Global.action_cam_enable.emit()
	queue_free()

func _ready() -> void:
	$Base/Content.modulate.a = 0.0
	$JadeWingsBase/JadeWings.modulate.a = 0.0
	$JadeWingsBase/JadeWings.position.y = 10.0
	$Base/Content/Done.grab_focus()

func _process(_delta: float) -> void:
	$JadeWingsBase.global_position = (
		get_window().size / 2.0 * (1.0 / Global.retina_scale) + Vector2(0, -200))

func _on_content_mouse_entered() -> void:
	Global.in_exclusive_ui = true
func _on_content_mouse_exited() -> void:
	Global.in_exclusive_ui = false
