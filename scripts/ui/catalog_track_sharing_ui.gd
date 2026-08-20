extends TrackSharingUI
class_name CatalogTrackSharingUI

func open_panel() -> void:
	_open()

func close_panel() -> void:
	_close()

func is_panel_open() -> bool:
	return panel != null and panel.visible
