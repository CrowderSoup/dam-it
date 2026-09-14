extends CanvasLayer
## In-game pause menu: resume, manually save, review controls, or start a
## fresh game. Toggled by the "menu" action (Escape / controller Start or
## Back). Pauses the SceneTree while open so nothing keeps happening behind
## it - storms, the raccoon, energy drain - but this node and its popups
## stay PROCESS_MODE_ALWAYS so the menu itself still responds while paused.
##
## New-game handling lives here rather than in Main so pressing "restart"
## and using this menu's "New Game" button share one path - see
## new_game_requested, which Main connects to. request_new_game() is that
## shared entry point: it never destroys a save on its own, it only ever
## opens (or reuses) this menu's existing confirmation dialog.

signal new_game_requested

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_feedback: Label = $Panel/VBoxContainer/SaveFeedback
@onready var confirm_new_game: ConfirmationDialog = $ConfirmNewGame
@onready var controls_dialog: AcceptDialog = $ControlsDialog

## Set by Main so this menu and the journal (scenes/ui/journal.gd) never
## stack open on top of each other - see _unhandled_input() below.
var _journal: CanvasLayer = null

func _ready() -> void:
	hide()
	save_feedback.hide()
	# AcceptDialog sizes itself from its label's minimum width. Without wrap,
	# the long controls copy forced an embedded Web window wider than the
	# entire 640px viewport despite the size set in the scene.
	controls_dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func set_journal(journal: CanvasLayer) -> void:
	_journal = journal

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if visible:
			close()
			get_viewport().set_input_as_handled()
		elif _journal == null or not _journal.visible:
			open()
			get_viewport().set_input_as_handled()

func open() -> void:
	show()
	save_feedback.hide()
	get_tree().paused = true
	resume_button.grab_focus()

func close() -> void:
	hide()
	get_tree().paused = false

## Shared by the keyboard/gamepad "restart" shortcut and this menu's "New
## Game" button, so neither can ever skip the confirmation dialog below.
func request_new_game() -> void:
	if not visible:
		open()
	confirm_new_game.popup_centered()

func _on_resume_pressed() -> void:
	close()

func _on_save_pressed() -> void:
	var saved := SaveManager.save_game()
	save_feedback.text = "Game saved!" if saved else "Could not save game."
	save_feedback.show()

func _on_controls_pressed() -> void:
	controls_dialog.popup_centered(Vector2i(420, 300))

func _on_new_game_pressed() -> void:
	request_new_game()

func _on_confirm_new_game() -> void:
	close()
	new_game_requested.emit()
