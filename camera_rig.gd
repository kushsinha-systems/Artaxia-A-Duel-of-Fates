extends Node2D

@onready var cam := $Camera2D
@export var p1: Node2D
@export var p2: Node2D

@export var min_zoom := 0.5
@export var max_zoom := 1.5
@export var zoom_smooth := 0.05

@export var background: Sprite2D

@export var arena_padding := 300.0

func _ready():

	if not background or not background.texture:
		return

	var tex_size = background.texture.get_size()
	var bg_scale = background.scale

	var width = tex_size.x * bg_scale.x
	var height = tex_size.y * bg_scale.y

	cam.limit_left = background.global_position.x - width / 2
	cam.limit_right = background.global_position.x + width / 2
	cam.limit_top = background.global_position.y - height / 2
	cam.limit_bottom = background.global_position.y + height / 2

func _physics_process(_delta: float) -> void:
	if not p1 or not p2:
		return

	# 1️⃣ Position: midpoint
	var mid = (p1.global_position + p2.global_position) * 0.5
	cam.global_position = mid

	# 2️⃣ Distance-based zoom
	var dist = abs(p1.global_position.x - p2.global_position.x) - arena_padding
	dist = max(dist, 0)
	var target_zoom = clamp(1.0 - dist / 2500.0, min_zoom, max_zoom)

	cam.zoom = cam.zoom.lerp(Vector2(target_zoom, target_zoom), zoom_smooth)
	cam.offset = cam.offset.lerp(Vector2(0, -200), 0.05)
