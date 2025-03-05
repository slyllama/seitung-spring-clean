extends CanvasLayer

signal closed

const PianoKey = preload("res://lib/attenuator/piano_key.tscn")

const notes = [
	{"float": 0.0,  "color": Color.CADET_BLUE},	# C
	{"float": 1.0,  "color": Color.WHITE},		# D
	{"float": 2.1,  "color": Color.WHITE},		# E
	{"float": 2.65,  "color": Color.WHITE},		# F
	{"float": 4.1,  "color": Color.WHITE},		# G
	{"float": 5.5,  "color": Color.WHITE},		# A
	{"float": 7.2,  "color": Color.WHITE},		# B
]
const KEY_INDICES = [
	"c1", "d1", "e1", "f1", "g1", "a1", "b1",
	"c2", "d2", "e2", "f2", "g2", "a2", "b2", "c2" ]
const TUNES = {
	"primordus": [
		"_", "a1", "a2", "b2", "b2", "_", "e2", "g2", "a2", "e2" ],
	"soo_won": [
		"d1", "e1", "f1", "e1", "f1", "g1", "a1", "f1", "d1", "g1", "e1", "c1" ],
	"mordremoth": [
		"a1", "_", "c2", "b1", "_", "c2", "e2", "_", "c2", "b1", "_", "c2" ],
	"zhaitan": [
		"e2", "_", "b1", "c2", "_", "a1", "b1", "_", "b1" ]
}
const TUNES_ORDER = [ "primordus", "soo_won", "mordremoth", "zhaitan" ]

var current_dragon = "primordus"
var two_oct = notes.duplicate()
var place = 0
var target_track
var passing = true

@onready var glyph_box: TextureRect = $Base/ControlContainer/GlyphContainer

func _set_ee_paint_exponent(val: float) -> void:
	$Base/EEUpper.material.set_shader_parameter("dissolve_value", val)

func _set_paint_exponent(val: float) -> void:
	$Base.material.set_shader_parameter("paint_exponent", val)
	$Base/KeyContainer.material.set_shader_parameter("paint_exponent", val)

func present_glyph() -> void: # present a glyph based on the current Elder Dragon
	for _n in glyph_box.get_children():
		_n.queue_free()
	
	var glyph_sprite = Sprite2D.new()
	glyph_sprite.modulate.a = 0.0
	glyph_sprite.use_parent_material = true
	glyph_sprite.texture = load(
		"res://lib/attenuator/textures/glyphs/" + current_dragon + ".png")
	$Dragon/Rune.texture = load( # TODO: streamline this
		"res://lib/attenuator/textures/glyphs/" + current_dragon + ".png")
	glyph_box.add_child(glyph_sprite)
	
	var _g_fade_tween = create_tween()
	_g_fade_tween.tween_property(glyph_sprite, "modulate:a", 1.0, 0.2)
	var _g_scale_tween = create_tween()
	_g_scale_tween.tween_property(glyph_sprite, "scale", Vector2(0.4, 0.4), 0.2)
	_g_scale_tween.parallel()

func _set_prev_next_keys() -> void:
	var current_index = TUNES_ORDER.find(current_dragon, 0)
	if current_index >= TUNES_ORDER.size() - 1: $Base/ControlContainer/ArrowBox/Next.disabled = true
	else: $Base/ControlContainer/ArrowBox/Next.disabled = false
	if current_index - 1 < 0: $Base/ControlContainer/ArrowBox/Previous.disabled = true
	else: $Base/ControlContainer/ArrowBox/Previous.disabled = false

func select_dragon(forward = true) -> void:
	var current_index = TUNES_ORDER.find(current_dragon, 0)
	if forward:
		if current_index < TUNES_ORDER.size() - 1:
			current_dragon = TUNES_ORDER[current_index + 1]
			await get_tree().process_frame
			render()
	else:
		if current_index > 0:
			current_dragon = TUNES_ORDER[current_index - 1]
			await get_tree().process_frame
			render()
	_set_prev_next_keys()

