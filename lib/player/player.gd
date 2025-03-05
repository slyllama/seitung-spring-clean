extends CharacterBody3D

const JADE_SOUNDS = [
	preload("res://lib/player/sounds/jade_sound_1.ogg"),
	preload("res://lib/player/sounds/jade_sound_2.ogg"),
	preload("res://lib/player/sounds/jade_sound_3.ogg"),
	preload("res://lib/player/sounds/jade_sound_4.ogg"),
	preload("res://lib/player/sounds/jade_sound_8.ogg"),
	preload("res://lib/player/sounds/jade_sound_5.ogg"),
	preload("res://lib/player/sounds/jade_sound_7.ogg"),
	preload("res://lib/player/sounds/jade_sound_6.ogg")
]

const SPRINT_SOUNDS = [
	preload("res://lib/player/sounds/jade_sprint_1.ogg"),
	preload("res://lib/player/sounds/jade_sprint_2.ogg"),
	preload("res://lib/player/sounds/jade_sprint_4.ogg"),
	preload("res://lib/player/sounds/jade_sprint_5.ogg")
]

const DgFX = preload("res://lib/dispersion_golem/dg_fx.tscn")
var can_play_sprint_sound = true

@export var base_speed: float = 3.0
@export var smoothing: float = 7.0
var smooth_mod = 1.0 # acceleration smoothing - to be modified by command

@onready var anim: AnimationPlayer = get_node("PlayerMesh/AnimationPlayer")
@onready var engine_bone: BoneAttachment3D = get_node("PlayerMesh/JadeArmature/Skeleton3D/EngineRing1")
@onready var _initial_y_rotation = global_rotation.y
var _direction := Vector3.ZERO
var _calculated_speed := base_speed
var _speed := _calculated_speed
var _sprint_multiplier := 1.0
var _target_velocity := Vector3.ZERO

func play_jade_sound() -> void:
	var rng = RandomNumberGenerator.new()
	var _ind = rng.randi_range(0, JADE_SOUNDS.size() - 1)
	
	var sound = AudioStreamPlayer.new()
	sound.stream = JADE_SOUNDS[_ind]
	sound.volume_db = linear_to_db(0.4)
	sound.pitch_scale = 0.8 + 0.4 * rng.randf()
	add_child(sound)
	
	sound.finished.connect(sound.queue_free)
	sound.play()

func spawn_dgolems() -> void:
	clear_dgolems()
	var _d = DgFX.instantiate()
	_d.amount = 3
	add_child(_d)

func clear_dgolems() -> void:
	for _n in get_children():
		if "amount" in _n:
			_n.queue_free()

var hearts_playing = false

func play_hearts() -> void:
	if !$PlayerMesh/HeartParticles.visible:
		$PlayerMesh/HeartParticles.visible = true
	
	hearts_playing = true
	$PlayerMesh/HeartParticles.emitting = true
	$HeartTimer.start()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_action"):
		$PlayerMesh.visible = !$PlayerMesh.visible
	
	if Input.is_action_just_pressed("sprint"):
		if can_play_sprint_sound and velocity.length() > 0.0:
			can_play_sprint_sound = false
			$SprintSoundCD.start()
			$SprintSoundPlayer.stream = SPRINT_SOUNDS.pick_random()
			$SprintSoundPlayer.play()

