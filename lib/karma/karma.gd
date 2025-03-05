extends Node3D

var picked_up = false

func _on_pick_up_area_body_entered(body: Node3D) -> void:
	if picked_up: return
	if body is CharacterBody3D:
		picked_up = true
		Save.add_karma(1)
		
		$DespawnTimer.start()
		$Orb/Stars.emitting = true
		$Collect.play()
		var scale_tween = create_tween()
		scale_tween.tween_property($Orb, "scale", Vector3(0.01, 0.01, 0.01), 0.07)
		
		var ray_tween = create_tween()
		ray_tween.set_parallel()
		ray_tween.tween_property($Orb/Ray, "scale:y", 6.0, 0.07)
		
		scale_tween.tween_callback(func():
			$Orb/Stars.emitting = false)

func _ready() -> void:
	$Orb/Stars.set_disable_scale(true)
	$Orb.scale = Vector3(0.01, 0.01, 0.01)
	$Orb/Ray.scale.y = 3.0
	
	var scale_tween = create_tween()
	scale_tween.tween_property($Orb, "scale", Vector3(1, 1, 1), 0.05)
	
	var ray_tween = create_tween()
	ray_tween.set_parallel()
	ray_tween.tween_property($Orb/Ray, "scale:y", 1.0, 0.25)

var _c = 0

func _process(delta: float) -> void:
	_c += delta
	if picked_up:
		global_position = lerp(
			global_position, Global.player_position,
			Utilities.critical_lerp(delta, 10.0))
	else:
		global_position = lerp(
			global_position, Global.player_position,
			Utilities.critical_lerp(delta, clamp(_c, 0.0, 2.0) * 0.5))
	$Orb.global_position.y = $YCast.get_collision_point().y + 0.24

func _on_despawn_timer_timeout() -> void:
	queue_free()
