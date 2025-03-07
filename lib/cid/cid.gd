@tool
extends Node3D

func play_animation() -> void:
	$Otter/AnimationPlayer.play("spin")

@export_tool_button("Play Animation") var anim_action = play_animation

func _ready() -> void:
	$Otter/OtterArmature/Skeleton3D/ParticleAttachment/Bubbles.emitting = false
