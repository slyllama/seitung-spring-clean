@tool
extends Node3D

@onready var bubbles = $OtterArmature/Skeleton3D/ParticleAttachment/Bubbles

func play_animation() -> void:
	bubbles.emitting = true
	$AnimationPlayer.play("spin")
	await $AnimationPlayer.animation_finished
	bubbles.emitting = false
	await get_tree().process_frame
	play_animation()

@export_tool_button("Play Animation") var anim_action = play_animation

func _ready() -> void:
	$OtterArmature/Skeleton3D/ParticleAttachment/Bubbles.set_disable_scale(true)
	bubbles.emitting = false
	
	play_animation()
