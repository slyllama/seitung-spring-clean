@icon("res://lib/gizmo/icon_gizmo.svg")
class_name GizmoScale extends Node3D

const ScaleMesh = preload("res://lib/gizmo/gizmo_arrow/meshes/arrow_meshes_arrow_scale.res")
const Dragger = preload("res://lib/dragger/dragger.tscn")

var enabled = false
var active = false
var scale_visual = MeshInstance3D.new()
var grabber = PickBox.new()
var mat = ShaderMaterial.new()
var color: Color

@onready var fluid_scale = get_parent().scale.x

func set_color(get_color: Color, dim = 0.5) -> void:
	color = get_color
	mat.set_shader_parameter("color", get_color * dim)

func destroy() -> void:
	enabled = false
	var scale_out_tween = create_tween()
	scale_out_tween.tween_property(scale_visual, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	scale_out_tween.tween_callback(queue_free)

func _ready() -> void:
	set_disable_scale(true)
	enabled = true
	position.y = 0.1
	
	if Global.transform_mode == Global.TRANSFORM_MODE_WORLD:
		global_rotation = Vector3.ZERO
	
	# Set up grabber from PickBox
	grabber.set_size(Vector3(0.35, 0.55, 0.35))
	grabber.make_ui_component()
	grabber.position.y = -0.9
	add_child(grabber)
	
	# Set up visible mesh
	scale_visual.mesh = ScaleMesh
	#scale_visual.mesh.size = Vector3(0.14, 0.14, 0.14)
	scale_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scale_visual.set_layer_mask_value(1, 0)
	scale_visual.set_layer_mask_value(2, 0)
	scale_visual.set_layer_mask_value(3, 1)
	grabber.add_child(scale_visual)
	#scale_visual.position.y = -0.25
	scale_visual.scale = Vector3(0.01, 0.01, 0.01)
	scale_visual.position.y = 0.2
	
	var scale_in_tween = create_tween()
	scale_in_tween.tween_property(scale_visual, "scale", Vector3(0.8, 0.8, 0.8), 0.15)
	
	mat.shader = load("res://generic/materials/shaders/shader_color.gdshader")
	mat.render_priority = 3
	scale_visual.set_surface_override_material(0, mat)
	set_color(Color.WHITE)
	
	grabber.mouse_entered.connect(func():
		if !enabled: return
		set_color(color, 1.0))
	grabber.mouse_exited.connect(func():
		if active: return
		set_color(color, 0.5))
	
	grabber.drag_started.connect(func():
		if !enabled: return
		
		var _d = Dragger.instantiate()
		_d.axis = _d.Axis.Y
		add_child(_d)
		
		_d.ratio_changed.connect(func(ratio):
			var _new_scale = clamp(fluid_scale + ratio * -0.1, 0.15, 2.5)
			if _new_scale <= 0.15 or _new_scale >= 2.5:
				_d.play_tick = false
			else:
				_d.play_tick = true
			fluid_scale = _new_scale
			var snapped_scale = snapped(fluid_scale, Global.SNAP_INCREMENT)
			if Global.snapping:
				get_parent().scale = Vector3(
				snapped_scale, snapped_scale, snapped_scale)
			else:
				get_parent().scale = Vector3(
					fluid_scale, fluid_scale, fluid_scale)
		)
	)
