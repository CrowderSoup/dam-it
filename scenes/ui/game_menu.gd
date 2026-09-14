extends CanvasLayer
## In-game pause menu: resume, manually save, or start a fresh game. Toggled
## by the "menu" action (Escape / controller Back). Pauses the SceneTree
## while open so nothing keeps happening behind it - storms, the raccoon,
## energy drain - but this node and its popups stay PROCESS_MODE_ALWAYS so
## the menu itself still responds while paused.
##
## New-game handling lives here rather than in Main so pressing "restart"
## and using this menu's "New Game" button share one path - see
## new_game_requested, which Main connects to.

signal new_game_requested

@onready var save_button: Button = $Panel/VBoxContainer/SaveButton
@onready var save_feedback: Label = $Panel/VBoxContainer/SaveFeedback
@onready var confirm_new_game: ConfirmationDialog = $ConfirmNewGame

func _ready() -> void:
	hide()
	save_feedback.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()

func open() -> void:
	show()
	save_feedback.hide()
	get_tree().paused = true
	save_button.grab_focus()

func close() -> void:
	hide()
	get_tree().paused = false

func _on_resume_pressed() -> void:
	close()

func _on_save_pressed() -> void:
	SaveManager.save_game()
	save_feedback.text = "Game saved!"
	save_feedback.show()

func _on_new_game_pressed() -> void:
	confirm_new_game.popup_centered()

func _on_confirm_new_game() -> void:
	close()
	new_game_requested.emit()
