@icon("res://lib/gizmo/icon_gizmo.svg")
class_name Gizmo extends Node3D

const GizmoArrow = preload("res://lib/gizmo/gizmo_arrow.gd")

@export var active = false
var offset = Vector3.ZERO
var arrows: Array[GizmoArrow] = []

func activate() -> void:
	if active: return
	global_position = get_parent().global_position + offset
	active = true
	for _a in arrows: _a.enable()
	visible = true

func deactivate() -> void:
	if !active: return
	active = false
	for _a in arrows: _a.disable()
	await get_tree().create_timer(0.3).timeout
	if !active: visible = false

func _ready() -> void:
	top_level = true
	offset = global_position - get_parent().global_position
	
	var arrow = GizmoArrow.new()
	add_child(arrow)
	arrow.set_axis(Vector3(0, 0, 1))
	arrow.set_color(Color.BLUE)
	
	var arrow2 = GizmoArrow.new()
	arrow2.rotation_degrees.x = 90
	add_child(arrow2)
	arrow2.set_axis(Vector3(0, 1, 0))
	arrow2.set_color(Color.GREEN)
	
	var arrow3 = GizmoArrow.new()
	arrow3.rotation_degrees.y = 90
	add_child(arrow3)
	arrow3.set_axis(Vector3(1, 0, 0))
	arrow3.set_color(Color.RED)
	
	arrows.append(arrow)
	arrows.append(arrow2)
	arrows.append(arrow3)
	visible = false

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		activate()

func _process(_delta: float) -> void:
	if active:
		get_parent().position = position - offset
