extends Node2D
## Keeps the title screen up until the player picks a save slot - nothing
## auto-loads before then, see SaveManager.begin_session().

@onready var slots: Array[Panel] = [$Slots/Slot1, $Slots/Slot2, $Slots/Slot3]

func _ready() -> void:
	for slot in slots:
		slot.slot_chosen.connect(_on_slot_chosen)
	_focus_first_available()

## Gives keyboard/controller players a focused button to start from,
## preferring "Continue" on the first occupied slot over "New Game".
func _focus_first_available() -> void:
	for slot in slots:
		if slot.continue_button.visible:
			slot.continue_button.grab_focus()
			return
	slots[0].new_game_button.grab_focus()

func _on_slot_chosen(slot_index: int) -> void:
	SaveManager.begin_session(slot_index)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