func render() -> void:
	place = 0
	present_glyph()
	var _title = Utilities.DRAGON_DATA[current_dragon].name
	$Base/ControlContainer/DragonTitle.text = "[center]" + _title + "[/center]"
	
	# Reset
	for _n in $Base/KeyContainer.get_children():
		_n.queue_free() # clear out
	_adv_blank_place()
	await get_tree().process_frame
	
	var _d = 0
	for _i in two_oct:
		var _n = PianoKey.instantiate()
		_n.pitch = 1.0 + _i.float * (1.0 / 8.0)
		_n.id = _d
		_n.note_name = KEY_INDICES[_d]
		_n.modulate = _i.color
		_n.played.connect(func():
			var played_note = KEY_INDICES[_n.id]
			var correct_note = TUNES[current_dragon][place]
			if played_note != correct_note:
				if passing:
					$Disabled.play()
					var ee_fade_tween = create_tween()
					ee_fade_tween.tween_method(_set_ee_paint_exponent, 1.0, 0.0, 0.3)
				passing = false
			
			if place < TUNES[current_dragon].size() - 1 and passing:
				place += 1
				_adv_blank_place()
				$Click.play()
			else:
				if place == TUNES[current_dragon].size() - 1 and passing:
					Global.add_effect.emit("d_" + current_dragon)
					Global.remove_effect.emit("discombobulator")
					$Success.play()
					$Dragon.reveal(current_dragon)
					await get_tree().create_timer(0.5).timeout
					render()
		)
		$Base/KeyContainer.add_child(_n)
		_n.set_pills_size(TUNES[current_dragon].size())
		_d += 1
	
	var _c = 0
	for _n in TUNES[current_dragon]:
		if _n != "_":
			var _key_index = KEY_INDICES.find(_n, 0)
			$Base/KeyContainer.get_children()[_key_index].assign_track([_c])
		_c += 1
	
	if !passing:
		passing = true
		var ee_fade_tween = create_tween()
		ee_fade_tween.tween_method(_set_ee_paint_exponent, 0.0, 1.0, 0.3)
	target_track = $Base/KeyContainer.get_children()[0]
	
	for _n in $Base/KeyContainer.get_children():
		if !is_instance_valid(_n): continue
		if "alpha" in _n:
			_n.alpha = 1.0
		await get_tree().create_timer(0.03).timeout

func close() -> void:
	await get_tree().process_frame # queue for next frame so settings doesn't open
	Global.target_music_ratio = 1.0
	
	Global.can_move = true
	Global.in_exclusive_ui = false
	Global.tool_mode = Global.TOOL_MODE_NONE
	closed.emit()
	
	var fade_tween = create_tween()
	fade_tween.tween_method(_set_paint_exponent, 0.0, 10.0, 0.2)
	var ee_fade_tween = create_tween()
	ee_fade_tween.tween_method(_set_ee_paint_exponent, 1.0, 0.0, 0.3)
	$DispulsionFX.anim_out()
	await $DispulsionFX.anim_out_complete
	
	queue_free()

func _adv_blank_place() -> void:
	if TUNES[current_dragon][place] == "_":
		place += 1

func _ready() -> void:
	Global.target_music_ratio = 0.0
	
	Global.can_move = false
	Global.in_exclusive_ui = true
	Global.action_cam_disable.emit()
	Global.tool_mode = Global.TOOL_MODE_FISH
	
	for _i in notes:
		two_oct.append({"float": _i.float * 2.0 + 8.0, "color": _i.color})
	two_oct.append({"float": notes[0].float * 4.0 + 24.0, "color": notes[0].color})
	
	render()
	_set_prev_next_keys()
	
	$DispulsionFX.anim_in()
	var fade_tween = create_tween()
	fade_tween.tween_method(_set_paint_exponent, 10.0, 0.0, 0.3)
	var ee_fade_tween = create_tween()
	ee_fade_tween.tween_method(_set_ee_paint_exponent, 0.0, 1.0, 0.3)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		close()
	if Input.is_action_just_pressed("ui_accept"):
		render() #TODO: debug testing re-loading

func _on_close_button_down() -> void:
	close()

func _process(delta: float) -> void:
	$DispulsionFX.position.x = $Base.position.x + $Base.size.x / 2.0
	$DispulsionFX.position.y = $Base.position.y + 140.0
	
	$Dragon.position.x = $Base.position.x + $Base.size.x / 2.0
	$Dragon.position.y = $Base.position.y + $Base.size.y / 2.0
	
	for _n in glyph_box.get_children():
		_n.position.x = glyph_box.size.x / 2.0
		_n.position.y = glyph_box.size.y / 2.0
	
	if !target_track: return # not ready yet
	if "pills" in target_track:
		var _target = target_track.pills[place]
		$Base/Marker.global_position.x = lerp(
			$Base/Marker.global_position.x,
			_target.global_position.x + 22.0,
			Utilities.critical_lerp(delta, 20.0))
	
	$Base/Debug.text = ("place: " + str(place) + "/" + str(TUNES[current_dragon].size())
		+ "\npassing = " + str(passing))

func _on_reset_button_down() -> void:
	Global.click_sound.emit()
	render()

func _on_next_button_down() -> void:
	Global.click_sound.emit()
	select_dragon()

func _on_previous_button_down() -> void:
	Global.click_sound.emit()
	select_dragon(false)