func _ready() -> void:
	# Spawn/clear golems in different circumstances
	Global.debug_skill_used.connect(spawn_dgolems)
	Global.add_effect.connect(func(id):
		if (id == "discombobulator" or id == "dv_charge"):
			spawn_dgolems())
	Global.remove_effect.connect(func(id):
		await get_tree().process_frame
		if (id == "discombobulator"
			or id == "dv_charge"
			or id == "d_jormag"
			or id == "d_kralkatorrik"
			or id == "d_mordremoth"
			or id == "d_primordus"
			or id == "d_soo_won"
			or id == "d_zhaitan"):
			if !Utilities.is_holding_dv_charge():
				clear_dgolems())
	
	Global.hearts_emit.connect(play_hearts)
	Global.camera = $Camera.camera # reference
	Global.player = self
	
	$Camera.top_level = true
	$Camera.set_cam_rotation(Vector3(-20, 0, 0))
	Global.jade_bot_sound.connect(play_jade_sound)
	
	get_window().focus_exited.connect(func():
		_sprint_multiplier = 1.0
		$Camera.added_fov = 0.0)
	
	# Move the player to a new location using global signals
	Global.move_player.connect(func(_pos: Vector3):
		global_position = _pos)
	
	Global.command_sent.connect(func(_cmd):
		if _cmd == "/hideplayer":
			$PlayerMesh.visible = false
		elif _cmd == "/showplayer":
			$PlayerMesh.visible = true
		elif "/speedratio=" in _cmd:
			var _speed_ratio = float(_cmd.replace("/speedratio=", ""))
			_calculated_speed = base_speed * clamp(_speed_ratio, 0.0, 2.0)
		elif "/playersmooth=" in _cmd:
			var _s = float(_cmd.replace("/playersmooth=", ""))
			smooth_mod = clamp(_s, 0.01, 1.0)
		elif _cmd == "/collision=off":
			$Collision.disabled = true
			Global.announcement_sent.emit("((Collision disabled))")
		elif _cmd == "/collision=on":
			$Collision.disabled = false
			Global.announcement_sent.emit("((Collision re-enabled))")
	)
	
	$PlayerMesh/HeartParticles.emitting = true
	await get_tree().process_frame
	$PlayerMesh/HeartParticles.emitting = false
	$PlayerMesh/HeartParticles.visible = false

var _fs = 0 # forward state (if > 0, a 'forward' key (including strafe) is down)
var _ss = 0 # strafe state
var _blend_target = 1.0
var _strafe_target = 0.0
var _elongate_target = 0.0
var _blend_state = _blend_target

