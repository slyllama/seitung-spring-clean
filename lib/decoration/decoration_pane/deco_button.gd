extends HBoxContainer

const ICONS = {
	"foliage": preload("res://lib/hud/fx_list/textures/fx_weed.png"),
	"utility": preload("res://lib/hud/fx_list/textures/fx_utility.png"),
	"furniture": preload("res://lib/hud/fx_list/textures/fx_furniture.png")
}
signal clicked

func set_icon(icon: String) -> void:
	$Icon.texture = ICONS[icon]

func set_text(text: String) -> void:
	$Button.text = text

func set_cost(cost: int) -> void:
	$Cost.text = str(cost)
	$Cost.visible = true
	$Karma.visible = true

func _on_button_button_down() -> void:
	$Click.play()
	clicked.emit()

func _on_button_mouse_entered() -> void:
	$Hover.play()
	$Anim.play("pop_in")

func _on_button_mouse_exited() -> void:
	$Anim.play("pop_out")
