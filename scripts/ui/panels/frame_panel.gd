@tool
class_name FramePanel
extends PanelContainer
## Prefab du cadre bleu à liseré clair (carte de question du quiz). Le contenu va dans `content`.

const SCENE := "res://scenes/ui/panels/frame_panel.tscn"

var content: VBoxContainer:
	get:
		return $Content


static func create() -> FramePanel:
	return load(SCENE).instantiate()