func _physics_process(delta: float) -> void:
	# Handle animations
	var _query_fs = _fs
	var _query_ss = _ss # query strafe state
	if Input.is_action_just_pressed("move_forward"): _query_fs += 1
	#if Input.is_action_just_pressed("move_up"): _query_fs += 1
	#if Input.is_action_just_pressed("move_left"): _query_fs += 1
	#if Input.is_action_just_pressed("move_right"): _query_fs += 1
	
	if Input.is_action_just_released("move_forward"): _query_fs -= 1
	#if Input.is_action_just_released("move_up"): _query_fs -= 1
	#if Input.is_action_just_released("move_left"): _query_fs -= 1
	#if Input.is_action_just_released("move_right"): _query_fs -= 1
	
	if _query_fs > 0 and _fs == 0:
		_blend_target = -1.0
	elif _query_fs == 0 and _fs > 0:
		_blend_target = 1.0
	
	if _fs != 0:
		if velocity.length() < 0.1:
			_fs = 0 # reset forward state (for animations) if it gets stuck
	
	# Process inputs
	if Input.is_action_pressed("move_forward"): _direction.x = 1
	elif Input.is_action_pressed("move_back"): _direction.x = -1
	else: _direction.x = 0
	
	if Input.is_action_pressed("move_right"): _direction.z = 1
	elif Input.is_action_pressed("move_left"): _direction.z = -1
	else: _direction.z = 0
	
	if Input.is_action_pressed("move_up"): _direction.y = 1
	elif Input.is_action_pressed("move_down"): _direction.y = -1
	else: _direction.y = 0
	
	var _camera_direction = $Camera.rotation_degrees.y
	var _camera_basis = $Camera.global_transform.basis
	Global.camera_basis = _camera_basis
	Global.camera_pivot_rotation_degrees = $Camera.rotation_degrees
	
	# Get player sprint multiplier
	if Input.is_action_pressed("sprint"):
		_sprint_multiplier = 1.95
	else:
		_sprint_multiplier = 1.0
		$Camera.added_fov = 0.0
	_speed = _calculated_speed
	_speed *= _sprint_multiplier
	
	# Multiply inputs by the movement vector and orbit rotation
	# This could be improved, but it works
	if Global.can_move:
		_target_velocity = (Vector3.FORWARD * _camera_basis * Vector3(-1, 0, 1) * _direction.x)
		_target_velocity += (Vector3.RIGHT * _camera_basis * Vector3(1, 0, -1) * _direction.z)
		_target_velocity += (Vector3.UP * _camera_basis * Vector3(0, 1, 0) * _direction.y)
		_target_velocity = _target_velocity.normalized() * Vector3(_speed, _speed * 1.12, _speed)
	else: _target_velocity = Vector3.ZERO
	
	velocity.x = lerp(velocity.x, _target_velocity.x, smoothing * 0.6 * delta * smooth_mod)
	velocity.y = lerp(velocity.y, _target_velocity.y, smoothing * 0.5 * delta * smooth_mod)
	velocity.z = lerp(velocity.z, _target_velocity.z, smoothing * delta * smooth_mod)
	
	if !Global.in_walk_mode:
		move_and_slide()
	else:
		if Global.walk_mode_target != null:
			global_position = Global.walk_mode_target.global_position + Vector3(0, 1, 0)
	Global.player_position = global_position
	Global.player_y_rotation = global_rotation.y
	_fs = _query_fs
	
	$Camera.rotation_degrees.y = fmod($Camera.rotation_degrees.y, 360.0);
	if velocity.length() > 1.0:
		# "Naturalise" rotations of both camera and mesh by subtracting
		# 360deg until they are each less than 360deg
		if $Camera.rotation_degrees.y < 0:
			$Camera.rotation_degrees.y += 360.0;
		#$Camera.rotation_degrees.y -= 180.0
		
		$PlayerMesh.rotation.y = lerp_angle(
			$PlayerMesh.rotation.y,
			$Camera.rotation.y - _initial_y_rotation + PI,
			smoothing * 0.6 * delta)
	
	if Global.can_move:
		if _direction.x > 0 or _direction.z != 0 or Global.in_walk_mode:
			if _sprint_multiplier > 1.0:
				$Camera.added_fov = 14.0
		
		$PlayerMesh.rotation.z = lerp(
			$PlayerMesh.rotation.z,
			_direction.z * 0.4,
			smoothing * 0.2 * delta)
	
	# Interpolating camera movements on physics tick seems to be smoother when
	# playing with unlimited frames
	$Camera.global_position.y = lerp(
		$Camera.global_position.y, global_position.y, smoothing * delta)
	$Camera.global_position.x = global_position.x
	$Camera.global_position.z = global_position.z

func _process(delta: float) -> void:
	$PlayerMesh/Stars.global_position = engine_bone.global_position
	$Camera.popup_open = Global.popup_open
	$Camera.mouse_in_ui = Global.mouse_in_ui
	
	if Global.can_move:
		_blend_state = lerp(_blend_state, _blend_target, 3.7 * delta)
		_strafe_target = lerp(_strafe_target, -_direction.z, 5.2 * delta)
		_elongate_target = lerp(_elongate_target, _direction.y * 1.2, 3.7 * delta)
	else: # gently reset when locking position
		_blend_state = lerp(_blend_state, 0.0, 2.0 * delta)
		_strafe_target = lerp(_strafe_target, 0.0, 2.0 * delta)
		_elongate_target = lerp(_elongate_target, 0.0, 2.0 * delta)
	$PlayerMesh/Tree.set("parameters/test_blend/blend_position", _blend_state)
	$PlayerMesh/Tree.set("parameters/strafe/add_amount", _strafe_target)
	$PlayerMesh/Tree.set("parameters/set_elongate/add_amount", _elongate_target)
	
	var _target_pitch_scale: float = (1.0
		+ Vector3(velocity * Vector3(1, 0, 1)).length() / base_speed * 0.5)
	$EngineSound.pitch_scale = lerp($EngineSound.pitch_scale, _target_pitch_scale, 0.07)

func _on_sprint_sound_cd_timeout() -> void:
	can_play_sprint_sound = true

func _on_heart_timer_timeout() -> void:
	if hearts_playing:
		hearts_playing = false
		$PlayerMesh/HeartParticles.emitting = false
