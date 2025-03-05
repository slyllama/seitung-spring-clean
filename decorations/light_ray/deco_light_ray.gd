@tool
extends Decoration

const _mat_exp_ray = preload("res://decorations/light_ray/materials/mat_exp_ray.tres")

func _ready():
	super()
	# TODO: proper screen rays aren't working well at all
	#for _n in Utilities.get_all_children($LightRay):
		#if _n is MeshInstance3D:
			#_n.set_surface_override_material(0, _mat_exp_ray)
