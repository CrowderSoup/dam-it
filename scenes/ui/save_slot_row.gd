extends Panel
## One row in the title screen's save-slot picker: shows what (if
## anything) is saved in this slot, and lets the player continue it or
## start fresh.
##
## Emits slot_chosen once the underlying save file is in whatever state
## play should begin from - untouched for Continue, freshly deleted for a
## confirmed New Game - so the title screen just switches scenes when it
## hears that; it doesn't need to know which button was pressed.

signal slot_chosen(slot_index: int)

@export var slot_index: int = 1

@onready var name_label: Label = $Margin/HBox/Info/NameLabel
@onready var info_label: Label = $Margin/HBox/Info/InfoLabel
@onready var continue_button: Button = $Margin/HBox/Buttons/ContinueButton
@onready var new_game_button: Button = $Margin/HBox/Buttons/NewGameButton
@onready var confirm_overwrite: ConfirmationDialog = $ConfirmOverwrite

func _ready() -> void:
	name_label.text = "Slot %d" % slot_index
	refresh()

## Re-reads this slot's save file. Called on _ready(), and again after a
## confirmed New Game deletes it, so the row reflects "Empty" immediately.
func refresh() -> void:
	var data := SaveManager.peek_slot(slot_index)
	if data.is_empty():
		info_label.text = "Empty"
		continue_button.hide()
	else:
		info_label.text = _summarize(data)
		continue_button.show()

func _summarize(data: Dictionary) -> String:
	var dam_built := 0
	var dam_built_data: Dictionary = data.get("dam_slots_built", {})
	for built in dam_built_data.values():
		if built:
			dam_built += 1
	var lodge_stage: int = data.get("lodge_stage", 0)
	return "Dam %d/%d | Lodge %d/%d" % [dam_built, dam_built_data.size(), lodge_stage, GameState.LODGE_MAX_STAGE]

func _on_continue_pressed() -> void:
	slot_chosen.emit(slot_index)

func _on_new_game_pressed() -> void:
	if SaveManager.has_save(slot_index):
		confirm_overwrite.popup_centered()
	else:
		slot_chosen.emit(slot_index)

func _on_confirm_overwrite() -> void:
	SaveManager.delete_save(slot_index)
	refresh()
	slot_chosen.emit(slot_index)
